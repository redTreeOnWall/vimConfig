function proxy_on(){
    export all_proxy=http://127.0.0.1:10080
    echo -e "proxy on"
}
function proxy_off(){
    unset all_proxy
    echo -e "proxy off"
}

# alias brew="/Users/reno/git/third/homebrew/bin/brew"

alias nvim="/Users/reno/soft/neovim/nvim-macos/bin/nvim"

# alias proxychains4="/Users/reno/soft/proxychains-ng/proxychains-ng-4.16/proxychains4"
alias pc="proxychains4"


tmux0(){
  first=$(tmux -d : -f 1ls | head -n 1 | cut -d :f 1)
  tmux a -t $first
}

alias ll="ls -lah"


# WSL clipboard
alias pbcopy="clip.exe"
alias pbpaste="powershell.exe -command 'Get-Clipboard' | head -n -1"



