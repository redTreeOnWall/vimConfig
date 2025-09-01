function proxy_on(){
    export all_proxy=http://127.0.0.1:10080
    echo -e "proxy on"
}
function proxy_off(){
    unset all_proxy
    echo -e "proxy off"
}

alias pc="proxychains4"

alias ll="ls -lah"
