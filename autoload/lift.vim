" Author: Adrián Pérez de Castro <aperez@igalia.com>
" License: GPLv3

if exists('g:loaded_lift_autoload')
	finish
endif
let g:loaded_lift_autoload = 1

let s:save_cpo = &cpo
set cpo&vim


let g:lift#max_list_items =
	\ get(g:, 'lift#max_list', 100)
let g:lift#max_source_items =
	\ get(g:, 'lift#max_source_items', 50)
let g:lift#sources =
	\ get(g:, 'lift#sources', { '_': ['omni', 'near', 'user'] })
let g:lift#annotate_sources =
	\ get(g:, 'lift#annotate_sources', 1)


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


function lift#complete(findstart, base)
	if a:findstart
		let b:lift_complete_sources = []
		let b:lift_complete_starts = []
		for l:source in lift#active_sources()
			let l:source_func = lift#completion_function_for_name(l:source)
			if l:source_func != ''
				let l:pos = function(l:source_func)(1, a:base)
				if l:pos >= 0
					call add(b:lift_complete_sources, l:source)
					call add(b:lift_complete_starts, l:pos)
				endif
			endif
		endfor

		if len(b:lift_complete_starts) == 0
			return -1
		endif

		let l:pos = b:lift_complete_starts[0]
		for l:p in b:lift_complete_starts
			if l:p < l:pos
				let l:pos = l:p
			endif
		endfor
		return l:pos
	endif

	let l:refresh = ''
	let l:annotation_length = s:longest_source_name(b:lift_complete_sources) + 1
	for l:source in b:lift_complete_sources
		let l:complete = lift#completion_function_for_name(l:source)
		if l:complete != '' && l:complete != 'lift#complete'
			let l:matches = function(l:complete)(0, a:base)

			" If we are given a dictionary, make it into a list and check .refresh
			if type(l:matches) == type({})
				let l:dict = l:matches
				unlet l:matches  " Avoid error about different type on reassignment
				let l:matches = get(l:dict, 'words', [])
				if get(l:dict, 'refresh', '') == 'always'
					let l:refresh = 'always'
				endif
				unlet l:dict
			endif

			" Add a note indicating which one
			if g:lift#annotate_sources
				let l:count = 0
				for l:match in l:matches
					" Convert strings to dictionary items to be able to add the source name.
					if type(l:match) == type('')
						call complete_add({ 'word': l:match,
						                  \ 'menu': printf('%*s', l:annotation_length, l:source) })
					else
						if has_key(l:match, 'menu') && len(l:match.menu) > 0
							let l:match.menu = printf('%*s · %s', l:annotation_length, l:source, l:match.menu)
						else
							let l:match.menu = printf('%*s', l:annotation_length,  l:source)
						endif
						call complete_add(l:match)
					endif

					let l:count += 1
					if l:count > g:lift#max_source_items
						break
					endif

					" Allow l:match to be of different type in the next iteration.
					unlet l:match
				endfor
			else
				for l:match in l:matches
					call complete_add(l:match)
				endfor
			endif
			unlet l:matches
		endif

		if complete_check()
			break
		endif
	endfor
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
	return "\<C-x>\<C-u>"
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
