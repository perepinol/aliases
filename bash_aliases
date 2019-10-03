echo "************************** general aliases ***************************" > /dev/null

alias sdn='sudo shutdown now'
alias c='clear'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias hg='history | grep '
function mcd() {
	mkdir $1
	cd $1
}
function ensudo() {
    sudo $(history | tail -n 2 | head -n 1 | awk '{$1=""}1')
}

echo "**************************** git aliases *****************************" > /dev/null

alias gs='git status'
alias gt='git tree'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push origin master'
alias gsum='git summary'

echo "************************* virtualenv aliases *************************" > /dev/null

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
function activate() {
	original_dir=$(pwd)
	if ! [ -z $1 ]; then
		cd "$1"
	fi
	
	current_dir=$(pwd)
	
	if [ -d "bin" ] && ! [ -z "$(ls bin | grep activate)" ]; then
		found=true
	else
		found=false
	fi
	
	while ! $found && [ "$current_dir" != "$HOME" ] && [ "$current_dir" != "/" ]; do
		cd ..
		current_dir=$(pwd)
		echo "$current_dir"
		if [ -d "bin" ] && ! [ -z "$(ls bin | grep activate)" ]; then
			found=true
		fi
	done
	
	if $found; then
		source bin/activate
		echo "Activated in virtualenv $current_dir"
	else
		echo "Not in virtualenv"
	fi
	
	cd "$original_dir"
}
