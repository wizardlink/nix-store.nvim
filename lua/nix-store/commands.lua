local M = {}

local store = require "nix-store.store"

---@param line string
---@return string[]
function M.completion_callback(_, line)
  local arguments = vim.iter(vim.split(line, "%s+"))
      :skip(1)
      :filter(function(value)
        if value == "" then
          return false
        else
          return true
        end
      end)
      :totable()

  local config = require "nix-store.config"

  local package_names = vim.iter(config.packages):map(function(key)
    return key
  end)

  if #arguments == 0 then
    return package_names:totable()
  end

  return package_names
      :filter(function(value)
        return vim.startswith(value, arguments[1])
      end)
      :totable()
end

--- Registers all the user commands
function M.register_commands()
  -- "NixStore" command
  -- Echoes the store path of the package passed via arguments
  vim.api.nvim_create_user_command("NixStore", function(opts)
    local store_path = store.get_store(opts.args, {}) or "Error"

    vim.api.nvim_echo({ { store_path } }, true, {})
  end, { nargs = 1, complete = M.completion_callback })

  -- "NixStoreRefresh" command
  -- Similar to "NixStore", but forces the re-evaluation of the path and
  -- if no arguments are passed, all stores are re-evaluated.
  vim.api.nvim_create_user_command("NixStoreRefresh", function(opts)
    local message

    if #opts.fargs > 0 then
      message = store.get_store(opts.args, { force = true }) or "Error"
    else
      local config = require "nix-store.config"
      local errors = 0

      vim.iter(config.packages)
          :map(function(key)
            return key
          end)
          :each(function(name)
            if not store.get_store(name, { force = true }) then
              errors = errors + 1
            end
          end)

      if errors > 0 then
        message = "Failure: " .. errors .. " errors"
      else
        message = "Success"
      end
    end

    vim.api.nvim_echo({ { message } }, true, {})
  end, { nargs = "?", complete = M.completion_callback })

  -- Create an alias for ease of use
  vim.fn.get_nix_store = store.get_store
end

return M
