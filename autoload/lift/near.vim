" Author: Adrián Pérez de Castro <aperez@igalia.com>
" License: GPLv3

if exists('g:loaded_lift_near_autoload')
	finish
endif
let g:loaded_lift_near_autoload = 1

let s:save_cpo = &cpo
set cpo&vim


let g:lift#near#backward_lines =
	\ get(g:, 'lift#near#backward_lines', 150)
let g:lift#near#forward_lines =
	\ get(g:, 'lift#near#forward_lines', 50)


" TODO: This is kinda crappy, inline it in the completion function or
"       rewrite it in a generic way that can be reused and move it to
"       and utility belt module.
function s:word_under_cursor()
	let l:line = getline('.')
	let l:index = col('.') - 1
	let l:start = l:index
	while l:index > 0
		let l:index -= 1
		if !(l:line[l:index] =~ '\w')
			let l:index += 1
			break
		endif
	endwhile
	return strpart(l:line, l:index, l:start - l:index)
endfunction


function lift#near#complete(findstart, base)
	if a:findstart
		let l:line = getline('.')
		let l:start = col('.') - 1
 
		" Find the first non-word character, backwards.
		while l:start >= 0 && l:line[l:start - 1] =~ '\W'
			let l:start -= 1
		endwhile

		return l:start
	endif

	let l:word = s:word_under_cursor()
	let l:fullword = a:base . l:word
	if len(l:fullword) < 1
		return []
	endif

	let l:line = line('.')

	let l:start_line = l:line - g:lift#near#backward_lines
	if g:lift#near#backward_lines == 0
		let l:start_line = line('w0')
	elseif g:lift#near#backward_lines < 0 || l:start_line < 0
		let l:start_line = 0
	endif

	let l:end_line = l:line + g:lift#near#forward_lines
	if g:lift#near#forward_lines == 0
		let l:end_line = line('w$')
	elseif g:lift#near#forward_lines < 0 || l:end_line > line('$')
		let l:end_line = line('$')
	endif

	let l:matches = []

	" Matches from the current line backwards
	let l:cur = l:line
	while l:cur != -1
		for l:w in split(getline(l:cur), '\W\+')
			let l:completion = strpart(l:w, len(l:word), len(l:w))
			if len(l:completion) > 0 && l:w =~ '^' . l:fullword . '.*$'
				call add(l:matches, { 'word': l:completion, 'abbr': l:w })
			endif
		endfor
		" Make sure we are not making the editor jank.
		if complete_check()
			break
		endif

		if l:cur < l:start_line
			let l:cur = l:line + 1
		elseif l:cur > l:end_line
			let l:cur = -1
		elseif l:cur <= l:line
			let l:cur -= 1
		else
			let l:cur += 1
		endif
	endwhile

	return l:matches
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
