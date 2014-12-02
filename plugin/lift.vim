" Author: Adrián Pérez de Castro <aperez@igalia.com>
" License: GPLv3

if exists('g:loaded_lift_plugin')
	finish
endif
let g:loaded_lift_plugin= 1

let s:save_cpo = &cpo
set cpo&vim

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
	let b:lift_initialized = 0
	let b:lift_saved_completefunc = &completefunc
	setlocal completefunc=lift#complete
endfunction

function s:buffer_insert_leave()
	if has_key(b:, 'lift_initialized')
		let &l:completefunc = b:lift_saved_completefunc
	endif
endfunction

augroup Lift
autocmd InsertEnter * call s:buffer_insert_enter()
autocmd InsertLeave * call s:buffer_insert_leave()
augroup END


let &cpo = s:save_cpo
unlet s:save_cpo
