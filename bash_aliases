#************************** general aliases ***************************

alias sdn='sudo shutdown now'
alias c='clear'
alias explorer='xdg-open'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias h='history'
alias hg='history | grep'
alias d='docker'
alias dc='docker-compose'

# Runs last instance of the command in the history that starts with the given args
function hgr() {
    command=$(history | tail -n +2 | grep "$*" | grep -v hgr | grep -v hg | awk '{$1=""}1' | tail -n 1)
    echo "$command"
    $command
}

# Find process IDs by name
function process() {
    ps -ef | awk -v search="$1" '
    /^UID/ { print $0 }
    {
        if ($8 ~ search) print $0
    }'
}

function mcd() {
	mkdir $1
	cd $1
}

# Run the last command in the history with `sudo`
function ensudo() {
    command=$(history | tail -n 2 | head -n 1 | awk '{$1=""}1')
    echo "sudo$command"
    sudo $command
}

# **************************** git aliases *****************************

alias gs='git status'
alias gt='git tree'
alias ga='git add'
alias gc='git commit -m'
alias gca='git commit --amend --no-edit'
alias gsum='git summary'
function gp() {
    branch=$(git branch | awk '/^\\\*/ {print \$2}')
    echo "Push to $branch"
    git push origin "$branch"
}
function gpf() {
    branch=$(git branch | awk '/^\\\*/ {print \$2}')
    echo "Push to $branch (FORCED)"
    git push origin "$branch" --force
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
