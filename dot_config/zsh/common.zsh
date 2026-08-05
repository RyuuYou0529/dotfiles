# Locale and core tools.
export LANG="${LANG:-en_US.UTF-8}"

if command -v hx >/dev/null 2>&1; then
  export EDITOR='hx'
elif command -v helix >/dev/null 2>&1; then
  export EDITOR='helix'
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
autoload -Uz add-zsh-hook vcs_info
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr '*'
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:git:*' formats '%b%c%u'
zstyle ':vcs_info:git:*' actionformats '%b|%a%c%u'

_dotfiles_update_vcs_info() {
  vcs_info
  [[ -n $vcs_info_msg_0_ ]] || return

  local git_status
  if [[ $vcs_info_msg_0_ == *\** ]]; then
    vcs_info_msg_0_=${vcs_info_msg_0_//\*/}
    git_status='%F{#F38BA8}✗%f'
  else
    git_status='%F{#A6E3A1}●%f'
  fi
  typeset -g vcs_info_msg_0_="%F{#F9E2AF}git:${vcs_info_msg_0_}%f ${git_status}"
}
add-zsh-hook precmd _dotfiles_update_vcs_info

case "$OSTYPE" in
  darwin*) typeset -g _DOTFILES_OS_PROMPT='%F{#CBA6F7}⌘%f' ;;
  linux*)  typeset -g _DOTFILES_OS_PROMPT='%F{#94E2D5}◆%f' ;;
  *)       typeset -g _DOTFILES_OS_PROMPT='%F{#94E2D5}◇%f' ;;
esac

if (( EUID == 0 )); then
  typeset -g _DOTFILES_USER_PROMPT='%K{#8C2D3B}%F{white} %n %f%k%F{#89B4FA}@%m%f'
else
  typeset -g _DOTFILES_USER_PROMPT='%F{#89B4FA}%n@%m%f'
fi

setopt PROMPT_SUBST
PROMPT=$'${_DOTFILES_OS_PROMPT} ${_DOTFILES_USER_PROMPT} %F{#89DCEB}%B%(6~|.../%5~|%~)%b%f ${vcs_info_msg_0_}\n%(?,%F{#A6E3A1},%F{#F38BA8})%B%(!.#.>)%b%f '

_dotfiles_set_terminal_title() {
  print -Pn '\e]0;%~\a'
}
add-zsh-hook precmd _dotfiles_set_terminal_title

alias cls='clear'
alias ll='ls -alF'
