export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)

source $ZSH/oh-my-zsh.sh

#######  #######   #####   #     #  #######  #######
#     #  #     #  #     #  ##   ##  #     #     #
#     #  #     #  #     #  # # # #  #     #     #
#######  #######  #     #  #  #  #  #######     #
#        #   #    #     #  #     #  #           #
#        #    #   #     #  #     #  #           #
#        #     #   #####   #     #  #           #

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

# Refresh the prompt
autoload -Uz add-zsh-hook
add-zsh-hook precmd set_prompt
zstyle ':vcs_info:git:*' formats '%b'

# 3. Add auto-refreshing prompt (ONLY for interactive shells)
if [[ -o interactive ]]; then
  TMOUT=1
  TRAPALRM() {
    zle reset-prompt
  }
  zle -N TRAPALRM
fi

 #####     ###   #######        #     #         ###       #      #####   #######   #####
#           #       #          # #    #          #       # #    #        #        #
#           #       #         #   #   #          #      #   #   #        #        #
#  ####     #       #        #     #  #          #     #     #   #####   #######   #####
#     #     #       #        #######  #          #     #######        #  #              #
#     #     #       #        #     #  #          #     #     #        #  #              #
 #####     ###      #        #     #  #######   ###    #     #   #####   #######   #####

# Add indexed git add function: 'gad <n>' adds the nth file from 'git status --short'
# If 'p' is given as the second argument, runs 'git add -p' on the file.
function gad() {
  local idx=$1
  local mode=$2
  if [[ -z $idx || ( $idx != "p" && ! $idx =~ ^[0-9]+$ ) ]]; then
    echo "Usage: gad <index> [p]"
    return 1
  fi

  if [[ $idx == "p" ]]; then
    git add -p
    return
  fi

  local file
  file=$(git status --short | awk 'NR=='"$idx"' {print substr($0,4)}')
  if [[ -z $file ]]; then
    echo "No file at index $idx"
    return 1
  fi

  if [[ $mode == "p" ]]; then
    git add -p -- "$file"
    echo "Added (patch): $file"
  else
    git add -- "$file"
    echo "Added: $file"
  fi
}
compdef '_arguments "1: :($(git status --short | awk "{print NR \":\" substr(\$0,4)}");p) 2: :(p)"' gad


# Add indexed git diff function: 'gdf <n>' diffs the nth file from 'git status --short'
# Also supports 'gdf staged' or 'gdf s' for staged diff
function gdf() {
  local arg=$1
  if [[ -z $arg ]]; then
    echo "Usage: gdf <index>|staged"
    return 1
  fi

  if [[ $arg == "staged" || $arg == "stage" || $arg == "stag" || $arg == "sta" || $arg == "st" || $arg == "s" ]]; then
    git diff --staged
    return
  fi

  if [[ ! $arg =~ ^[0-9]+$ ]]; then
    echo "Usage: gdf <index>|staged"
    return 1
  fi

  local file
  file=$(git status --short | awk 'NR=='"$arg"' {print substr($0,4)}')
  if [[ -z $file ]]; then
    echo "No file at index $arg"
    return 1
  fi
  git diff -- "$file"
}
compdef '_arguments "1: :($(git status --short | awk "{print NR \":\" substr(\$0,4)}");staged)"' gdf

# Add indexed git restore function: 'gre <n>' restores the nth file from 'git status --short'
function gre() {
  local idx=$1
  if [[ -z $idx || ! $idx =~ ^[0-9]+$ ]]; then
    echo "Usage: gre <index>"
    return 1
  fi
  local file
  file=$(git status --short | awk 'NR=='"$idx"' {print substr($0,4)}')
  if [[ -z $file ]]; then
    echo "No file at index $idx"
    return 1
  fi
  git restore -- "$file"
  echo "Restored: $file"
}
compdef '_arguments "1: :($(git status --short | awk "{print NR \":\" substr(\$0,4)}"))"' gre
#########################################


#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
