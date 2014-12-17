" Author: Adrián Pérez de Castro <aperez@igalia.com>
" License: GPLv3

if exists('g:loaded_lift_autoload')
	finish
endif
let g:loaded_lift_autoload = 1

let s:save_cpo = &cpo
set cpo&vim


let g:lift#max_items =
	\ get(g:, 'lift#max_items', 100)
let g:lift#max_source_items =
	\ get(g:, 'lift#max_source_items', 50)
let g:lift#sources =
	\ get(g:, 'lift#sources', { '_': ['omni', 'near', 'user'] })
let g:lift#annotate_sources =
	\ get(g:, 'lift#annotate_sources', 1)
let g:lift#debug_messages =
	\ get(g:, 'lift#debug_messages', 0)


function s:dbgmsg(level, msg)
	if g:lift#debug_messages >= a:level
		echomsg '(lift:' . a:level . ') ' . a:msg
	endif
endfunction


function lift#active_sources()
	if has_key(b:, 'lift_sources')
		return b:lift_sources
	elseif &ft != '' && has_key(g:lift#sources, &ft)
		return g:lift#sources[&ft]
	else
		return get(g:lift#sources, '_', [])
	endif
endf


" Populate the built-in sources:
"
"  * Provided by Lift:
"    - near (autoload/lift/near.vim)
""
"  * Provided by Vim:
"    - syntax ($RUNTIME/autoload/syntaxcomplete.vim)
"
let s:source_name_map = {
	\ 'near'   : 'lift#near#complete',
	\ 'syntax' : 'syntaxcomplete#Complete'
  \ }


function lift#register_source(name, function)
	for l:key in keys(s:source_name_map)
		" Check that we are not adding a duplicate key.
		if l:key == a:name
			echoerr 'lift#register_source: A source named "'
				\ . a:name . '" was already registered.'
			return
		endif

		" Check that the completion function is not already
		" associated to some other source name.
		if s:source_name_map[l:key] == a:function
			echoerr 'lift#register_source: The function "'
				\ . a:function . '" is already being used for '
				\ . 'source "' . l:key . '"'
			return
		endif
	endfor

	let s:source_name_map[a:name] = a:function
endfunction


function lift#completion_function_for_name(name)
	if a:name == 'omni'
		return &omnifunc
	elseif a:name == 'user'
		return get(b:, 'lift_saved_completefunc', &completefunc)
	else
		return get(s:source_name_map, a:name, '')
	endif
endfunction


function lift#available_sources()
	let l:result = ['omni', 'user']
	return sort(extend(l:result, keys(s:source_name_map)))
endfunction


function s:longest_source_name(sources)
	let l:len = 0
	for l:name in a:sources
		let l:name_len = len(l:name)
		if l:name_len > l:len
			let l:len = l:name_len
		endif
	endfor
	return l:len
endfunction


function s:complete_find_starts()
	let b:lift_complete_sources = []
	let b:lift_complete_starts = []
	let seen_functions = {}

	for src in lift#active_sources()
		let func = lift#completion_function_for_name(src)
		if len(func) && !has_key(seen_functions, func)
			let pos = function(func)(1, '')
			if pos >= 0
				call add(b:lift_complete_sources, src)
				call add(b:lift_complete_starts, pos)
			endif
			let seen_functions[func] = 1
		endif
	endfor

	if len(b:lift_complete_starts) == 0
		return -1
	endif

	let pos = b:lift_complete_starts[0]
	for item in b:lift_complete_starts
		if item < pos
			let pos = item
		endif
	endfor
	return pos
endfunction


function s:format_completion_item(mm)
	if type(a:mm) == type('')
		return '[s] "' . a:mm . '"'
	elseif type(a:mm) == type({})
		let info = ''
		if has_key(a:mm, 'info') && len(a:mm['info']) > 0
			let l:info = '...'
		endif
		return '[d] word="' . get(a:mm, 'word', '') .
					\ '" abbr="' . get(a:mm, 'abbr', '') .
					\ '" menu="' . get(a:mm, 'menu', '') .
					\ '" info="' . l:info .
					\ '" kind="' . get(a:mm, 'kind', '') .
					\ '" dup='   . get(a:mm, 'dup', 1) .
					\ ' empty='  . get(a:mm, 'empty', 0) .
					\ ' icase='  . get(a:mm, 'icase', 0)
	else
		return '[i] invalid type=' . type(a:mm)
	endif
endf


function lift#complete(findstart, base)
	if a:findstart
		return s:complete_find_starts()
	endif

	let annotation_length = s:longest_source_name(b:lift_complete_sources)
	let total_count = 0
	let refresh = ''

	call s:dbgmsg(1, 'complete: ↓ start ↓')
	for src in b:lift_complete_sources
		let func = lift#completion_function_for_name(src)
		if !len(func) || l:func == 'lift#complete'
			call s:dbgmsg(1, 'complete: source: ' . src . ' skipped')
			continue
		endif

		let matches = function(func)(0, a:base)
		call s:dbgmsg(1, 'complete: source: ' . src . ' (' . len(matches) . ' matches)')

		" If we are given a dictionary, make it into a list and check .refresh
		if type(matches) == type({})
			let d = matches
			unlet matches  " Avoid error about different type on reassignment
			let matches = get(d, 'words', [])
			if get(d, 'refresh', '') == 'always'
				let refresh = 'always'
				call d:dbgmsg(1, ' * got refresh flag')
			endif
			unlet d
		endif

		let source_count = 0
		for mm in matches
			call s:dbgmsg(2, ' - match: ' . s:format_completion_item(mm))
			if g:lift#annotate_sources
				" Convert strings to dictionaries, to be able to annotate
				" the completion result with the name of the source.
				if type(mm) == type('')
					let d = { 'word': mm, 'abbr': mm }
				else
					let d = mm
				endif
				unlet mm  " Allow 'mm' to change type

				" Remove duplicates.
				let d.dup = 0

				" Variable 'd' now always contains a dictionary. Either
				" prefix the source name to an existing 'menu' string, or
				" add the 'menu' key if it was not present.
				if has_key(d, 'menu') && len(d.menu) > 0
					let d.menu = printf('%*s · %s', annotation_length, src, d.menu)
				else
					let d.menu = printf('%*s', annotation_length, src)
				endif
				let mm = l:d

				call s:dbgmsg(2, '      --> ' . s:format_completion_item(mm))
			endif

			call complete_add(mm)
			unlet mm  " Allow 'mm' to change type

			let source_count += 1
			let total_count += 1

			if complete_check()
						\ || source_count > g:lift#max_source_items
						\ || total_count > g:lift#max_items
				break
			endif
		endfor

		unlet matches

		if complete_check() || total_count > g:lift#max_items
			break
		endif
	endfor
	call s:dbgmsg(1, 'complete: ↑ end ↑')
	return { 'words': [], 'refresh': l:refresh }
endfunction


function lift#trigger_completion()
	if pumvisible()
		return "\<C-n>"
	endif
	let l:col = col('.') - 1
	if !l:col || getline('.')[l:col - 1] =~ '\s'
		return "\<Tab>"
	endif
	return "\<C-x>\<C-u>\<C-u>"
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
