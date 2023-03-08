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

# open file in mole_rc variable and read config file(Groups, format GROUP {name}
#file1
#file2
#file3
#GROUP {name})
groups=$(grep -E "^GROUPS" "$mole_rc/mole_rc" | awk '{print $2}')

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
  else
    $EDITOR "${filename// /_}"
  fi
  exit
fi
}

# List files edited by mole in the directory
list_files() {
  echo "Files edited by mole:"
  files=$(grep -r -l -E "^# mole " $(pwd) | sort -r)
  echo "$files"
}

# parse args using getops
parse_args() {
  while getopts ":hmg:d:f:lb:a:" opt; do
    case $opt in
      h)
        print_help
        exit
        ;;
      g)
        group="$OPTARG"
        ;;
      m)
        mode="most"
        ;;
      d)
        if [[ -n "$start_date" ]]; then
          end_date="$OPTARG"
        else
          start_date="$OPTARG"
        fi
        ;;
      f)
        filter="$OPTARG"
        ;;
      l)
        list_files
        exit
        ;;
      b)
        start_date="$OPTARG"
        ;;
      a)
        end_date="$OPTARG"
        ;;
      \?)
        echo "Invalid option: -$OPTARG" >&2
        print_help
        exit 1
        ;;
      :)
        echo "Option -$OPTARG requires an argument." >&2
        print_help
        exit 1
        ;;
    esac
  done
  shift $((OPTIND - 1))
  filename="$1"
  open_file
}

parse_args "$@"


# Get list of files edited by mole in the directory
echo "$files"

# Filter by group if specified and group exists else create new group and add file to it
if [[ -n "$group" ]]; then
  if [[ -n "$groups" ]]; then
    if [[ -n "$(grep -E "^GROUPS" "$mole_rc/mole_rc" | grep -E "$group")" ]]; then
      files=$(echo "$files" | xargs grep -l -E "^# mole -g {1}$group( |$)")
    else
      echo "GROUPS $group" >>"$mole_rc/mole_rc"
      echo "$filename" >>"$mole_rc/mole_rc"
    fi
  else
    echo "GROUPS $group" >>"$mole_rc/mole_rc"
    echo "$filename" >>"$mole_rc/mole_rc"
  fi
fi

# Filter by file name if specified
if [[ -n "$filter" ]]; then
  files=$(echo "$files" | grep -i -E "$filter")
fi

# Filter by date range if specified
if [[ -n "$start_date" && -n "$end_date" ]]; then
  files=$(echo "$files" | xargs grep -l -E "^# mole -d {2}$start_date( |$)" | xargs grep -l -E "^# mole -d {1}$end_date( |$)")
elif [[ -n "$start_date" ]]; then
  files=$(echo "$files" | xargs grep -l -E "^# mole -d {2}$start_date( |$)")
elif [[ -n "$end_date" ]]; then
  files=$(echo "$files" | xargs grep -l -E "^# mole -d {1}$end_date( |$)")
fi

# Choose file to open based on mode
if [[ "$mode" == "" ]]; then
  file=$(echo "$files" | head -n 1)
elif [[ "$mode" == "most" ]]; then
  file=$(echo "$files" | awk '{ print $1 }' | uniq -c | sort -rn | head -n 1 | awk '{ print $2 }')
else
  file=$(echo "$files" | head -n 1)
fi

# Open the chosen file
if [[ -n "$file" ]]; then
  echo "Opening file: $file"
  vim "$file"
fi

# If no directories specified, use all mole-tracked directories
if [[ ${#directories[@]} -eq 0 ]]; then
  directories=($(grep -r -l -E "^# mole " $(pwd) | xargs -I {} dirname {} | sort -u))
fi

# Get list of files edited by mole in the directories
files=$(grep -r -l -E "^# mole " "${directories[@]}" | sort -r)

# Filter by date range if specified
if [[ -n "$start_date" && -n "$end_date" ]]; then
  files=$(echo "$files" | xargs grep -l -E "^# mole -d {2}$start_date( |$)" | xargs grep -l -E "^# mole -d {1}$end_date( |$)")
elif [[ -n "$start_date" ]]; then
  files=$(echo "$files" | xargs grep -l -E "^# mole -d {2}$start_date( |$)")
elif [[ -n "$end_date" ]]; then
  files=$(echo "$files" | xargs grep -l -E "^# mole -d {1}$end_date( |$)")
fi

## Create compressed log file
#log_file="$(date +%Y-%m-%d-%H-%M-%S)-mole-secret-log.tar.gz"
#tar -czf "$log_file" -T <(echo "$files")

## Print success message
#echo "Secret log file created: $log_file"
