" autoload/open_gitiles.vim
if exists('g:autoload_open_gitiles_loaded') | finish | endif
let g:autoload_open_gitiles_loaded = 1

function! open_gitiles#UrlEncodePath(p) abort
  " Very-nomagic to ignore user 'magic' settings
  let s = a:p
  let s = substitute(s, '\V%', '%25', 'g')
  let s = substitute(s, '\V#', '%23', 'g')
  let s = substitute(s, '\V ', '%20', 'g')
  let s = substitute(s, '\V?', '%3F', 'g')
  let s = substitute(s, '\V+', '%2B', 'g')
  return s
endfunction

function! open_gitiles#NormalizeRemote(remote) abort
  let s = trim(a:remote)

  " scp-like: [user@]host:path
  if s =~# '^[^/]\+:[^/]'
    let colon     = match(s, ':')
    let hostpart  = strpart(s, 0, colon)
    let path      = strpart(s, colon + 1)
    let at        = match(hostpart, '@')
    let host      = (at >= 0) ? strpart(hostpart, at + 1) : hostpart
    let url       = 'https://' . host . '/' . path

  " ssh://[user@]host[:port]/path
  elseif s =~# '^ssh://'
    let rest      = s[6:]
    let at        = match(rest, '@')
    if at >= 0 | let rest = strpart(rest, at + 1) | endif
    let slash     = match(rest, '/')
    if slash == -1
      let url = 'https://' . rest
    else
      let hostport  = strpart(rest, 0, slash)
      let path      = strpart(rest, slash + 1)
      let colon     = match(hostport, ':')
      let host      = (colon >= 0) ? strpart(hostport, 0, colon) : hostport
      let url       = 'https://' . host . '/' . path
    endif

  " http(s) or bare host/path
  else
    if s =~# '^http://'
      let url = 'https://' . s[7:]
    elseif s =~# '^https://'
      let url = s
    else
      let url = 'https://' . s
    endif
  endif

  " Normalize Gerrit quirks
  let url = substitute(url, '://\([^/]\+\)/a/', '://\1/', '')
  let url = substitute(url, '\.git$', '', '')
  return url
endfunction

function! open_gitiles#ToGitilesBase(url) abort
  if a:url =~# 'googlesource\.com' || a:url =~# '/plugins/gitiles/' || a:url =~# '/gitiles/'
    return a:url
  endif
  " Insert configured mount after scheme+host
  let s      = a:url
  let mount  = get(g:, 'open_gitiles_path', '/plugins/gitiles')
  let sep    = match(s, '://')
  let start  = (sep >= 0) ? sep + 3 : 0
  let slash  = match(s, '/', start)
  if slash == -1
    return s . mount
  endif
  return strpart(s, 0, slash) . mount . strpart(s, slash)
endfunction

function! open_gitiles#GetRevision() abort
  if get(g:, 'open_gitiles_use_branch', 0)
    let rev = trim(system('git rev-parse --abbrev-ref HEAD'))
    if v:shell_error || rev ==# 'HEAD'
      let rev = trim(system('git rev-parse HEAD'))
    else
      let rev = 'refs/heads/' . rev
    endif
  else
    let rev = trim(system('git rev-parse HEAD'))
  endif
  return v:shell_error || empty(rev) ? '' : rev
endfunction

function! open_gitiles#RepoRoot() abort
  let root = trim(system('git rev-parse --show-toplevel'))
  return v:shell_error ? '' : root
endfunction

function! open_gitiles#RelativePath(abs, root) abort
  if empty(a:abs) | return '' | endif
  let rel = a:abs
  if rel[:strlen(a:root)-1] ==# a:root
    let rel = rel[strlen(a:root):]
    if rel =~# '^[\/\\]'
      let rel = rel[1:]
    endif
  endif
  return substitute(rel, '\\', '/', 'g')
endfunction

function! open_gitiles#RemoteUrl(remote_name) abort
  let rname  = empty(a:remote_name) ? 'origin' : a:remote_name
  let remote = trim(system('git remote get-url --push ' . shellescape(rname)))
  if v:shell_error
    let remote = trim(system('git remote get-url ' . shellescape(rname)))
  endif
  return v:shell_error || empty(remote) ? '' : remote
endfunction

function! open_gitiles#BuildUrl(line1, line2, ...) abort
  let root = open_gitiles#RepoRoot()
  if empty(root) | echoerr 'open-gitiles: not inside a Git repo' | return '' | endif

  let abs = expand('%:p')
  if empty(abs) | echoerr 'open-gitiles: buffer has no file name' | return '' | endif

  let rel = open_gitiles#RelativePath(abs, root)
  if empty(rel) | echoerr 'open-gitiles: could not compute repo-relative path' | return '' | endif

  let remote = open_gitiles#RemoteUrl(a:0 >= 1 ? a:1 : '')
  if empty(remote) | echoerr 'open-gitiles: cannot determine remote URL' | return '' | endif

  let base = open_gitiles#ToGitilesBase(open_gitiles#NormalizeRemote(remote))
  let rev  = open_gitiles#GetRevision()
  if empty(rev) | echoerr 'open-gitiles: cannot resolve revision' | return '' | endif

  " Gitiles supports single-line anchors only; use start of range
  let l1 = a:line1
  let l2 = a:line2
  if l1 > l2 | let tmp = l1 | let l1 = l2 | let l2 = tmp | endif
  let anchor = '#' . l1

  return base . '/+/' . rev . '/' . open_gitiles#UrlEncodePath(rel) . anchor
endfunction

function! open_gitiles#OutputUrl(url) abort
  if empty(a:url) | return | endif
  let g:last_open_gitiles_url = a:url
  echom a:url
  if get(g:, 'open_gitiles_copy_to_clipboard', 1)
    try | call setreg('+', a:url) | catch | endtry
    try | call setreg('*', a:url) | catch | endtry
  endif
endfunction

function! open_gitiles#OpenUrl(url) abort
  if empty(a:url) | return | endif
  if exists('*netrw#BrowseX')
    call netrw#BrowseX(a:url, 0)
  else
    if has('mac')
      call system('open ' . shellescape(a:url))
    elseif has('unix')
      call system('xdg-open ' . shellescape(a:url) . ' >/dev/null 2>&1 &')
    elseif has('win32') || has('win64')
      call system('cmd /c start "" ' . shellescape(a:url))
    else
      echoerr 'open-gitiles: cannot open browser on this OS'
    endif
  endif
endfunction

function! open_gitiles#Open(line1, line2, ...) abort
  let url = open_gitiles#BuildUrl(a:line1, a:line2, (a:0 >= 1 ? a:1 : ''))
  if empty(url) | return | endif
  if get(g:, 'open_gitiles_open_browser', 0)
    call open_gitiles#OpenUrl(url)
  else
    call open_gitiles#OutputUrl(url)
  endif
endfunction
