export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

[[ -d /opt/homebrew/lib/node_modules ]] &&
  export NODE_PATH='/opt/homebrew/lib/node_modules'
