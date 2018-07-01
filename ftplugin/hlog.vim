setlocal buftype=nofile
setlocal cursorline
setlocal nomodifiable
setlocal nowrap
setlocal startofline

nnoremap <silent> <buffer> s :call hermes#cli#Scope()<cr>
nnoremap <silent> <buffer> S :call hermes#cli#ScopeClear()<cr>

