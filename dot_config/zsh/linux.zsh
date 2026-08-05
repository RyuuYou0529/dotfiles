# Configure workstation tools only when their machine-local roots exist.
if [[ -n ${CUDA_ROOT:-} && -d "$CUDA_ROOT" ]]; then
  export CUDA_HOME="$CUDA_ROOT"
  path=("$CUDA_HOME/bin" $path)
  typeset -U path PATH
  export PATH

  if [[ -d "$CUDA_HOME/lib64" && ":${LD_LIBRARY_PATH:-}:" != *":$CUDA_HOME/lib64:"* ]]; then
    export LD_LIBRARY_PATH="$CUDA_HOME/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  fi
fi

if [[ -n ${NVM_ROOT:-} && -r "$NVM_ROOT/nvm.sh" ]]; then
  export NVM_DIR="$NVM_ROOT"
  source "$NVM_DIR/nvm.sh"
fi

if [[ -z ${DISPLAY:-} && -n ${DISPLAY_DEFAULT:-} ]]; then
  export DISPLAY="$DISPLAY_DEFAULT"
fi

command -v zellij >/dev/null 2>&1 && alias zlj='zellij'
