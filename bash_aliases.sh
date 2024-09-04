#************************** general aliases ***************************

alias sdn='sudo shutdown now'
alias c='clear'
alias explorer='xdg-open'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias h='history'

# Prints the given line number from stdin
function line() {
    [ -z "$1" ] && echo "Usage: line <line_number>" && return 1

    head -n "$1" | tail -n +"$1"
}

# Finds a command with the given contents in the history
function hg() {
    history | tail -n +2 | grep "$*" | grep -v hgr | grep -v hg
}

# Finds process IDs by name. Like pgrep but with more info
function process() {
    ps -ef | awk -v search="$1" '
        /^UID/ { print $0 }
        {
            if ($8 ~ search) print $0
        }
    '
}

# Creates a new directory and cds into it
function mcd() {
	mkdir $1
	cd $1
}

# Runs the last command in the history with `sudo`
function ensudo() {
    command=$(history | tail -n 2 | head -n 1 | awk '{$1=""}1')
    history -s "sudo$command"
    echo "sudo$command"
    eval sudo$command
}

# Makes a beep sound
function beep() {
    echo -en '\007'
}

# Makes multiple beep sounds with a different pattern depending on the first parameter
function bell() {
    for i in {1..3}; do
        beep
        if [ -n "$1" ] && [ "$1" -ne 0 ]; then
            sleep 0.1
            beep
        fi
        sleep 0.2
    done
}

# Runs a command and beeps when it is done
function bgrun() {
    (eval $*; bell $?) &
}

# Watches an existing process by name or PID and makes a sound when it finishes
function bgattach() {
    [ "$#" -eq 0 ] && echo "No PID or name given" && return 1
    pid="$*"
    ps -p $pid &> /dev/null
    if [ "$?" -gt 0 ]; then
        pid_names=$(ps -e -o pid,args --no-headers | grep "$*" | head -n -1 | awk '
            {
                PIDS[NR]=$1;
                $1="";
                NAMES[NR]=$0
            }
            END{
                ORS=" ";
                for (i = 1; i <= NR; i++) print PIDS[i];
                ORS="\n";
                print "";
                for (i = 1; i <= NR; i++)  print NAMES[i]
            }
        ')
        pids=$(echo "$pid_names" | head -n 1) # All the pids on the same line separated by spaces
        names=$(echo "$pid_names" | tail -n +2 | sed 's/ //') # Each command and its args on a different line
        pid="$pids"
        if [ "$(echo $pid | wc -w)" -gt 1 ]; then
            # Outputs the parameters to the user as options, and returns the index of the chosen one
            function select_option() {
                echo "Several options available. Please choose one:" 1>&2
                printf '%s\n' "$*" | awk '{print "["FNR"]", $1}' 1>&2
                read result
                ! [[ "$result" =~ ^[0-9]+$ ]] || [ "$result" -lt 1 -o "$result" -gt $argcount ] && echo "Invalid value $result" 1>&2 && return 1
                args=($*)
                echo "${args[$((result - 1))]}"
            }

            pid=$(select_option "$names") || return 1
        fi
    fi

    [ -z "$pid" ] && echo "Process \"$*\" not found" && return 1

    function poll() {
        while true; do
            ps -p $pid &> /dev/null || break
            sleep 5
        done
    }

    bgrun poll
}

# **************************** git aliases *****************************

alias gs='git status'
alias gt='git tree'
alias ga='git add'
alias gc='git commit -m'
alias gca='git commit --amend --no-edit'
alias gsum='git summary'

function gp() {
    branch=$(git branch --show-current)

    # Cannot use -n because the params might start with dash
    [ $(echo "$@" | wc -c) -gt 0 ] && params=" ($@)"
    printf "Push to $branch$params\n"
    git push origin "$branch" "$@"
}

function gpnv() {
    gp --no-verify "$@"
}

function gpf() {
    gp --force "$@"
}

function gpfnv() {
    gp --force --no-verify "$@"
}

# Runs "git remote prune" for all remotes,
# removes refs that are fully merged,
# then interactively asks about removing local refs that have no remote counterpart
function gprune() {
    function check_merged_commits() {
        branch_messages="$(git log "$1" ^origin/main --format=%s -- 2> /dev/null)" || return 1
        git log origin/main --format=%s | grep -q "$branch_messages"
    }

    git remote | xargs git remote prune
    for branch in $(git branch | grep -vE "^\*"); do
        git branch --remote | grep -q "$branch\$" && continue
        git branch -d "$branch" > /dev/null 2>&1 && echo "Deleted branch $branch" && continue

        status="data might be lost"
        check_merged_commits "$branch" && status="all commits present in main"

        printf "Force delete %s? (%s) [y/N] " "$branch" "$status"
        read response
        [ "$response" == "y" ] && git branch -D "$branch"
    done
}

# Sets upstream branch to the remote branch with the same name as the checked-out one
function gtrack() {
    remote=$(git remote)
    [ "$(echo $remote | wc -w)" -ne 1 ] && echo "Found several remotes: $remote" && exit 1
    branch=$(git branch --show-current)
    git branch --set-upstream-to=$remote/$branch $branch
}

# ************************* virtualenv aliases *************************

function virtualenv() {
	if [ $# -eq 0 ]; then
		echo "Usage: virtualenv [-v <python version>] ENV_DIR"
		return 0
	fi
	
	VERSION=3
	
	while [ $# -gt 0 ]; do
		key="$1"
		case $key in
			-v|--version)
			VERSION="$2"
			shift
			shift
			;;
			
			*)
			ENV_DIR="$1"
			shift
			;;
		esac
	done
		
	command="python$VERSION -m venv $ENV_DIR"
	$command
}

alias deact='deactivate'

# Navigates directories towards the root while looking for the virtualenv passed as parameter.
# Activates it if found
function activate() {
	if [ -z $1 ]; then
		echo -e "Usage: activate <virtualenv_dir_name>"
		return 0
	fi

	virtualenv_dir="$1"
	
	original_dir=$(pwd)
	current_dir="$original_dir"

	if [ -d "$virtualenv_dir/bin" ] && ! [ -z "$(ls "$virtualenv_dir/bin" | grep activate)" ]; then
		found=true
	else
		found=false
	fi
	
	while ! $found && [ "$current_dir" != "$HOME" ] && [ "$current_dir" != "/" ]; do
		cd ..
		current_dir=$(pwd)
		echo "$current_dir/$virtualenv_dir"
		if [ -d "$virtualenv_dir/bin" ] && ! [ -z "$(ls "$virtualenv_dir/bin" | grep activate)" ]; then
			found=true
		fi
	done
	
	if $found; then
		source "$virtualenv_dir/bin/activate"
		echo "Virtualenv activated"
	else
		echo "Virtualenv $virtualenv_dir not found"
	fi
	
	cd "$original_dir"
}
