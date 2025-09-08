export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)

source $ZSH/oh-my-zsh.sh

#########################################
################# Prompt ################
#########################################

# Load git info if not already present
autoload -Uz vcs_info

# Precmd hook runs before each prompt
function set_prompt() {
  local exit_code=$?
  local prompt_color
  if [[ $exit_code -eq 0 ]]; then
    prompt_color="%F{green}"
  else
    prompt_color="%F{red}"
  fi

  # Git branch info (if in a git repo)
  vcs_info
  local git_info=""
  if [[ -n $vcs_info_msg_0_ ]]; then
    git_info=" %F{magenta}(${vcs_info_msg_0_})%f"
  fi

  PROMPT="%F{yellow}%*%f %F{blue}%n%f:%F{cyan}%~%f${git_info} ${prompt_color}\$%f "
}

# Configure vcs_info for git branch display
zstyle ':vcs_info:git:*' formats '%b'
precmd_functions+=(set_prompt)

#########################################

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
