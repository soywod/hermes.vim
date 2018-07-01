" ------------------------------------------------------------------ # Actions #

function! s:Actions(args)
  return [
    \['^co\?n\?n\?e\?c\?t\?', 'Connect'],
  \]
endfunction

" -------------------------------------------------------------- # Entry point #

function! hermes#EntryPoint(args)
  if a:args =~? '^ *$'
    return hermes#tool#log#Error('Command not found.')
  endif

  let farg = split(a:args, ' ')[0]
  let args = a:args[len(farg) + 1:]

  for [regex, action] in s:Actions(args)
    if farg =~? regex
      return s:Trigger(action, args)
    endif
  endfor

  return hermes#tool#log#Error('Command not found.')
endfunction

" ------------------------------------------------------------------ # Helpers #

function! s:Trigger(action, args)
  execute 'call hermes#cli#' . a:action . '("' . a:args . '")'
endfunction

