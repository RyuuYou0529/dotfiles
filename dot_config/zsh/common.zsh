# Locale and core tools.
export LANG="${LANG:-en_US.UTF-8}"

if command -v hx >/dev/null 2>&1; then
  export EDITOR='hx'
elif command -v vim >/dev/null 2>&1; then
  export EDITOR='vim'
else
  export EDITOR='vi'
fi
export VISUAL="$EDITOR"
export PAGER='less'
export LESS='-FRX'

# History is local to each machine and is never managed by chezmoi.
typeset -g HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
typeset -g HISTSIZE=50000
typeset -g SAVEHIST=50000
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# Completion must be initialized before ZLE plugins.
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select

# Small, dependency-free prompt.
PROMPT=$'%F{cyan}%B%(6~|.../%5~|%~)%b%f\n%(?,%F{green},%F{red})%B%(!.#.>)%b%f '

autoload -Uz add-zsh-hook
_dotfiles_set_terminal_title() {
  print -Pn '\e]0;%~\a'
}
add-zsh-hook precmd _dotfiles_set_terminal_title

alias cls='clear'
alias ll='ls -alF'
