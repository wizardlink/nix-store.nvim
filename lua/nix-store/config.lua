---@class nix-store.Config.Module: nix-store.Config
local M = {}

local commands = require "nix-store.commands"
local store = require "nix-store.store"

---@class nix-store.Config
local defaults = {
  --- Whether to pass `NIXPKGS_ALLOW_UNFREE` or not.
  allow_unfree = false,
  --- Table that contains all the packages currently loaded and their configuration.
  ---
  --- You can use this configuration to replace the expression of a particular
  --- package to be evaluated.
  ---
  --- Example:
  --- require("nix-store").setup({
  ---   packages = {
  ---     ["vscode-extensions.ms-vscode.cpptools"] = {
  ---       output = 0, -- = out = outPath
  ---       expression = "callPackage ~/some/derivation/path { }"
  ---     }
  ---   }
  --- })
  packages = {}, ---@type nix-store.Store.Packages
}

---@type nix-store.Config
local merged_options

---@param opts? nix-store.Config
---@return nix-store.Config
function M.setup(opts)
  merged_options = vim.tbl_deep_extend("force", {}, merged_options or defaults, opts or {}) --[[@as nix-store.Config]]

  merged_options.packages = vim.tbl_deep_extend("keep", merged_options.packages, store.read_lockfile())

  commands.register_commands()

  return merged_options
end

return setmetatable(M, {
  __index = function(_, key)
    merged_options = merged_options or M.setup()
    return merged_options[key]
  end,
})
