#!/bin/bash

set -e
set -x

if [ -z "$INPUT_SOURCE_FOLDER" ]
then
  echo "Source folder must be defined"
  return -1
fi

if [ $INPUT_DESTINATION_HEAD_BRANCH == "main" ] || [ $INPUT_DESTINATION_HEAD_BRANCH == "master"]
then
  echo "Destination head branch cannot be 'main' nor 'master'"
  return -1
fi

if [ -z "$INPUT_PULL_REQUEST_REVIEWERS" ]
then
  PULL_REQUEST_REVIEWERS=$INPUT_PULL_REQUEST_REVIEWERS
else
  PULL_REQUEST_REVIEWERS='--reviewer '$INPUT_PULL_REQUEST_REVIEWERS
fi

CLONE_DIR=$(mktemp -d)

echo "Setting git variables"
export GITHUB_TOKEN=$API_TOKEN_GITHUB
git config --global user.email "$INPUT_USER_EMAIL"
git config --global user.name "$INPUT_USER_NAME"

echo "Cloning destination git repository"
git clone "https://$API_TOKEN_GITHUB@github.com/$INPUT_DESTINATION_REPO.git" "$CLONE_DIR"

echo "Checkout to branch: $INPUT_DESTINATION_HEAD_BRANCH"
pushd "$CLONE_DIR"
git checkout "$INPUT_DESTINATION_HEAD_BRANCH" || git checkout -b "$INPUT_DESTINATION_HEAD_BRANCH"
popd

echo "Copying contents to git repo"
rsync -r -v --delete-after --mkpath "$INPUT_SOURCE_FOLDER/" "$CLONE_DIR/$INPUT_DESTINATION_FOLDER/"

echo "Adding git commit"
pushd "$CLONE_DIR"
if git diff --name-only --exit-code
then
  echo "No changes detected"
else
  git add .
  git commit --message "$INPUT_COMMIT_MESSAGE"
  echo "Pushing git commit"
  git push origin $INPUT_DESTINATION_HEAD_BRANCH
fi

if git diff --name-only --exit-code $INPUT_DESTINATION_BASE_BRANCH..$INPUT_DESTINATION_HEAD_BRANCH
then
    echo "No PR required"
else
    echo "Creating a pull request"
    gh pr create --title "$INPUT_PR_TITLE" \
                 --body "$INPUT_PR_BODY" \
                 --base $INPUT_DESTINATION_BASE_BRANCH \
                 --head $INPUT_DESTINATION_HEAD_BRANCH \
                 $PULL_REQUEST_REVIEWERS
fi
popd