#!/bin/bash 

dir="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$dir"
make -s
source config

print_help() {
    format="    %-20s %s\n"
    printf "tie-command - save your last command into an output file\n\n"  
    printf "${format}"  "tiec options:"                                     \ 
    "-c, --cat"       "print the output file results and exit"              \
    "-d"             "don't write to file. useful for setup commands"       \
    "-f, --file"       "specify the output path and filename"               \
    "" "'tiec [-f | --file]=\$(pwd)/filename.sh'"                           \
    "-h, --help"       "what you did just now"                              \
    "-i, --process-id" "take last command from a different shell using pid" \
    "" "'tiec [-i | --process-id]=1234'"                                    \
    "-p, --preface"    "preface your command with an explanation"           \
    "" "'tiec [-p | --preface]=\"special command that does x\"'"            \
    "-s, --shell"      "change the boilerplate ( default #!/bin/bash )"     \
    "" "won't do anything if the file is already started"                   \
    "" "'tiec [-s | --shell]=#!/bin/zsh'"                                   \
    "-v, --version"    "print version information and exit" "" 
    
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
