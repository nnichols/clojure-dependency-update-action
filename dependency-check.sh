#!/bin/bash

# Set active git user to the tokens provided
git config --global user.email $EMAIL
git config --global user.name $NAME
export GITHUB_TOKEN=$TOKEN

# Checkout the base branch for all updates
echo "Checking out base branch" $BRANCH
git checkout $BRANCH

# Convert the list of excluded artifacts into a set of --exclude flags
echo "::group::Setting Excludes"
echo "Original excludes: ${EXCLUDE}"
EXCLUDES=""
for artifact in $EXCLUDE; do
    EXCLUDES="${EXCLUDES} --exclude=${artifact}"
    echo ${EXCLUDES}
done
echo "::endgroup::"

# If no directory is specified, default to the current directory
echo "::group::Setting Directory"
echo "Original directory: ${DIRECTORY}"
if [ -z "${DIRECTORY}" ]; then
    DIRECTORY="."
    echo "No directory specified. Defaulting to current directory"
fi

# Convert the list of directories into a set of --directory flags
DIRECTORIES=""
for directory in $DIRECTORY; do
    DIRECTORIES="${DIRECTORIES} --directory=${directory}"
    echo ${DIRECTORIES}
done
echo "::endgroup::"

# Convert the list of skip flags into a set of --skip flags
echo "::group::Setting Skips"
echo "Original skip: ${SKIP}"
SKIPS=""
for skip in $SKIP; do
    SKIPS="${SKIPS} --skip=${skip}"
    echo ${SKIPS}
done
echo "::endgroup::"

# Pre-fetch Antq. This prevents the action from parsing the output of loading the app dependencies
echo "::group::Pre-fetching dependencies"
PREFETCH=$(clojure -Stree -Sdeps '{:deps {antq/antq {:mvn/version "RELEASE"}}}')
echo "::endgroup::"

# Set the reporter for antq to be parsable
FORMATTER="--reporter=format --error-format=\"{{name}},{{version}},{{latest-version}},{{diff-url}}\""
echo "::group::Selected options"
echo "Formatter: ${FORMATTER}"
echo "::endgroup::"

# Run antq to check for outdated dependencies
echo "::group::Checking for outdated dependencies"
UPGRADE_CMD="clojure -Sdeps '{:deps {antq/antq {:mvn/version \"RELEASE\"}}}' -m antq.core ${FORMATTER} ${EXCLUDES} ${DIRECTORIES} ${SKIPS}"
UPGRADE_LIST=$(eval ${UPGRADE_CMD})
echo "::endgroup::"

# Parse the output of antq into a list of upgrades, and remove any failed fetches
UPGRADES=$(echo ${UPGRADE_LIST} | sed '/Failed to fetch/d' | sed '/Unable to fetch/d' | sed '/Logging initialized/d' | sort -u)
UPDATE_TIME=$(date +"%Y-%m-%d-%H-%M-%S")

echo "::group::Upgrades"
echo ${UPGRADES}
echo "::endgroup::"

# Iterate over all upgrades
for upgrade in $UPGRADES; do

  echo "::group::Processing upgrade"

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
      echo "Opening pull request for" $DEP_NAME
      gh pr create --fill --head $BRANCH_NAME --base $BRANCH
    fi

    # Print a blank line, and reset the branch
    echo "Checking out" $BRANCH
    git checkout $BRANCH
  fi

  echo "::endgroup::"

done

# Once all updates have been made, open the pull request for batch mode
if [ "$BATCH" == "true" ]; then
  git checkout $BRANCH_NAME
  echo "Opening pull request for batch update"
  gh pr create --fill --head $BRANCH_NAME --base $BRANCH
fi
