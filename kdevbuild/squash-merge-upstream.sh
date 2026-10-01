#!/bin/bash

set -xe

git merge --squash --allow-unrelated-histories upstream/master
git checkout --theirs -- .
git add -A
git commit -m "sync: snapshot from upstream/master at $(date +%Y-%m-%d)"
echo "All done!"

