" Author: Adrián Pérez de Castro <aperez@igalia.com>
" License: GPLv3

if exists('g:loaded_lift_plugin')
	finish
endif
let g:loaded_lift_plugin= 1

let s:save_cpo = &cpo
set cpo&vim

let g:lift#close_preview_window =
	\ get(g:, 'lift#close_preview_window', 'auto')

let g:lift#blacklist_buffers =
	\ get(g:, 'lift#blacklist_buffers', {
	\   'quickfix'  : 1,
	\   'nofile'    : 1,
	\   'help'      : 1,
	\   'directory' : 1,
	\   'unlisted'  : 1,
	\   'unite'     : 1,
	\ })


function s:buffer_insert_enter()
	if has('quickfix') && has_key(g:lift#blacklist_buffers, &buftype)
		return
	endif
	let b:lift_initialized = 1
	let b:lift_saved_completefunc = &completefunc
	setlocal completefunc=lift#complete
endfunction


function s:buffer_insert_leave()
	if get(b:, 'lift_initialized', 0)
		call s:close_preview_window()
		let &l:completefunc = b:lift_saved_completefunc
	endif
endfunction


function s:option_has_value(haystack, needle)
	let pos = stridx(a:haystack, a:needle)
	if pos == -1
		return 0
	endif

	let endpos = pos + len(a:needle)
	let before = ','
	if pos != 0
		let before = a:haystack[pos - 1]
	endif

	let after = ','
	if endpos < len(a:haystack)
		let after = a:haystack[endpos]
	endif

	return before == ',' && after == ','
endfunction


function s:close_preview_window()
	if get(b:, 'lift_initialized', 0)
				\ && ((g:lift#close_preview_window == 'auto'
				\       && s:option_has_value(&completeopt, 'preview'))
				\    || g:lift#close_preview_window)
				\ && bufname('%') !=# '[Command Line]'
				\ && winnr('$') != 1 && !&l:previewwindow
		pclose!
	endif
endfunction


augroup Lift
	autocmd!
	autocmd InsertEnter  * call s:buffer_insert_enter()
	autocmd InsertLeave  * call s:buffer_insert_leave()
	autocmd CompleteDone * call s:close_preview_window()
augroup END


let &cpo = s:save_cpo
unlet s:save_cpo
