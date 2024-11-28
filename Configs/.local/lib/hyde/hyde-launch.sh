#!/bin/bash

# Declare an associative array for special cases
declare -A dict

# Add entries to the associative array
dict["file-manager"]="inode/directory"
dict["text-editor"]="text/plain"
dict["web-browser"]="text/html"
dict["image-viewer"]="image/webp"
dict["video-player"]="video/mp4"
dict["pdf-viewer"]="application/pdf"
dict["archive-manager"]="application/x-compressed-tar"
dict["word-processor"]="application/msword"
dict["font-manager"]="font/ttf"
dict["code-editor"]="text/x-csrc"
dict["log-viewer"]="text/x-log"

show_usage() {
    cat <<USAGE
Usage: $0 [options] <mime-type or dict>
Options:
  --help, -h       Show this help message
  --std            Only print the command without executing it
  --mime <keyword>    Search for a specific MIME type in the mimeapps.list or system MIME types
  --fall <command>    Fallback command to execute if no matching MIME type or application is found

* Note: For setting the default application, use xdg-mime command

Examples:
  $(basename "${0}") text/plain
  $(basename "${0}") file-manager
dict:
USAGE
    for k in "${!dict[@]}"; do printf '  %s: %s\n' "$k" "${dict[$k]}"; done
}

find_mime_type() {
    local input=$1
    local mime_type

    # Check if input is a special case
    [[ -v dict[$input] ]] && echo "${dict[$input]}" && return

    # Use awk for faster processing
    mime_type=$(awk -v input="$input" '
        BEGIN { IGNORECASE=1 }
        $0 ~ "^" input "=" { print $0; exit }
    ' "${HOME}/.config/mimeapps.list" 2>/dev/null)

    if [ -z "$mime_type" ]; then
        mime_type=$(awk -v input="$input" '
            BEGIN { IGNORECASE=1 }
            $0 ~ "^" input "$" || $0 ~ "/" input "$" || $0 ~ "/" input "/" || $0 ~ "^" input "/" { print $0; exit }
        ' /usr/share/mime/types)
    fi

    echo "${mime_type%%=*}"
}

# find_exec_line() {
#     local default_app=$1
#     local dirs=(
#         "$HOME/.local/share/flatpak/exports/share/applications/"
#         "$HOME/.local/share/applications"
#         "/var/lib/flatpak/exports/share/applications/"
#         "/usr/local/share/applications"
#         "/usr/share/applications")

#     for dir in "${dirs[@]}"; do
#         if [ -f "$dir/$default_app" ]; then
#             awk '/^Exec=/ {print; exit}' "$dir/$default_app"
#             return 0
#         fi
#     done
#     return 1
# }

main() {
    # Check if no arguments are provided
    [ $# -eq 0 ] && {
        show_usage
        exit 1
    }
    std_only=false
    # Parse options
    while [[ "$1" == --* || "$1" == -* ]]; do
        case "$1" in
        --help | -h)
            show_usage
            exit 0
            ;;
        --std)
            std_only=true
            ;;
        --mime)
            (cat "${HOME}/.config/mimeapps.list" || cat /usr/share/mime/types) 2>/dev/null | grep --color=auto "${2}"
            exit 0
            ;;
        --fall)
            fallbackCmd="${2}"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
        esac
        shift
    done

    local input=$1
    local mime_type
    mime_type=$(find_mime_type "$input")

    [ -z "$mime_type" ] && {
        echo -e "Error: No matching MIME type found for $input\n"
        gtk-launch "${fallbackCmd}" || exit 1
    }

    local default_app
    default_app=$(xdg-mime query default "$mime_type")
    [ -z "$default_app" ] && {
        echo -e "Error: No default application found for $mime_type\n"
        gtk-launch "${fallbackCmd}" || exit 1
    }

    # local exec_line
    # exec_line=$(find_exec_line "${default_app}")
    # [ -z "$exec_line" ] && {
    #     echo -e "Error: Could not find Exec line in (${default_app})\n"
    #     gtk-launch "${fallbackCmd}" || exit 1
    # }

    # local command=${exec_line#Exec=}
    # command=${command%% %*}

    # if [[ "${command}" == *"flatpak run"* ]] || command -v "$command" &>/dev/null; then
    # echo "${command}"
    $std_only || gtk-launch "${default_app}" || gtk-launch "${fallbackCmd}"
    # echo "[error] Could not find the default application ($command)" && exit 1
    # fi
}

main "$@"
