#!/bin/bash

msg="Commit on $(date)"
if [ -z "$1" 	]; then
	msg="$1"
fi
echo "Commit msg:$msg"

hugo
git add .
git commit -m "$msg"
git push origin master