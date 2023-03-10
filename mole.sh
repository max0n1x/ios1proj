#!/bin/bash

## Default values
directory=$(pwd)
filter=""
mode="last"
group=""
start_date=""
end_date=""
filename=""
EDITOR="${EDITOR:-${VISUAL:-nano}}"
mole_rc="$directory/.config/"

if [[ ! -d "$mole_rc" ]]; then
  echo "mole_rc doesnt exist"
  exit
fi

if [[ -f "$mole_rc" ]]; then
  source "$mole_rc"
else
  mkdir -p $mole_rc
  touch "$mole_rc/mole_rc"
fi

print_help() {
  echo "Usage:
mole -h
mole [-g GROUP] FILE
mole [-m] [FILTERS] [DIRECTORY]
mole list [FILTERS] [DIRECTORY]"
}

open_file(){
if [[ -n "$filename" ]]; then
  if [[ -f "$filename" ]]; then
    $EDITOR "$filename"
    awk '1;/FILES/{ print "'$filename'"}' "$mole_rc/mole_rc" > "$mole_rc/mole_rc".tmp && mv "$mole_rc/mole_rc".tmp "$mole_rc/mole_rc"
    exit
  else
    echo "File doesnt exist"
    exit
  fi
fi
}


groups(){
  if grep -Fxq "#$group" "$mole_rc/mole_rc"; then
    awk_array=($(awk '{print $0}' "$mole_rc/mole_rc"))

    if [ -z "$awk_array" ]; then
        echo "No lines in $mole_rc/mole_rc"
        exit 1
    fi

    for ((i=0; i<${#awk_array[@]}; i++)); do
      if [ "${awk_array[$i]}" != "FILES" ]; then
        if [[ "${awk_array[$i]}" == "#$group" ]]; then
          for ((j="$i"+1; j<${#awk_array[@]}; j++)); do
            if [[ "${awk_array[$j]}" == *"#"* ]]; then
                break
            elif [ "$filename" == "${awk_array[$j]}" ]; then
                find=1
            fi
          done
        fi
      fi
    done

    if [[ "$find" -eq 1 ]]; then
      echo "File already exists in group '$group'"
    else
      awk '1;/'"#$group"'/{ print "'$filename'"}' "$mole_rc/mole_rc" > "$mole_rc/mole_rc".tmp && mv "$mole_rc/mole_rc".tmp "$mole_rc/mole_rc"
    fi

  else
    awk '1;/GROUPS/{ print "#'$group'"}' "$mole_rc/mole_rc" > "$mole_rc/mole_rc".tmp && mv "$mole_rc/mole_rc".tmp "$mole_rc/mole_rc"
    awk '1;/'"#$group"'/{ print "'$filename'"}' "$mole_rc/mole_rc" > "$mole_rc/mole_rc".tmp && mv "$mole_rc/mole_rc".tmp "$mole_rc/mole_rc"
  fi
}

list_files() {
  awk_array=($(awk '{print $0}' "$mole_rc/mole_rc"))

  if [ -z "$awk_array" ]; then
      echo "No lines in $mole_rc"
      exit 1
  fi

  for ((i=0; i<${#awk_array[@]}; i++)); do
    if [ "${awk_array[$i]}" == "FILES" ]; then
      for ((j=i+1; j<${#awk_array[@]}; j++)); do
        for entry in "$directory"/*; do
          if [ "${awk_array[$j]}" == "$entry" ]; then
            echo "File being edited by mole: $entry"
          fi
        done
      done
    fi
  done
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h)
      print_help
      exit
      ;;
    -g)
      group="$2"
      groups
      shift
      ;;
    -m)
      mode="most"
      ;;
    -a)
      start_date="$2"
      shift
      ;;
    -b)
      end_date="$3"
      shift
      ;;
    list)
      list_files
      exit
      ;;
    *)
      if [[ -f "$1" ]]; then
        filename=$(readlink -f "$1")
      elif [[ -d "$1" ]]; then
        directory="$1"
      else
        directory=$(pwd)
      fi
      open_file
      ;;
    esac
    shift
  done
}

parse_args "$@"

