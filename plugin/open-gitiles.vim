" plugin/open-gitiles.vim
if exists('g:loaded_open_gitiles_plugin') | finish | endif
let g:loaded_open_gitiles_plugin = 1

" Defaults
let g:open_gitiles_open_browser      = get(g:, 'open_gitiles_open_browser', 0) " print by default
let g:open_gitiles_use_branch        = get(g:, 'open_gitiles_use_branch', 0)
let g:open_gitiles_path              = get(g:, 'open_gitiles_path', '/plugins/gitiles')
let g:open_gitiles_copy_to_clipboard = get(g:, 'open_gitiles_copy_to_clipboard', 1)

" :OpenGitiles [remote]
" - normal mode: opens at cursor line
" - visual/range: uses first line of selection (Gitiles can't highlight a range)
command! -range -nargs=? OpenGitiles       call open_gitiles#Open(<line1>, <line2>, <f-args>)

" Force behaviors regardless of g:open_gitiles_open_browser
command! -range -nargs=? OpenGitilesEcho   call open_gitiles#OutputUrl(open_gitiles#BuildUrl(<line1>, <line2>, <f-args>))
command! -range -nargs=? OpenGitilesBrowse call open_gitiles#OpenUrl(open_gitiles#BuildUrl(<line1>, <line2>, <f-args>))

" Optional example mappings (commented out; add to your vimrc if you like)
" nnoremap <silent> <leader>go :OpenGitiles<CR>
" xnoremap <silent> <leader>go :<C-U>OpenGitiles<CR>
