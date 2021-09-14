# coq.nvim Thirdparty Sources

**PR welcome**

---

**First party lua sources** & _third party integration_ for [`coq.nvim`](https://github.com/ms-jpq/coq_nvim)

See [`:COQhelp custom_sources`](https://github.com/ms-jpq/coq_nvim/tree/coq/docs/CUSTOM_SOURCES.md)

## How to use

Install the repo the normal way, and then:

```lua
require("coq_3p") {
  { src = "demo" },
  { src = "nvimlua", short_name = "nLUA" },
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

`{ src = "nvimlua", short_name = "nLUA", conf_only = true }`

Live nvim Lua env.

![lua.img](https://raw.githubusercontent.com/ms-jpq/coq.artifacts/artifacts/preview/nvim_lua.gif)

- conf_only :: only return results if current document is relative to `$VIM_HOME`

### Math

`{ src = "bc", short_name = "MATH", precision = 6 }`

![bc.img](https://raw.githubusercontent.com/ms-jpq/coq.artifacts/artifacts/preview/bc.gif)

requires - [`bc`](https://linux.die.net/man/1/bc)

### Banner

`{ src = "figlet", short_name = "BIG" }`

![figlet.img](https://raw.githubusercontent.com/ms-jpq/coq.artifacts/artifacts/preview/figlet.gif)

requires - [`figlet`](https://linux.die.net/man/6/figlet)

### Moo

`{ src = "cow" }`

![cowsay.img](https://raw.githubusercontent.com/ms-jpq/coq.artifacts/artifacts/preview/cowsay.gif)

requires - [`cowsay`](https://linux.die.net/man/1/cowsay)

## Third Parties

### [VimTex](https://github.com/lervag/vimtex)

`{ src = "vimtex", short_name = "vTEX" }`

- Cache enabled

### [Orgmode.nvim](https://github.com/kristijanhusak/orgmode.nvim)

`{ src = "orgmode", short_name = "ORG" }`

- Cache enabled

---

## FYI

None of the code under `require('coq_3p')` is public API.

From the users' prespective, any change I make should be transparent, ie. I will try to not break their stuff.

For other plugin developers, if you want to re-use my code. Make a COPY, do not just `require "blah"` from this repo.

I want to reserve the ability to fearlessly re-factor.
