[[ -o zle && -t 0 && -t 1 ]] || return

typeset _dotfiles_vendor_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/vendor"

source "$_dotfiles_vendor_dir/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Syntax highlighting must be sourced after completion, fzf, and custom widgets.
source "$_dotfiles_vendor_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

unset _dotfiles_vendor_dir
