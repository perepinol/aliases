#************************** general aliases ***************************

alias sdn='sudo shutdown now'
alias c='clear'
alias explorer='xdg-open'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias h='history'
alias d='docker'
alias dc='docker-compose'
alias k='kubectl'

# Prints the given line number from stdin, or a variable if given. Also used in these scripts as a helper
function line() {
    [ -z "$1" ] && echo "Usage: line <line_number>" && return 1

    if [ -z "$2" ]; then
        head -n "$1" | tail -n +"$1"
    else
        echo "$2" | head -n "$1" | tail -n +"$1"
    fi
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

# Runs a command and beeps when it is done
function bgrun() {
    (eval $*; beep) &
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
                argcount=$(echo "$*" | wc -l)
                for i in $(seq $argcount); do
                    text=$(line $i "$*")
                    echo "[$i] $text" 1>&2
                done
                read result
                ! [[ "$result" =~ ^[0-9]+$ ]] || [ "$result" -lt 1 -o "$result" -gt $argcount ] && echo "Invalid value $result" 1>&2 && return 1
                echo "$((result - 1))"
            }

            index=$(select_option "$names") || return 1
            pid_array=($pid)
            pid=${pid_array[$index]}
        fi
    fi

    [ -z "$pid" ] && echo "Process \"$*\" not found" && return 1

    function poll() {
        while true; do
            if ! ps -p $pid &> /dev/null; then break; fi
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
    echo "Push to $branch"
    git push origin "$branch" "$@"
}
function gpf() {
    branch=$(git branch --show-current)
    echo "Push to $branch (FORCED)"
    git push origin "$branch" --force "$@"
}
function gprune() {
    for remote in $(git remote); do
        git remote prune "$remote"
    done
    for branch in $(git branch | grep -vE "\* .*"); do
        remote=$(git branch --remote | grep "$branch\$")
        if [ -n "$remote" ]; then continue; fi
        if [ "$1" == "-f" ]; then
            git branch -D "$branch"
        else
            git branch -d "$branch"
        fi
    done
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
