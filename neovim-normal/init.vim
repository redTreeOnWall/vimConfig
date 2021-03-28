"plug
"https://github.com/junegunn/vim-plug#usage
call plug#begin('~/.local/share/nvim/plugged')

	Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
	Plug 'redTreeOnWall/VimColor'		"我的主题
	Plug 'blueshirts/darcula'		" idea 主题
"	Plug 'vim-scripts/AutoComplPop'  	" 自动补全 自动联想
"	Plug 'kien/ctrlp.vim' 			"按ctr-p快速跳转到文件
	"Plug 'neoclide/coc.nvim', {'do': { -> coc#util#install()}}

call plug#end()

" pligin setting
map <F2> :NERDTreeToggle<CR>


set noundofile
set nocompatible
set nobackup
set noswapfile
set history=1024
set autochdir
set whichwrap=b,s,<,>,[,]
set nobomb
set backspace=indent,eol,start whichwrap+=<,>,[,]
" Vim 的默认寄存器和系统剪贴板共享
set clipboard+=unnamed

set fileencodings=utf-8,gbk2312,gbk,gb18030,cp936
set encoding=utf-8
set langmenu=zh_CN
let $LANG = 'en_US.UTF-8'

"高亮当前
set cursorline
"设置终端的当前行的颜色
"highlight CursorLine   cterm=NONE ctermbg=black ctermfg=green guibg=black guifg=green
"highlight CursorLine   cterm=NONE guibg=#424242
set hlsearch
set number
" 窗口大小
"set lines=15 columns=80
" 分割出来的窗口位于当前窗口下边/右边
set splitbelow
set splitright

set nolist
set listchars=tab:▶\ ,eol:¬,trail:·,extends:>,precedes:<
"set guifont=Inconsolata:h11:cANSI
"set guifont=Source\ Code\ Variable:h11:cANSI
"set guifont=Consolas:h11:cANSI
"set guifont=Source\ Code\ Variable\ SemiBold:h10:cANSI
set guifont=Source\ Code\ Pro:h12:cANSI
set linespace=3

"默认最大化窗口打开
"au GUIEnter * simalt ~x 


" 主题
color darcula 

"终端鼠标复制粘贴
if has('mouse')
	set mouse-=a
endif

set diffexpr=MyDiff()
function MyDiff()
  let opt = '-a --binary '
  if &diffopt =~ 'icase' | let opt = opt . '-i ' | endif
  if &diffopt =~ 'iwhite' | let opt = opt . '-b ' | endif
  let arg1 = v:fname_in
  if arg1 =~ ' ' | let arg1 = '"' . arg1 . '"' | endif
  let arg2 = v:fname_new
  if arg2 =~ ' ' | let arg2 = '"' . arg2 . '"' | endif
  let arg3 = v:fname_out
  if arg3 =~ ' ' | let arg3 = '"' . arg3 . '"' | endif
  if $VIMRUNTIME =~ ' '
    if &sh =~ '\<cmd'
      if empty(&shellxquote)
        let l:shxq_sav = ''
        set shellxquote&
      endif
      let cmd = '"' . $VIMRUNTIME . '\diff"'
    else
      let cmd = substitute($VIMRUNTIME, ' ', '" ', '') . '\diff"'
    endif
  else
    let cmd = $VIMRUNTIME . '\diff'
  endif
  silent execute '!' . cmd . ' ' . opt . arg1 . ' ' . arg2 . ' > ' . arg3
  if exists('l:shxq_sav')
    let &shellxquote=l:shxq_sav
  endif
endfunction


