echo "************************** general aliases ***************************" > /dev/null

alias sdn='sudo shutdown now'
alias c='clear'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

echo "**************************** git aliases *****************************" > /dev/null

alias gs='git status'
alias gt='git tree'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push origin master'
alias gsum='git summary'

echo "************************* virtualenv aliases *************************" > /dev/null

alias virtualenv='python3 -m venv'
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
