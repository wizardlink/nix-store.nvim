local M = {}

--- Executes a command and returns the output broken per line.
--- It makes use of `nvim_parse_cmd` so it cannot contain newlines.
---@param command string
---@return string[]
function M.command(command)
  local parsed_command = vim.api.nvim_parse_cmd(command, {})

  local command_output = vim.api.nvim_cmd(parsed_command --[[@as vim.api.keyset.cmd]], { output = true })

  -- Breaks at newline and remove empty lines from array.
  local filtered_output = vim.tbl_filter(function(value)
    if value == "" then
      return false
    else
      return true
    end
  end, vim.split(command_output, "\n"))

  -- Removes the command echo line.
  table.remove(filtered_output, 1)

  return filtered_output
end

--- Executes a shell command and returns the output broken per line.
--- It makes use of `nvim_parse_cmd` so it cannot contain newlines.
---@param command string
---@return string[]
function M.shell_command(command)
  return M.command("silent !" .. command)
end

return M
