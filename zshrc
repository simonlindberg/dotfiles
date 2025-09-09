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

# 3. Add auto-refreshing prompt with autocomplete preservation
if [[ -o interactive ]]; then
  TMOUT=1

  # Store and restore completion menu state
  local completion_menu_buffer=""
  local completion_menu_choices=""

  function store_menu_state() {
    if [[ "$COMPSTATE[insert]" == "menu" ]]; then
      completion_menu_buffer="$BUFFER"
      completion_menu_choices="${(pj:\n:)${(@f)$(zle list-choices 2>/dev/null)}}"
    else
      completion_menu_buffer=""
      completion_menu_choices=""
    fi
  }

  function restore_menu_state() {
    if [[ -n "$completion_menu_buffer" && -n "$completion_menu_choices" ]]; then
      BUFFER="$completion_menu_buffer"
      zle list-choices
    fi
  }

  TRAPALRM() {
    store_menu_state
    zle reset-prompt
    restore_menu_state
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
  local file

  if [[ -z $idx ]]; then
    echo "Usage: gad <index[:filename]> [p]"
    return 1
  fi

  # Support index:filename or just index, but always use index to get filename
  if [[ $idx =~ ^([0-9]+): ]]; then
    idx="${match[1]}"
  elif [[ $idx == "p" ]]; then
    git add -p
    return
  elif [[ $idx =~ ^[0-9]+$ ]]; then
    # idx is already set
    :
  else
    echo "Usage: gad <index[:filename]> [p]"
    return 1
  fi

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

function gdf() {
  local arg=$1
  local idx
  local file

  if [[ -z $arg ]]; then
    echo "Usage: gdf <index[:filename]>|staged"
    return 1
  fi

  if [[ $arg == "staged" || $arg == "stage" || $arg == "stag" || $arg == "sta" || $arg == "st" || $arg == "s" ]]; then
    git diff --staged
    return
  fi

  # Support index:filename or just index, but always use index to get filename
  if [[ $arg =~ ^([0-9]+): ]]; then
    idx="${match[1]}"
  elif [[ $arg =~ ^[0-9]+$ ]]; then
    idx="$arg"
  else
    echo "Usage: gdf <index[:filename]>|staged"
    return 1
  fi

  file=$(git status --short | awk 'NR=='"$idx"' {print substr($0,4)}')

  if [[ -z $file ]]; then
    echo "No file at index $idx"
    return 1
  fi
  git diff -- "$file"
}
compdef '_arguments "1: :($(git status --short | awk "{print NR \":\" substr(\$0,4)}");staged)"' gdf

function gre() {
  local idx=$1
  local file

  if [[ -z $idx ]]; then
    echo "Usage: gre <index[:filename]>"
    return 1
  fi

  # Support index:filename or just index, but always use index to get filename
  if [[ $idx =~ ^([0-9]+): ]]; then
    idx="${match[1]}"
  elif [[ $idx =~ ^[0-9]+$ ]]; then
    # idx is already set
    :
  else
    echo "Usage: gre <index[:filename]>"
    return 1
  fi

  file=$(git status --short | awk 'NR=='"$idx"' {print substr($0,4)}')

  if [[ -z $file ]]; then
    echo "No file at index $idx"
    return 1
  fi
  git restore --staged --worktree -- "$file"
  echo "Restored: $file"
}
compdef '_arguments "1: :($(git status --short | awk "{print NR \":\" substr(\$0,4)}"))"' gre


#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
