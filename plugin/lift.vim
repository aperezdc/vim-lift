" Author: Adrián Pérez de Castro <aperez@igalia.com>
" License: GPLv3

if exists('g:loaded_lift')
	finish
endif
let g:loaded_lift = 1

let s:save_cpo = &cpo
set cpo&vim

" Pick defaults
let g:lift#max_list_items =
	\ get(g:, 'lift#max_list', 100)
let g:lift#max_source_items =
	\ get(g:, 'lift#max_source_items', 50)
let g:lift#sources =
	\ get(g:, 'lift#sources', ['omni', 'user'])
let g:lift#annotate_sources =
	\ get(g:, 'lift#annotate_sources', 1)

let s:source_name_map = {}


function lift#register_source(name, function)
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
		for l:source in g:lift#sources
			let l:source = lift#completion_function_for_name(l:source)
			if l:source != ''
				let l:pos eval(l:source . '(a:findstart, a:base)')
				if l:pos >= 0
					return l:pos
				endif
			endif
		endfor
		return -1
	endif

	let l:annotation_length = s:longest_source_name(g:lift#sources)
	let l:lifted_result = []
	for l:source in g:lift#sources
		let l:complete = lift#completion_function_for_name(l:source)
		if l:complete != '' && l:complete != 'lift#complete'
			let l:matches = eval(l:complete . '(a:findstart, a:base)')
			" Add a note indicating which one
			if g:lift#annotate_sources
				let l:count = 0
				for l:match in l:matches
					let l:count += 1
					" Convert strings to dictionary items to be able to add the source name.
					if type(l:match) == type("")
						let l:match = { 'word': l:match,
						              \ 'menu': printf(' %*s · %s', l:annotation_length, l:source, l:match.menu) }
					else
						if has_key(l:match, 'menu')
							let l:match.menu = printf(' %*s · %s', l:annotation_length, l:source, l:match.menu)
						else
							let l:match.menu = ' ' . l:source
						endif
					endif
					call add(l:lifted_result, l:match)
					if l:count > g:lift#max_source_items
						break
					endif
				endfor
			else
				let l:lifted_result = extend(l:lifted_result, l:matches[:g:lift#max_source_items])
			endif
		endif
		if len(l:lifted_result) > g:lift#max_list_items
			return l:lifted_result[:g:lift#max_list_items]
		endif
	endfor
	return l:lifted_result
endfunction


function lift#trigger_completion()
	if pumvisible()
		return "\<C-p>"
	endif

	if strpart( getline('.'), 0, col('.')-1 ) =~ '^\s*$'
		return "\<Tab>"
	endif

	return "\<C-x>\<C-u>"
endfunction


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
