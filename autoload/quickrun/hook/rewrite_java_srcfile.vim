let s:save_cpo = &cpo
set cpo&vim


let s:hook = {
      \ 'config' : {
      \   'enable' : 0,
      \   'tempdir' : '%{fnamemodify(tempname(), ":p:h")}',
      \   'pattern' : '\<class\>\s\+\zs\u\w*\ze',
      \   'sweep' : 1,
      \ },
      \}


function! s:on_normalized(session, context) abort dict
  let path_sep = exists('+shellslash') && !&shellslash ? '\' : '/'
  let a:session._sweep_glob_expr_list = []
  if has_key(a:session.config, 'srcfile') && !has_key(a:session.config, 'src')
    let a:session.config.enable = 0
    return
  endif
  let tempdir = quickrun#expand(self.config.tempdir)
  if !isdirectory(tempdir)
    let a:session.config.enable = 0
    return
  endif
  let pat = self.config.pattern
  let src = a:session.config.src
  let class_name = matchstr(src, pat)
  if empty(class_name)
    let a:session.config.enable = 0
    return
  endif
  let java_filepath = printf('%s%s%s.java', tempdir, path_sep, class_name)
  let class_filepath = printf('%s%s%s.class', tempdir, path_sep, class_name)
  let class_filepath_pattern = printf('%s%s%s*.class', tempdir, path_sep, class_name)
  let a:session._sweep_glob_expr_list = [class_filepath_pattern]
  let a:session.config.tempfile = java_filepath
  if writefile(split(src, '\n', 1), a:session.config.tempfile, 'b') == -1
    let a:session.config.enable = 0
    return
  endif
  let a:session.config.srcfile = a:session.config.tempfile
  if !self.config.sweep
    return
  endif
  call a:session.tempname(java_filepath)
  call a:session.tempname(class_filepath)
endfunction
let s:hook.on_normalized = function('s:on_normalized')


function! s:on_finish(session, context) abort dict
  if !self.config.sweep
    return
  endif
  call map(copy(a:session._sweep_glob_expr_list),
        \ 'map(glob(v:val, 1, 1), "delete(v:val)")')
endfunction
let s:hook.on_finish = function('s:on_finish')


function! s:priority(hook_point) abort dict
  return 100
endfunction
let s:hook.priority = function('s:priority')


function! quickrun#hook#rewrite_java_srcfile#new() abort
  return deepcopy(s:hook)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
