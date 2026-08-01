# Load Conda only when it is first used. This avoids a generated, absolute-path
# `conda init` block and keeps normal shell startup fast.
if [[ -n ${CONDA_ROOT:-} && -r "$CONDA_ROOT/etc/profile.d/conda.sh" ]]; then
  conda() {
    unfunction conda
    source "$CONDA_ROOT/etc/profile.d/conda.sh" || return
    conda "$@"
  }
fi
