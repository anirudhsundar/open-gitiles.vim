# open-gitiles.vim

Open (or print) a Gerrit **Gitiles** URL for the current file and line in Vim/Neovim.

- Reads the repo’s remote (`origin` by default), converts to a Gitiles URL.
- Anchors the URL to your cursor line (or the first line of a visual selection).
- **Prints** the URL by default (friendly for remote dev boxes).
- Optional command to open it in your browser.

> Gitiles only supports single-line anchors, not line ranges.

## Install

With [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'anirudhsundar/open-gitiles.vim'
