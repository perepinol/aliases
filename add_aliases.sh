#!/bin/bash

if [ -f "git_aliases.sh" ]; then
    chmod +x git_aliases.sh
    ./git_aliases.sh
fi
if [ -f "bash_aliases.sh" ]; then
    cp bash_aliases.sh ~/.bash_aliases
fi
