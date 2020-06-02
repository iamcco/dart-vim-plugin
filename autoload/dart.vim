" Finds the path to `uri`.
"
" If the file is a package: uri, looks for a .packages file to resolve the path.
" If the path cannot be resolved, or is not a package: uri, returns the
" original.
function! dart#resolveUri(uri) abort
  if a:uri !~# 'package:'
    return a:uri
  endif
  let package_name = substitute(a:uri, 'package:\(\w\+\)\/.*', '\1', '')
  let [found, package_map] = s:PackageMap()
  if !found
    call s:error('cannot find .packages file')
    return a:uri
  endif
  if !has_key(package_map, package_name)
    call s:error('no package mapping for '.package_name)
    return a:uri
  endif
  let package_lib = package_map[package_name]
  return substitute(a:uri,
      \ 'package:'.package_name,
      \ escape(package_map[package_name], '\'),
      \ '')
endfunction

" A map from package name to lib directory parse from a '.packages' file.
"
" Returns [found, package_map]
function! s:PackageMap() abort
  let [found, dot_packages] = s:DotPackagesFile()
  if !found
    return [v:false, {}]
  endif
  let dot_packages_dir = fnamemodify(dot_packages, ':p:h')
  let lines = readfile(dot_packages)
  let map = {}
  for line in lines
    if line =~# '\s*#'
      continue
    endif
    let package = substitute(line, ':.*$', '', '')
    let lib_dir = substitute(line, '^[^:]*:', '', '')
    if lib_dir =~# 'file:/'
      let lib_dir = substitute(lib_dir, 'file://', '', '')
      if lib_dir =~# '/[A-Z]:/'
        let lib_dir = lib_dir[1:]
      endif
    else
      let lib_dir = resolve(dot_packages_dir.'/'.lib_dir)
    endif
    if lib_dir =~# '/$'
      let lib_dir = lib_dir[:len(lib_dir) - 2]
    endif
    let map[package] = lib_dir
  endfor
  return [v:true, map]
endfunction

" Finds a file name '.packages' in the cwd, or in any directory above the open
" file.
"
" Returns [found, file].
function! s:DotPackagesFile() abort
  if filereadable('.packages')
    return [v:true, '.packages']
  endif
  let dir_path = expand('%:p:h')
  while v:true
    let file_path = dir_path.'/.packages'
    if filereadable(file_path)
      return [v:true, file_path]
    endif
    let parent = fnamemodify(dir_path, ':h')
    if dir_path == parent
      break
    endif
    let dir_path = parent
  endwhile
  return [v:false, '']
endfunction
