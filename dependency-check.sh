#!/bin/bash

git config --global user.email $EMAIL
git config --global user.name $NAME
export GITHUB_TOKEN=$TOKEN
git checkout $BRANCH

EXCLUDES=""
for artifact in $EXCLUDE; do
    EXCLUDES="${EXCLUDES} --exclude=${artifact}"
done

if [ -z "${DIRECTORY}" ]; then
    DIRECTORY="."
fi

DIRECTORIES=""
for directory in $DIRECTORY; do
    DIRECTORIES="${DIRECTORIES} --directory=${directory}"
done

SKIPS=""
for skip in $SKIP; do
    SKIPS="${SKIPS} --skip=${skip}"
done

PREFETCH=$(clojure -Stree -Sdeps '{:deps {antq/antq {:mvn/version "RELEASE"}}}')
UPGRADES=$(clojure -Sdeps '{:deps {antq/antq {:mvn/version "RELEASE"}}}' -m antq.core --reporter=format --error-format="{{name}},{{version}},{{latest-version}},{{diff-url}},{{file}}" $EXCLUDES $DIRECTORIES $SKIPS | sed '/Failed to fetch/d' | sed '/Unable to fetch/d' | sed '/Logging initialized/d')
UPDATE_TIME=$(date +"%Y-%m-%d-%H-%M-%S")

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
  if [ $BATCH = 'true' ]; then
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
    clojure -Sdeps '{:deps {antq/antq {:mvn/version "RELEASE"}}}' -m antq.core --upgrade --force $DIRECTORIES --focus=${DEP_NAME} || $(echo "Cannot update $DEP_NAME. Continuing" && git checkout $BRANCH && continue)

    # Commit the dependency update, and link to the diff
    git add .
    git commit -m "Bumped $DEP_NAME from $OLD_VERSION to $NEW_VERSION." -m "Inspect dependency changes here: $DIFF_URL"
    git push -u "https://$GITHUB_ACTOR:$TOKEN@github.com/$GITHUB_REPOSITORY.git" $BRANCH_NAME

    # We only create pull requests per dependency in non-batch mode
    if [$BATCH != 'true']; then
      gh pr create --fill --head $BRANCH_NAME --base $BRANCH
    fi

    # Print a blank line, and reset the branch
    echo
    git checkout $BRANCH
  fi
done

# Once all updates have been made, open the pull request for batch mode
if [$BATCH = 'true']; then
  git checkout $BRANCH_NAME
  gh pr create --fill --head $BRANCH_NAME --base $BRANCH
fi
