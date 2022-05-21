# coq.nvim (first & third) party sources

**PR welcome**

---

**First party lua sources** & _third party integration_ for [`coq.nvim`](https://github.com/ms-jpq/coq_nvim)

See [`:COQhelp custom_sources`](https://github.com/ms-jpq/coq_nvim/tree/coq/docs/CUSTOM_SOURCES.md)

## How to use

Install the repo the normal way, and then:

```lua
require("coq_3p") {
  { src = "nvimlua", short_name = "nLUA" },
  { src = "vimtex", short_name = "vTEX" },
  { src = "copilot", short_name = "COP", accept_key = "<c-f>" },
  ...
  { src = "demo" },
}
```

`require("coq_3p")` takes a list of `{ src = ..., short_name = ..., ... }` objects.

`src` is required

If `short_name` is not specified, it is uppercase `src`.

The rest of object are specific to each individual source.

## First party

### Shell REPL

```lua
{
  src = "repl",
  sh = "zsh",
  shell = { p = "perl", n = "node", ... },
  max_lines = 99,
  deadline = 500,
  unsafe = { "rm", "poweroff", "mv", ... }
}
```

Evaluates `...`:

```text
`<ctrl chars>!...`
```

Where `<ctrl chars>` can be a combination of zero or more of:

- `#` :: comment output

- `-` :: prevent indent

Note: `coq.nvim` has _very short_ deadlines by default for auto completions, manual `<c-space>` might be required if `$SHELL` is slow.

![repl.img](https://raw.githubusercontent.com/ms-jpq/coq.artifacts/artifacts/preview/repl.gif)

- sh :: Maybe str :: default repl shell, default to `$SHELL` fallback to `cmd.exe` under NT and `sh` under POSIX

- shell :: Maybe Map 'str, 'str :: For the first word `w` after "\`!", if `w ∈ key of shell`, set `sh = shell[w]`

- max_lines :: int :: max lines to return

- deadline :: int :: max ms to wait for execution

- unsafe :: Seq 'str :: do not start repl with these executables, ie. `rm`, `sudo`, `mv`, etc

### Nvim Lua API

`{ src = "nvimlua", short_name = "nLUA", conf_only = true }`

![lua.img](https://raw.githubusercontent.com/ms-jpq/coq.artifacts/artifacts/preview/nvim_lua.gif)

- conf_only :: Maybe bool :: only return results if current document is relative to `$NVIM_HOME`, default yes

### Scientific calculator

`{ src = "bc", short_name = "MATH", precision = 6 }`

![bc.img](https://raw.githubusercontent.com/ms-jpq/coq.artifacts/artifacts/preview/bc.gif)

- precision :: Maybe int

requires - [`bc`](https://linux.die.net/man/1/bc)

### Moo

`{ src = "cow", trigger = "!cow" }`

Use **`trigger = "!cow"`** to only show cowsay when you end a line with `!cow`

![cowsay.img](https://raw.githubusercontent.com/ms-jpq/coq.artifacts/artifacts/preview/cowsay.gif)

requires - [`cowsay`](https://linux.die.net/man/1/cowsay)

### Comment Banner

`{ src = "figlet", short_name = "BIG" }`

Use **`trigger = "!big"`** to only show figlet when you end a line with `!big`
Use **`fonts = {"/usr/share/figlet/fonts/standard.flf"}`** specify the list of fonts to choose from

![figlet.img](https://raw.githubusercontent.com/ms-jpq/coq.artifacts/artifacts/preview/figlet.gif)

requires - [`figlet`](https://linux.die.net/man/6/figlet)

## Third parties

### [Copilot](https://github.com/github/copilot.vim)

`{ src = "copilot", short_name = "COP", accept_key = "<c-f>" }`

Hitting `tmp_accept_key` will accept the suggestions once they are shown.

**This is just a quick workaround**, if its at all possible i'd like to remove `tmp_accept_key`, and include copilot suggestions right in the completion popup.

### [VimTex](https://github.com/lervag/vimtex)

`{ src = "vimtex", short_name = "vTEX" }`

### [Orgmode.nvim](https://github.com/kristijanhusak/orgmode.nvim)

`{ src = "orgmode", short_name = "ORG" }`

### [vim-dadbod-completion](https://github.com/kristijanhusak/vim-dadbod-completion)

`{ src = "vim_dadbod_completion", short_name = "DB"}`

### [nvim-dap](https://github.com/mfussenegger/nvim-dap)

`{ src = "dap" }`

Thanks [@davidatbu](https://github.com/davidatbu) <3

---

## FYI

None of the code under `require('coq_3p')` is public API.

From the users' prespective, any change I make should be transparent, ie. I will try to not break their stuff.

For other plugin developers, if you want to re-use my code. Make a COPY, do not just `require "blah"` from this repo.

I want to reserve the ability to fearlessly re-factor.
