# nix-store.nvim

This is a [neovim] plugin that gives interfaces to fetch store paths in [nix] powered systems and cache their paths.

## Installation

Using [lazy.nvim]:
```lua
{
  "wizardlink/nix-store.nvim",
  -- The following are needed if you wish to get store paths
  -- in other plugin initializations.
  priority = 999999, -- This number can be lower depending on your distro/config
  lazy = false,
}
```

### Configuration

Here are the defaults of the plugin:

```lua
require("nix-store").setup({
  allow_unfree = false,
  packages = {},
})
```

Below you can find more detailed information on each option.

#### allow_unfree

_Expects a `boolean`, by default it is `false`._

When set `true` store evaluations will be preceded by `NIXPKGS_ALLOW_UNFREE=1`, so that unfree packages may be
evaluated.

#### packages

_Expects a `table`, by default it is empty `{}`._

The `packages` field expects a key-value pair table, the key being a [package name](#package-name) and the value a
key-pair table with the following keys/fields:

- [`output`](#output)
  - This field is obligatory.
- [`expression`](#expression)
- `store`
  - This should be set by the plugin, but can be optionally used to ignore cache.

Example:
```lua
require("nix-store").setup({
  packages = {
    hello = {
      output = "out",
      expression = "callPackage ~/path/to/derivation.nix { }",
    },
  },
})
```

## Usage

Once the plugin is installed, `nix-store.nvim` provides the following ways to fetch store paths:
- [`vim.fn.get_nix_store`](#vimfnget_nix_store)
- [NixStore](#nixstore)
- [NixStoreRefresh](#nixstorerefresh)

### vim.fn.get_nix_store

This is a lua function that expects a [package name](#package-name) as an argument and optionally an [output](#output) field may be passed
in a table alongside a an optional `force` boolean field so the store path is re-evaluated.

You can also reach this function through `require("nix-store.store").get_store`, however, if this is invoked in a
context before the set-up of the plugin it will force the plugin to set-up with the default settings. It is prefferred
to use `vim.fn.get_nix_store` to make sure the plugin is set-up in the context it's invoked.

Example usage:
```lua
-- Returns the store path of `vscode-extensions.ms-vscode.cpptools`
vim.fn.get_nix_store("vscode-extensions.ms-vscode.cpptools")

-- The same, but ignores the cache
vim.fn.get_nix_store("vscode-extensions.ms-vscode.cpptools", { force = true })
```

### NixStore

`NixStore` is a user command that echoes the store path of a given package, it has completion based on the cached
package names.

Example usage:
```
:NixStore vscode-extensions.ms-vscode.cpptools
```

### NixStoreRefresh

Like `NixStore`, `NixStoreRefresh` also echoes the store path of a given package, however, it forces re-evaluation of
the package and if no arguments are supplied, it re-evaluates all cached packages.

Example usage:
```
:NixStoreRefresh vscode-extensions.ms-vscode.cpptools
:NixStoreRefresh
```

## The store lockfile

`nix-store.nvim` keeps a JSON file in `$XDG_CACHE_HOME/nvim/nix-store-lock.json` as cache for the packages previously
evaluated, this is to reduce the startup time of the plugin which would otherwise get exponentially slower with more
packages.

Inside the JSON you will find an object containing key-value pair definitions for each package, a package will have the
following properties:

- `store`
  - The store path to the package
- `output`
  - The [output](#output) used to evaluate the store
- `expression`
  - An [expression](#expression) that evaluates to an installable

### Package name

You will see throughout `nix-store.nvim` the term "package name" being used, this term refers the expression that
evaluates a package in the context of `nixpkgs`.

For example, the package `hello`'s store path can be reached with the expression `(import <nixpkgs> {}).hello.outPath`,
then the "package name" in this context is `hello`; now for a package like `cpptools` you need the expression
`(import <nixpkgs> {}).vscode-extensions.ms-vscode.cpptools.outPath`, so it's "package name" is `vscode-extensions.ms-vscode.cpptools`.

### Output

The term "output" refers to the possible values for [outputs of a derivation], currently `nix-store.nvim` handles two:

1. `"out"`
2. `"lib"`

### Expression

An "expression" in the context of `nix-store.nvim` is a string that when evaluated in the context of `nixpkgs`, yields an
[installable].

"in the context of `nixpkgs`" means that this string will be evaluated proceeding a `with import <nixpkgs> {};`
statement, so all packages from `nixpkgs` will be available in the context.

Here are some examples:
```nix
callPackage ~/path/to/some/derivation.nix {}

some.package.in.nixpkgs
```

<!-- References -->

[lazy.nvim]: https://github.com/folke/lazy.nvim
[neovim]: https://neovim.io/
[nix]: https://nixos.org/
[outputs of a derivation]: https://nix.dev/manual/nix/2.25/language/derivations#attr-outputs
[installable]: https://nix.dev/manual/nix/2.25/command-ref/new-cli/nix.html?highlight=installable#installables
