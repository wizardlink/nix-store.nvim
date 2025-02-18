local M = {}

local util = require "nix-store.util"

local lockfile_path = vim.fn.stdpath "cache" .. "/nix-store-lock.json"

---@enum (key) nix-store.Store.Package.Output
M.PACKAGEOUTPUT = {
  out = 0,
  lib = 1,
}

---@class nix-store.Store.Package
---@field output nix-store.Store.Package.Output The type of derivation output for the package
--- An expression that evaluates to an installable.
---
--- In the context of the expression, all packages from `nixpkgs` are available.
--- i.e. `expression = "callPackage ~/some/derivation/path {}"`
---@field expression? string
---@field store? string

---@alias nix-store.Store.Packages table<string, nix-store.Store.Package>

--- Reads the store lock file and returns it's contents
---@return nix-store.Store.Packages
function M.read_lockfile()
  local fd = io.open(lockfile_path, "r")

  local contents = "{}"

  if fd ~= nil then
    contents = fd:read "*a"
    fd:close()
  else
    fd = io.open(lockfile_path, "w") --[[@as file*]]
    fd:write(contents)
    fd:close()
  end

  return vim.json.decode(contents)
end

--- Writes packages to lockfile.
---@param pkgs nix-store.Store.Packages
function M.write_lockfile(pkgs)
  local fd = io.open(lockfile_path, "w") --[[@as file*]]

  fd:write(vim.json.encode(pkgs))

  fd:close()
end

---@class nix-store.Store.SearchOptions
---@field force? boolean Defaults to false
---@field output? nix-store.Store.Package.Output Defaults to "out"

---@param package_name string
---@param search_options? nix-store.Store.SearchOptions
---@return string?
function M.get_store(package_name, search_options)
  search_options = search_options or {}

  local output = M.PACKAGEOUTPUT.out

  if search_options.output == nil then
    search_options.output = "out"
  else
    output = M.PACKAGEOUTPUT[search_options.output]
  end

  local config = require "nix-store.config"

  local local_package = config.packages[package_name]

  -- The expression that evaluates an installable.
  -- It is overridden with a custom expression if available.
  local package_expr = package_name

  if local_package ~= nil then
    if
        search_options.force ~= true
        and local_package.store ~= nil
        and M.PACKAGEOUTPUT[local_package.output] == output
    then
      return local_package.store
    end

    package_expr = local_package.expression or package_expr
  end

  -- The expression we will use to evaluate the package
  local nix_eval = ""

  if config.allow_unfree then
    nix_eval = nix_eval .. "NIXPKGS_ALLOW_UNFREE=1 "
  end

  nix_eval = nix_eval
      .. "nix eval --raw --expr '"
      .. "with import <nixpkgs> { }; "
      .. (output == M.PACKAGEOUTPUT.lib and "lib.getLib " or "")
      .. "("
      .. package_expr
      .. ")"
      .. (output == M.PACKAGEOUTPUT.out and ".outPath" or "")
      .. "' --impure"

  local command_output = util.shell_command(nix_eval)

  if string.sub(command_output[1], 1, 5) == "error" then
    vim.notify("Failed evaluating Nix package `" .. package_expr .. "`\n\n" .. table.concat(command_output, "\n"))
  else
    config.packages[package_name] = {
      output = search_options.output,
      store = command_output[1],
      expression = local_package and local_package.expression,
    }

    M.write_lockfile(config.packages)

    return command_output[1]
  end
end

return M
