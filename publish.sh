#!/bin/bash

git checkout publisher
git merge main
git push
git checkout main
git push
