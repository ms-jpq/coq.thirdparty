# coq.nvim Thirdparty Sources

**PR welcome**

---

First party lua sources & third party integration for [`coq.nvim`](https://github.com/ms-jpq/coq_nvim)

See [`:COQhelp custom_sources`](https://github.com/ms-jpq/coq_nvim/tree/coq/docs/CUSTOM_SOURCES.md)

## How to use

Install the repo the normal way, and then:

```lua
require("coq_3p") {
  { src = "demo" },
  { src = "vimtex", short_name = "vTEX" },
  ...
}
```

`require("coq_3p")` takes a list of `{ src = ..., short_name = ..., ... }` objects.

`src` is required

If `short_name` is not specified, it is uppercase `src`.

The rest of object are specific to each individual source.

## Lua Sources

### [Demo](https://github.com/ms-jpq/coq.thirdparty/blob/main/lua/coq_3p/demo/init.lua)

`{ src = "demo" }`

This is a reference implementation, do not enable it unless you want to write your own plugin, and want to see how it works.

### Nvim Lua

` { src = "nvimlua", short_name = "nLUA" }`

Live nvim Lua env.

## Third Parties

### [VimTex](https://github.com/lervag/vimtex)

`{ src = "vimtex", short_name = "vTEX" }`

- Cache enabled

### [Orgmode.nvim](https://github.com/kristijanhusak/orgmode.nvim)

`{ src = "orgmode", short_name = "ORG" }`

- Cache enabled
