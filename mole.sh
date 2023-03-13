#!/bin/sh

## Default values
directory=$(pwd)
mode="last"
export EDITOR="${EDITOR:-${VISUAL:-nano}}"
export mole_rc="$directory/.config"
export POSIXLY_CORRECT=YES

if [ ! -d "$mole_rc" ]; then

  echo "mole_rc doesnt exist"
  exit

fi

if [ -f "$mole_rc" ]; then

    . "$mole_rc"

else

  mkdir -p "$mole_rc"
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

if [ -n "$filename" ]; then

  if [ -f "$filename" ]; then

    $EDITOR "$filename"
    sed -i "/FILES/a $filename | $(date +'%Y-%m-%d')" "$mole_rc/mole_rc"
    exit

  else

    echo "File doesn't exist"
    exit

  fi

fi

}

groups(){

  if [ -z "$group_arg" ]; then
    echo "No group specified"
    exit
  fi

  if [ -z "$filename" ]; then
    echo "No file specified"
    exit
  fi

  if grep -Fxq "#$group_arg" "$mole_rc/mole_rc"; then

    groups=$(awk '/GROUPS/{flag=1;next}/FILES/{flag=0}flag' "$mole_rc/mole_rc")

    for group_i in $groups; do

      if [ "$group_i" = "#$group_arg" ]; then

        filenames=$(awk '/#'"$group_arg"'/{flag=1;next}/(FILES|#)/{flag=0}flag' "$mole_rc/mole_rc")

        for filename_j in $filenames; do

          if [ "$filename_j" = "$filename" ]; then

            find="1"
            break

          fi

        done

      fi

    done

    if [ "$find" = "1" ]; then

      echo "File already exists in group '$group_arg'"

    else

      sed -i "/#$group_arg/a $filename" "$mole_rc/mole_rc"

    fi

  else

    sed -i "/GROUPS/a #$group_arg" "$mole_rc/mole_rc"
    sed -i "/#$group_arg/a $filename" "$mole_rc/mole_rc"

  fi

  open_file

}


list_group(){

    if [ -z "$start_date" ] && [ -n "$end_date" ]; then

        files=$(awk '/FILES/{flag=1;next}/END/{flag=0}flag' "$mole_rc/mole_rc" |
          awk -F" | " '{print $1, $3}' |
          awk -v start_date="$start_date" -v end_date="$end_date" '$2 <= end_date {print $1}' |
          tr ' ' '\n' | sort | uniq)

    elif [ -n "$start_date" ] && [ -z "$end_date" ]; then

        files=$(awk '/FILES/{flag=1;next}/END/{flag=0}flag' "$mole_rc/mole_rc" |
          awk -F" | " '{print $1, $3}' |
          awk -v start_date="$start_date" -v end_date="$end_date" '$2 >= start_date {print $1}' |
          tr ' ' '\n' | sort | uniq)

    elif [ -z "$start_date" ] && [ -z "$end_date" ]; then

        files=$(awk '/FILES/{flag=1;next}/END/{flag=0}flag' "$mole_rc/mole_rc" |
          awk -F" | " '{print $1}' |
          tr ' ' '\n' | sort | uniq)

    elif [ -n "$start_date" ] && [ -n "$end_date" ]; then

        files=$(awk '/FILES/{flag=1;next}/END/{flag=0}flag' "$mole_rc/mole_rc" |
          awk -F" | " '{print $1, $3}' |
          awk -v start_date="$start_date" -v end_date="$end_date" '$2 >= start_date && $2 <= end_date {print $1}' |
          tr ' ' '\n' | sort | uniq)

    fi

    if [ -n "$group_arg" ]; then

      target_groups=$(echo "$group_arg" | awk -F"," '{for(i=1;i<=NF;i++) print $i}')

    fi

    for target in "$directory"/*; do

      for file in $files; do

        if [ "$file" = "$target" ]; then

          for target_group in $target_groups; do

            if grep -Fxq "#$target_group" "$mole_rc/mole_rc"; then

              groups=$(awk '/GROUPS/{flag=1;next}/FILES/{flag=0}flag' "$mole_rc/mole_rc")

              for group_i in $groups; do

                if [ "$group_i" = "#$target_group" ]; then

                  filenames=$(awk '/#'"$target_group"'/{flag=1;next}/(FILES|#)/{flag=0}flag' "$mole_rc/mole_rc")

                  for filename_j in $filenames; do

                    if [ "$filename_j" = "$target" ]; then

                      find="1"
                      break

                    fi

                  done

                    if [ "$find" != "1" ]; then

                    continue 3

                    fi

                fi

              done

            fi

          done

          printf '%-15s :' "$(basename "$target")"

          groups=$(awk '/GROUPS/{flag=1;next}/FILES/{flag=0}flag' "$mole_rc/mole_rc")

          for group_i in $groups; do

            if test "${group_i#*"#"}" != "$group_i"; then

              filenames=$(awk '/'"$group_i"'/{flag=1;next}/(FILES|#)/{flag=0}flag' "$mole_rc/mole_rc")

              for filename in $filenames; do

                if [ "$filename" = "$target" ]; then

                  printf '%s' " $group_i |" | sed 's/#//g'

                  found=1

                fi

              done

            fi

          done

          if [ -z "$found" ]; then

              printf ' %s' "-"

          fi

          printf '\n'
          unset found

        fi

      done

    done

}

parse_args() {

  while [ $# -gt 0 ]; do

    case "$1" in

      -h)

        print_help
        exit
        ;;

      -g)

        group_arg="$2"
        shift
        ;;

      -m)

        mode="most"
        shift
        ;;

      -a)

        start_date="$2"
        shift
        ;;

      -b)

          end_date="$2"
          shift
          ;;


      list)
        while [ $# -gt 0 ]; do

          case "$1" in

            -g)

              group_arg="$2"
              shift
              ;;

            -a)

              start_date="$2"
              shift
              ;;

            -b)

              end_date="$2"
              shift
              ;;

            *)

              if [ -d "$1" ]; then
                directory="$1"
              fi

              ;;
          esac
          shift
        done

        list_group

        exit
        ;;
      *)

        if [ -f "$1" ] && [ -n "$group" ]; then

          filename=$(readlink -f "$1")
          groups

        elif [ -d "$1" ] && [ -n "$group" ]; then

          directory="$1"
          mode_open

        elif [ -f "$1" ] && [ -z "$group" ]; then

          filename=$(readlink -f "$1")
          open_file

        elif [ -d "$1" ] && [ -z "$group" ]; then

          directory="$1"
          mode_open

        else

          echo "Invalid argument: $1"

        fi
        ;;

    esac

    shift

  done

}

parse_args "$@"

