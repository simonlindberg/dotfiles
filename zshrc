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
zstyle ':vcs_info:*' formats '%b'

# Refresh the prompt
autoload -Uz add-zsh-hook
add-zsh-hook precmd set_prompt


# Add auto-refreshing prompt with autocomplete preservation
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

 #####     ###   #######          #     #         ###       #      #####   #######   #####
#           #       #            # #    #          #       # #    #        #        #
#           #       #           #   #   #          #      #   #   #        #        #
#  ####     #       #          #     #  #          #     #     #   #####   #######   #####
#     #     #       #          #######  #          #     #######        #  #              #
#     #     #       #          #     #  #          #     #     #        #  #              #
 #####     ###      #          #     #  #######   ###    #     #   #####   #######   #####

unalias gc
function gc() {
  local first_arg="${1:l}"
  if [[ "$first_arg" == (amend|amen|ame|am|a) ]]; then
    git commit --amend
  elif [[ $# -gt 0 ]]; then
    git commit -m "$*"
  else
    git commit
  fi
}
compdef '_arguments "1: :(amend amen ame am a as)" "*:commit message:_message"' gc

function gamend() {
  git commit --amend "$@"
}
compdef _git gamend

function gpush() {
  git push origin "$@"
}
compdef _git gpush

function gpushf() {
  git push --force origin "$@"
}
compdef _git gpushf

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

# Custom completion: only offer 'staged' if there are staged files
function _gdf_completion {
  local -a files
  local -a opts
  files=("${(@f)$(git status --short | awk '{print NR ":" substr($0,4)}')}")
  if git diff --cached --quiet; then
    # No staged changes
    opts=("${files[@]}")
  else
    opts=("${files[@]}" "staged")
  fi
  _arguments "1: :(${(j: :)opts})"
}
compdef _gdf_completion gdf

function gre() {
  local idx=$1
  local target=$2
  local file
  local staged=0
  local unstaged=0

  if [[ -z $idx ]]; then
    echo "Usage: gre <index[:filename]> [staged|worktree|all]"
    return 1
  fi

  # Support index:filename or just index, but always use index to get filename
  if [[ $idx =~ ^([0-9]+): ]]; then
    idx="${match[1]}"
  elif [[ $idx =~ ^[0-9]+$ ]]; then
    # idx is already set
    :
  else
    echo "Usage: gre <index[:filename]> [staged|worktree|all]"
    return 1
  fi

  file=$(git status --short | awk 'NR=='"$idx"' {print substr($0,4)}')

  if [[ -z $file ]]; then
    echo "No file at index $idx"
    return 1
  fi

  # Check status: staged if first column is not ' ' or '?', unstaged if second column is not ' '
  local status_line
  status_line=$(git status --short | awk 'NR=='"$idx"'')
  [[ ${status_line[1,1]} != " " && ${status_line[1,1]} != "?" ]] && staged=1
  [[ ${status_line[2,2]} != " " ]] && unstaged=1

  # Accept all variants for staged, worktree, all
  local target_lc="${target:l}"
  if [[ $target_lc == (staged|stage|stag|sta|st|s) ]]; then
    target_lc="staged"
  elif [[ $target_lc == (worktree|work|wtree|wt|w) ]]; then
    target_lc="worktree"
  elif [[ $target_lc == (all|a) ]]; then
    target_lc="all"
  fi

  if (( staged && unstaged )); then
    if [[ $target_lc == "staged" ]]; then
      git restore --staged -- "$file"
      echo "Restored staged: $file"
    elif [[ $target_lc == "worktree" ]]; then
      git restore --worktree -- "$file"
      echo "Restored worktree: $file"
    elif [[ $target_lc == "all" ]]; then
      git restore --staged --worktree -- "$file"
      echo "Restored staged and worktree: $file"
    else
      echo "File has changes in both staged and worktree. Specify [staged|worktree|all]."
      return 1
    fi
  elif (( staged )); then
    git restore --staged -- "$file"
    echo "Restored staged: $file"
  elif (( unstaged )); then
    git restore --worktree -- "$file"
    echo "Restored worktree: $file"
  else
    echo "No changes to restore for: $file"
    return 1
  fi
}
# Completion: offer staged/worktree/all (with aliases) if both, else nothing
function _gre_completion {
  local -a files
  files=("${(@f)$(git status --short | awk '{print NR ":" substr($0,4)}')}")
  local -a targets
  targets=(staged worktree all)
  local expl
  _arguments -C \
    "1:modified file:(${(j: :)files})" \
    "2:target:(${(j: :)targets})"
}
compdef _gre_completion gre

function gls() {
  # Reserve 2 lines for prompt, etc.
  local log_lines=$(( $(tput lines) - 2 ))
  ((log_lines < 1)) && log_lines=1

  git log --oneline --graph --decorate --color=always \
    --pretty=format:'%C(yellow)%h%C(reset) %C(blue)%ad%C(reset) %C(auto)%d%C(reset) %C(white)%s%C(reset) %C(green)[%an]%C(reset)' \
    --date=short -$log_lines | head -n $log_lines
}
compdef _git gls

function glsa() {
  # Reserve 2 lines for prompt, etc.
  local log_lines=$(( $(tput lines) - 2 ))
  ((log_lines < 1)) && log_lines=1

  git log --oneline --all --graph --decorate --color=always \
    --pretty=format:'%C(yellow)%h%C(reset) %C(blue)%ad%C(reset) %C(auto)%d%C(reset) %C(white)%s%C(reset) %C(green)[%an]%C(reset)' \
    --date=short -$log_lines | head -n $log_lines
}
compdef _git glsa


#   #  ###   ####   ####
## ##   #   #      #
# # #   #    ####  #
#   #   #        # #
#   #  ###   ####   ####

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
