# Utility

# Easiest if it's global.
segments=()

# Pushes a segment on to the list
# 
#   text
#   background color
#   foreground color
# 
push_segment() {
  segments+=("${1}" "${2:=default}" "${3:=black}")
}

# Prints all segments currently pushed & resets the list.
# 
#   side: "left" or "right"
# 
print_segments() {
  local side="${1}"

  [[ "${side}" == "right" ]] && echo -n " "

  for (( i = 0; i < ${#segments[@]} ; i += 3 )) ; do
    local text="${segments[$i + 1]}"
    local background="${segments[$i + 2]}"
    local foreground="${segments[$i + 3]}"
    
    if [[ "${side}" == "right" ]]; then
      (( i > 0 )) && local previous_background="${segments[$i - 1]}"
      echo -n "%K{${previous_background:=default}}%F{$background}%f%k"
    fi

    echo -n "%K{$background}%F{$foreground} ${text} %f%k"

    if [[ "${side}" == "left" ]]; then
      local next_background="${segments[$i + 5]}"
      echo -n "%K{${next_background:=default}}%F{$background}%f%k"
    fi
  done

  [[ "${side}" == "left" ]] && echo -n " "

  segments=()
}

# Specific Segments

segment_host() {
  local user=`whoami`
  [[ "${user}" == "${DEFAULT_USER}" && -n "${SSH_CONNECTION}" ]]; return

  push_segment "${user}@%m" magenta
}

segment_path() {
  push_segment "%~" blue
}

segment_vcs() {
  [[ "${vcs_info_msg_0_}" == "" ]] && return

  local info=("${(@s/❖/)vcs_info_msg_0_}")
  local ref="${info[1]}"
  local action="${info[2]}"

  if [[ "${ref}" =~ \ [0-9a-f]{40} ]]; then
    ref="${ref[0,9]}"
  fi
  ref="${ref:s/.../}"

  if [[ "$(git status --porcelain)" == "" ]]; then
    push_segment "${ref}" green
  else
    push_segment "${ref}" yellow
  fi

  [[ "${action}" != "" ]] && push_segment "${action}" cyan
}

segment_status() {
  if [[ "$RETVAL" -ne 0 ]]; then
    push_segment "${RETVAL} ↵" red white
  else
    push_segment "✓" black green
  fi
}

segment_time() {
  push_segment "%D{%H:%M:%S.%.}" white black
}

# Prompts

prompt_novash_left() {
  segment_host
  segment_path
  segment_vcs
  
  if type iterm2_prompt_mark >/dev/null; then
    echo -n "%{$(iterm2_prompt_mark)%}"
  fi

  print_segments left
}

prompt_novash_right() {
  segment_status
  segment_time
  print_segments right
}

prompt_novash_precmd() {
  RETVAL=$?

  vcs_info
  PROMPT="$(prompt_novash_left)"
  RPROMPT="$(prompt_novash_right)"
}

prompt_novash_setup() {
  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info

  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:*' formats ' %b'
  zstyle ':vcs_info:*' actionformats ' %b❖%a'
  
  add-zsh-hook precmd prompt_novash_precmd  
}

prompt_novash_setup "$@"
