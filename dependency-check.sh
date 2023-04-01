#!/bin/bash

# Set active git user to the tokens provided
git config --global user.email $EMAIL
git config --global user.name $NAME
export GITHUB_TOKEN=$TOKEN

# Checkout the base branch for all updates
git checkout $BRANCH

# Convert the list of excluded artifacts into a set of --exclude flags
EXCLUDES=""
for artifact in $EXCLUDE; do
    EXCLUDES="${EXCLUDES} --exclude=${artifact}"
done

# If no directory is specified, default to the current directory
if [ -z "${DIRECTORY}" ]; then
    DIRECTORY="."
fi

# Convert the list of directories into a set of --directory flags
DIRECTORIES=""
for directory in $DIRECTORY; do
    DIRECTORIES="${DIRECTORIES} --directory=${directory}"
done

# Convert the list of skip flags into a set of --skip flags
SKIPS=""
for skip in $SKIP; do
    SKIPS="${SKIPS} --skip=${skip}"
done

# Pre-fetch Antq. This prevents the action from parsing the output of loading the app dependencies
PREFETCH=$(clojure -Stree -Sdeps '{:deps {antq/antq {:mvn/version "RELEASE"}}}')

# Set the reporter for antq to be parsable
FORMATTER="--reporter=format --error-format=\"{{name}},{{version}},{{latest-version}},{{diff-url}}\""

# Run antq to check for outdated dependencies
UPGRADE_CMD="clojure -Sdeps '{:deps {antq/antq {:mvn/version \"RELEASE\"}}}' -m antq.core ${FORMATTER} ${EXCLUDES} ${DIRECTORIES} ${SKIPS}"
UPGRADE_LIST=$(eval ${UPGRADE_CMD})

# Parse the output of antq into a list of upgrades, and remove any failed fetches
UPGRADES=$(echo ${UPGRADE_LIST} | sed '/Failed to fetch/d' | sed '/Unable to fetch/d' | sed '/Logging initialized/d' | sort -u)
UPDATE_TIME=$(date +"%Y-%m-%d-%H-%M-%S")

# Iterate over all upgrades
for upgrade in $UPGRADES; do

  # Parse each upgrade into its constituent parts
  IFS=',' temp=($upgrade)
  DEP_NAME=${temp[0]}
  OLD_VERSION=${temp[1]}
  NEW_VERSION=${temp[2]}
  DIFF_URL=${temp[3]}
  MODIFIED_FILE=${temp[4]}

  # If we're performing a batch update, reuse the branch name
  # Otherwise, create branch names for each unique update
  if [ "$BATCH" == "true" ]; then
    BRANCH_NAME="dependencies/clojure/${UPDATE_TIME}"
  else
    BRANCH_NAME="dependencies/clojure/$DEP_NAME-$NEW_VERSION"
  fi

  # Checkout the branch if it exists, otherwise create it
  echo "Checking out" $BRANCH_NAME
  git checkout $BRANCH_NAME || git checkout -b $BRANCH_NAME

  if [[ $? == 0 ]]; then

    # Use antq to update the dependency
    echo "Updating" $DEP_NAME "version" $OLD_VERSION "to" $NEW_VERSION
    UPDATE_CMD="clojure -Sdeps '{:deps {antq/antq {:mvn/version \"RELEASE\"}}}' -m antq.core --upgrade --force ${DIRECTORIES} --focus=${DEP_NAME}"
    eval ${UPDATE_CMD} || $(echo "Cannot update ${DEP_NAME}. Continuing" && git checkout ${BRANCH} && continue)

    # Commit the dependency update, and link to the diff
    git add .
    git commit -m "Bumped $DEP_NAME from $OLD_VERSION to $NEW_VERSION." -m "Inspect dependency changes here: $DIFF_URL"
    git push -u "https://$GITHUB_ACTOR:$TOKEN@github.com/$GITHUB_REPOSITORY.git" $BRANCH_NAME

    # We only create pull requests per dependency in non-batch mode
    if [ "$BATCH" != "true" ]; then
      gh pr create --fill --head $BRANCH_NAME --base $BRANCH
    fi

    # Print a blank line, and reset the branch
    echo
    git checkout $BRANCH
  fi
done

# Once all updates have been made, open the pull request for batch mode
if [ "$BATCH" == "true" ]; then
  git checkout $BRANCH_NAME
  gh pr create --fill --head $BRANCH_NAME --base $BRANCH
fi
