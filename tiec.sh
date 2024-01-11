#!/bin/bash 

DEFAULT='setup.sh'
STORAGE='/tmp/tie-command-storagefile'
SHELL="/bin/bash"
FILENAME=$(pwd)/$DEFAULT
PROCESS_ID=$PPID
PREFACE=""
COMMENT='#'
VERSION="v0.1"
FILE_PROVIDED=false
DONT_WRITE=false
dir="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$dir"
make -s

print_help() {
    echo "tie-command : save your last command into an output file"
    echo "tiec options:"
    echo -e "\t-c | --cat\t: print the output file results and exit"
    echo -e "\t-d \t\t: don't write to file. useful for setup commands"
    echo -e "\t-f | --file\t: specify the output path and filename"
    echo -e " \t      'tiec [-f | --file]=\$(pwd)/filename.sh'\n"
    echo -e "\t-h | --help\t: what you did just now"
    echo -e "\t-i | --process-id\t: take last command from a different shell, if you have the pid"
    echo -e " \t      'tiec [-i | --process-id]=1234'\n"
    echo -e "\t-p | --preface\t: preface your command with an explanation"
    echo -e " \t      'tiec [-p | --preface]=\"special command that does x\"'\n"
    echo -e "\t-s | --shell\t: change the boilerplate ( default #!/bin/bash )"
    echo -e "\twon't do anything if the file is already started"
    echo -e " \t      'tiec [-s | --shell]=#!/bin/zsh'\n"
    echo -e "\t-v | --version\t: print version information and exit"
    echo ""
    exit 0
}
extract_argument() {
    echo "${2:-${1#*=}}"
}
handle_flags() {
    while [ $# -gt 0 ]; do
        case $1 in 
            -c | --cat)
                CAT=true
                ;;
            -d)
                DONT_WRITE=true
                ;;
            -f* | --file*)
                FILENAME=$(extract_argument $@)
                FILE_PROVIDED=true
                ;;
            -h | --help)
                print_help
                ;;
            -i* | --process-id*)
                PROCESS_ID=$(extract_argument $@)
                ;;
            # TODO record mode - save history id# and retrieve list of commands when recording stops
            -p* | --preface*)
                PREFACE="${1#*=}"
                ;;
            -s* | --shell*)
                SHELL=$(extract_argument $@)
                ;;
            -v | --version)
                echo "tie-command version : $VERSION"
                exit 0
                ;;
            *)
                echo "Invalid option: $1" >&2
                exit 1
                ;;
        esac
        shift
    done
}
store_variable() {
    # TODO will delete other stored variables
    echo ''$1'="'"$2"'"' > $STORAGE
}

handle_flags "$@"

if ! test -f "$STORAGE" || "$FILE_PROVIDED" = true ; then 
    echo "storing $(basename $FILENAME) location in persistent file"
    store_variable "FILENAME" "$FILENAME"
else
    . $STORAGE
fi
if [ "$CAT" = true ]; then
    cat "$FILENAME"
    exit 0
fi
if [ ! -s "$FILENAME" ]; then
    echo '#!'"$SHELL" >> $FILENAME
fi

# use gdb to get last command from parent shell
# https://unix.stackexchange.com/questions/341534/is-it-possible-to-view-another-shells-history
LASTCMD=$(sudo gdb -p "$PROCESS_ID" -batch -x gdb_lasthistory | tail -2 | head -1)

if [ "$DONT_WRITE" = false ]; then
    if [ ! -z "$PREFACE" ]; then
        echo "$COMMENT" "$PREFACE" >> $FILENAME
    fi
    echo -e "$LASTCMD" >> $FILENAME
fi
