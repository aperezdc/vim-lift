" Author: Adrián Pérez de Castro <aperez@igalia.com>
" License: GPLv3

if exists('g:loaded_lift_plugin')
	finish
endif
let g:loaded_lift_plugin= 1

let s:save_cpo = &cpo
set cpo&vim

function s:buffer_insert_enter()
	let b:lift_saved_completefunc = &completefunc
	setlocal completefunc=lift#complete
endfunction

function s:buffer_insert_leave()
	let &l:completefunc = b:lift_saved_completefunc
endfunction

augroup Lift
autocmd InsertEnter * call s:buffer_insert_enter()
autocmd InsertLeave * call s:buffer_insert_leave()
augroup END


let &cpo = s:save_cpo
unlet s:save_cpo
