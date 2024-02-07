#!/bin/bash

msg="Commit on $(date)"
if [ -z "$1" 	]; then
	msg="$1"
fi

hugo
git add .
git commit -m "$msg"
git push origin master