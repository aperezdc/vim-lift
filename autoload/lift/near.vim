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


function s:add_completions_from_line(completions, seen, lineno, word, fullword_re)
	for l:w in split(getline(a:lineno), '\W\+')
		if has_key(a:seen, l:w)
			" Skip words for which we already generated a result.
			continue
		endif

		let l:completion = strpart(l:w, len(a:word), len(l:w))
		if len(l:completion) > 0 && l:w =~ a:fullword_re
			call add(a:completions, { 'word': l:completion, 'abbr': l:w })
			let a:seen[l:w] = 1
		endif
	endfor
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
	let l:fullword_re = a:base . l:word
	if len(l:fullword_re) < 1
		return []
	endif
	let l:fullword_re = '^' . l:fullword_re . '.*$'

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
	let l:seen = {}

	" Current line
	call s:add_completions_from_line(l:matches, l:seen, l:line, l:word, l:fullword_re)

	" Backwards
	let l:current = l:line - 1
	while l:current >= l:start_line && !complete_check()
		call s:add_completions_from_line(l:matches, l:seen, l:current, l:word, l:fullword_re)
		let l:current -= 1
	endwhile

	" Forward
	let l:current = l:line + 1
	while l:current <= l:end_line && !complete_check()
		call s:add_completions_from_line(l:matches, l:seen, l:current, l:word, l:fullword_re)
		let l:current += 1
	endwhile

	return l:matches
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
