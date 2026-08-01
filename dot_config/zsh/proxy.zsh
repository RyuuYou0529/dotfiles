proxy_on() {
  if [[ -z ${PROXY_HTTP_URL:-} ]]; then
    print -u2 'PROXY_HTTP_URL is not configured.'
    return 1
  fi

  export HTTP_PROXY="$PROXY_HTTP_URL"
  export HTTPS_PROXY="$PROXY_HTTP_URL"
  export http_proxy="$HTTP_PROXY"
  export https_proxy="$HTTPS_PROXY"

  if [[ -n ${PROXY_SOCKS_URL:-} ]]; then
    export ALL_PROXY="$PROXY_SOCKS_URL"
    export all_proxy="$ALL_PROXY"
  else
    unset ALL_PROXY all_proxy
  fi

  export NO_PROXY="${PROXY_NO_PROXY:-localhost,127.0.0.1,::1}"
  export no_proxy="$NO_PROXY"
}

proxy_off() {
  unset HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY
  unset http_proxy https_proxy all_proxy no_proxy
}

proxy_status() {
  if [[ -n ${HTTP_PROXY:-} ]]; then
    print "HTTP proxy:  $HTTP_PROXY"
    print "SOCKS proxy: ${ALL_PROXY:-disabled}"
    print "No proxy:    ${NO_PROXY:-not configured}"
  else
    print 'Proxy: disabled'
  fi
}

with_proxy() (
  proxy_on || exit
  "$@"
)

[[ ${PROXY_AUTO_ENABLE:-1} == 1 ]] && proxy_on
