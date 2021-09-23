function! ncm2#register_source(source)
  call luaeval('require("ncm2")(unpack(...))', [a:source])
endfunction
