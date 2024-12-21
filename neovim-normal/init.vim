imap <C-j> <down>
imap <C-k> <up>
imap <C-h> <left>
imap <C-l> <right>

"plug
"https://github.com/junegunn/vim-plug#usage
call plug#begin('~/.local/share/nvim/plugged')
  Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }

  Plug 'redTreeOnWall/VimColor'

  Plug 'blueshirts/darcula'

  Plug 'neoclide/coc.nvim', {'branch': 'master', 'do': 'npm install --frozen-lockfile'} " LSP
  Plug 'neoclide/coc-tsserver', {'do': 'npm install --frozen-lockfile'} " typescript
  Plug 'neoclide/coc-java', {'do': 'npm install --frozen-lockfile'} " java
  Plug 'clangd/coc-clangd', {'do': 'npm install --frozen-lockfile'} " c/c++
  Plug 'neoclide/coc-html', {'do': 'npm install --frozen-lockfile'} " html
  Plug 'neoclide/coc-css', {'do': 'npm install --frozen-lockfile'} " html
  Plug 'neoclide/coc-eslint', {'do': 'npm install --frozen-lockfile'} " eslint
  " Plug 'neoclide/coc-prettier', {'do': 'npm install --frozen-lockfile'} " prettier
  Plug 'iamcco/coc-spell-checker', {'do': 'npm install --frozen-lockfile'}  " spell check


  Plug 'nvim-lua/plenary.nvim'

  Plug 'nvim-telescope/telescope.nvim'

  Plug 'tpope/vim-fugitive' " git

  " Plug 'vim-airline/vim-airline'
  "
  " Plug 'vim-airline/vim-airline-themes'

  Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && npm install'  } " markdown 增强和实时预览

  Plug 'ferrine/md-img-paste.vim'  " paste image in markdown 

  Plug 'dhruvasagar/vim-table-mode' " align table in markdown 

  Plug 'easymotion/vim-easymotion'

  Plug 'sindrets/diffview.nvim'

  Plug 'mattn/emmet-vim'

call plug#end()

" plugin setting
map <F2> :NERDTreeToggle<CR>

" md-img-paste
" TODO 

" ------- coc start ---------
" May need for Vim (not Neovim) since coc.nvim calculates byte offset by count
" utf-8 byte sequence
set encoding=utf-8
" Some servers have issues with backup files, see #649
set nobackup
set nowritebackup

" Having longer updatetime (default is 4000 ms = 4s) leads to noticeable
" delays and poor user experience
set updatetime=300

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved
set signcolumn=yes

" Use tab for trigger completion with characters ahead and navigate
" NOTE: There's always complete item selected by default, you may want to enable
" no select by `"suggest.noselect": true` in your configuration file
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window
nnoremap <silent> K :call ShowDocumentation()<CR>

function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s)
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Applying code actions to the selected code block
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying code actions at the cursor position
nmap <leader>ac  <Plug>(coc-codeaction-cursor)
" Remap keys for apply code actions affect whole buffer
nmap <leader>as  <Plug>(coc-codeaction-source)
" Apply the most preferred quickfix action to fix diagnostic on the current line
nmap <leader>qf  <Plug>(coc-fix-current)

" Remap keys for applying refactor code actions
nmap <silent> <leader>re <Plug>(coc-codeaction-refactor)
xmap <silent> <leader>r  <Plug>(coc-codeaction-refactor-selected)
nmap <silent> <leader>r  <Plug>(coc-codeaction-refactor-selected)

" Run the Code Lens action on the current line
nmap <leader>cl  <Plug>(coc-codelens-action)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Remap <C-f> and <C-b> to scroll float windows/popups
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
  inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
  inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
  vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif

" Use CTRL-S for selections ranges
" Requires 'textDocument/selectionRange' support of language server
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer
command! -nargs=0 Format :call CocActionAsync('format')

" Add `:Fold` command to fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer
command! -nargs=0 OR   :call     CocActionAsync('runCommand', 'editor.action.organizeImport')

" Add (Neo)Vim's native statusline support
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Mappings for CoCList
" Show all diagnostics
nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions
nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
" Show commands
nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document
nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item
nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item
nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list
nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>

let g:coc_default_semantic_highlight_groups = 1
" coc-setting.json
"semanticTokens.filetypes": ["*"],
let g:coc_preferences_semanticTokensHighlights = 1

" ------------ telescope start ----------
" Find files using Telescope command-line sugar.
nnoremap <leader>fo <cmd>Telescope oldfiles<cr>
nnoremap <c-p> <cmd>Telescope oldfiles<cr>
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>
lua <<EOF
require('telescope').setup{
  defaults = {
    path_display={'smart'},
  },
  pickers = {
    find_files = {
      previewer = false,
    },
    oldfiles = {
      previewer = false,
    },
    buffers = {
      previewer = false,
    },
  },
}
EOF

" ------------ md-img-paste.vim ----------
autocmd FileType markdown nmap <buffer><silent> <leader>p :call mdip#MarkdownClipboardImage()<CR>
" there are some defaults for image directory and image name, you can change them
" let g:mdip_imgdir = 'img'
" let g:mdip_imgname = 'image'

" ------------- markdown-preview -----------
let g:mkdp_theme = 'light'

" ------------- easy-motion ----------------
" s{char}{char} to move to {cahr}{char}
nmap s <Plug>(easymotion-overwin-f2)
vmap s <Plug>(easymotion-overwin-f2)

set tabstop=2
set shiftwidth=2
set expandtab

set fdm=indent
set nofoldenable
" zc zo zC zo zn zN

set noundofile
set nocompatible
set nobackup
set noswapfile
set history=1024
set autochdir
set whichwrap=b,s,<,>,[,]
set nobomb
set backspace=indent,eol,start whichwrap+=<,>,[,]

" set clipboard+=unnamed

set fileencodings=utf-8,gbk2312,gbk,gb18030,cp936
set encoding=utf-8
let $LANG = 'en_US.UTF-8'

set cursorline
set hlsearch
set number
set splitbelow
set splitright

" set colorcolumn=80

set nolist
set listchars=tab:▶\ ,eol:¬,trail:·,extends:>,precedes:<

imap <C-j> <down>
imap <C-k> <up>
imap <C-h> <left>
imap <C-l> <right>

nmap <Space>2 :NERDTreeToggle<CR>
nmap <Space>3 :NERDTreeFind<CR>
nmap <Space>t :tabnew<CR>
nmap <Space>q :q<CR>
nmap <Space>v :vsplit<CR>
nmap <Space>n :nohlsearch<CR>
nmap <Space>d :put =strftime('# %Y-%m-%d %H:%M:%S')<CR>

nmap <Space>w :w<CR>
nmap <Space>l :w<CR>

nmap <C-u> <C-b>
nmap <C-d> <C-f>
vmap <C-u> <C-b>
vmap <C-d> <C-f>

nmap <Space>k <C-b>
nmap <Space>j <C-f>
vmap <Space>k <C-b>
vmap <Space>j <C-f>

vmap <C-y> "+y

inoremap jk <ESC>

" 主题
color darculaTransparent

if has('mouse')
	set mouse-=a
endif

set mouse=

command RlspTsserver :CocComand tsserver.restart

nmap <Space>p :CocCommand eslint.executeAutofix <CR>

hi CocFloating ctermbg=237 guibg=#2b2b2b
