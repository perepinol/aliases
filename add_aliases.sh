#!/bin/bash

if [ -f "git_aliases.sh" ]; then
    chmod +x git_aliases.sh
    ./git_aliases.sh
fi
if [ -f "bash_aliases" ]; then
    while read line; do
        if [[ "$line" == \#* ]]; then
            continue
        fi
        echo "$line"
    done < bash_aliases
fi
