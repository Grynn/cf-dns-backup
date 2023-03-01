#!/usr/bin/env bash

# Backup Cloudflare DNS zone files  

set -e -u -o pipefail

usage() {
    echo "Usage: $(basename $0) [-hv] [-z <value>]"
    echo ""
    echo "-h = display this help and exit"
    echo "-v = verbose output"
    echo "-z = directory to store zone files (default ./zones)"
    exit 2
}

error_log() {
    echo "$@" >&2
}

# Parse options & arguments
VERBOSE=
TOKEN=()

cwd=$(pwd)   
zone_files_dir="$cwd/zones"
account_file_path="$cwd/accounts.txt"  

optspec="hvz:t:"
while getopts "$optspec" optchar; do
case "${optchar}" in
        z)
            zone_files_dir=${OPTARG}
            ;;
        t)
            TOKEN+=("${OPTARG}")
            ;;
        h)
            usage
            ;;
        v)
            echo "Parsing option: '-${optchar}'" >&2
            VERBOSE=1
            ;;
        *)
            if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
                error_log "Unrecognized option: '-${OPTARG}'"
                exit 2
            fi
            ;;
    esac
done

#verify account tokens file exists or -t <token> has been supplied on the cli
if (( ${#TOKEN[@]} == 0 )); then
    
    # probe for accounts file
    if [ ! -f "$account_file_path" ]; then
        account_file_path=${HOME}/.cf-dns-backup/accounts.txt
    fi

    if [ ! -f "$account_file_path" ]; then
        error_log "Please create a file with Cloudflare API tokens, one per line, at $account_file_path" 
        exit 1
    fi

    # Read accounts from file
    while IFS= read -r line; do
        TOKEN+=("$line")
    done < <(sed -e '/^#/d;s/[^\/]#.*$//' "$account_file_path") # Remove comments and blank lines

fi

# check if all required commands are present 
function check_command_present() {
    for ((i=1; i<=$#; i++)); do
        if ! command -v ${!i} &> /dev/null
        then
            error_log "${!i} could not be found. `brew install ${!i}`. For gsed, brew install coreutils"
            exit
        fi
    done
}

function backup() {
    export CF_API_TOKEN=$1
    local bar=""
    if [ ! -z $VERBOSE ]; then 
        bar="--bar" ; 
        echo "Backing up zones for account with token: $1"
        flarectl z l
    fi
    
    flarectl --json z l | jq -r '.[] | .Name' | parallel $bar "flarectl zone x --zone {} > \"${zone_files_dir}/{}.zone.txt\""
}

function clean() {
    find "${zone_files_dir}" -type f -exec bash -c "gsed -i -e '/IN[[:space:]]\+SOA[[:space:]]\+/d' -e '/;; Exported: /d' \"{}\"" \;
}

if [ $VERBOSE ]; then
    echo "zone_files_dir: \"$zone_files_dir\""
    echo "account_file_path: \"$account_file_path\""
    echo "tokens: ${TOKEN[*]}"
fi

check_command_present jq parallel flarectl gsed

# Create zone files directory if it doesn't exist
mkdir -p "${zone_files_dir}"

# For each token in $TOKEN[], backup the zones
for token in "${TOKEN[@]}"; do
    backup "$token"
done

clean

# Create git repo if it doesn't exist
[ -d "${zone_files_dir}/.git" ] || git init "${zone_files_dir}"

# If any files changed, commit and push
( 
    cd "$zone_files_dir"
    if [ -n "$(git status --porcelain)" ]; then
        echo "Changes detected"
        git add -A
        git commit -m "DNS changes, $(date +%F)"
        if [ -z "$(git remote -v)" ]; then
            echo "Warning: No remote configured for git repo. Please configure a remote and push manually. ${zone_files_dir}"
        else
            git push
        fi
    else
        echo "No changes detected"
    fi
)

exit 0