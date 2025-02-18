local M = {}

--- Whether the plugin has been setup or not.
M.is_setup = false

---@param opts? nix-store.Config
function M.setup(opts)
  if M.is_setup == true then
    return
  end

  require("nix-store.config").setup(opts)

  M.is_setup = true
end

return M
