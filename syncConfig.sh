current_path=$(pwd)

mkdir -p ~/.local/share/nvim/site/autoload

curl -o ~/.local/share/nvim/site/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim 

mkdir -p ~/.config/nvim

ln -s $current_path/neovim-normal/init.vim ~/.config/nvim/init.vim

mkdir -p ~/.config/alacritty
ln -s $current_path/alacritty.toml ~/.config/alacritty/alacritty.toml

ln -s $current_path/tmux/.tmux.conf ~/.tmux.conf 
