setlocal buftype=nofile
setlocal cursorline
setlocal nomodifiable
setlocal nowrap
setlocal startofline

nnoremap <silent> <buffer> 1 :call hermes#cli#ScopeChange(0)<cr>
nnoremap <silent> <buffer> 2 :call hermes#cli#ScopeChange(1)<cr>
nnoremap <silent> <buffer> 3 :call hermes#cli#ScopeChange(2)<cr>
nnoremap <silent> <buffer> s :call hermes#cli#ScopeSet()<cr>

