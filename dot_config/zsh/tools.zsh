# fzf provides fuzzy history search with Ctrl-R and optional file/directory pickers.
export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border --color=light'

if [[ -o zle && -t 0 && -t 1 ]] &&
  command -v fzf >/dev/null 2>&1 && fzf --zsh >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# Yazi wrapper: leave Yazi in the directory selected before quitting.
if command -v yazi >/dev/null 2>&1; then
  y() {
    local tmp cwd
    tmp="$(mktemp -t 'yazi-cwd.XXXXXX')" || return
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [[ "$cwd" != "$PWD" && -d "$cwd" ]] && builtin cd -- "$cwd"
    command rm -f -- "$tmp"
  }
fi

if [[ -o zle && -t 0 && -t 1 ]]; then
  # Open the current command line in $VISUAL with the conventional ZLE binding.
  autoload -Uz edit-command-line
  zle -N edit-command-line
  bindkey '^X^E' edit-command-line
fi
