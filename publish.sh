#!/bin/bash

git checkout main
git pull
git checkout publisher
git pull
git merge main
git push
git checkout main
git push
