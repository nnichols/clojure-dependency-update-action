#!/bin/bash

git config --global user.email $EMAIL
git config --global user.name $NAME
export GITHUB_TOKEN=$TOKEN
git checkout $BRANCH

EXCLUDES=""
for artifact in $EXCLUDE; do
    EXCLUDES="${EXCLUDES} --exclude=${artifact}"
done

DIRECTORIES=""
for directory in $DIRECTORY; do
    DIRECTORIES="${DIRECTORIES} --directory=${directory}"
done

SKIPS=""
for skip in $SKIP; do
    SKIPS="${SKIPS} --skip=${skip}"
done

PREFETCH=$(clojure -Stree -Sdeps '{:deps {antq/antq {:mvn/version "RELEASE"}}}')
UPGRADES=$(clojure -Sdeps '{:deps {antq/antq {:mvn/version "RELEASE"}}}' -m antq.core --reporter=format --error-format="{{name}},{{version}},{{latest-version}}" $EXCLUDES $DIRECTORIES $SKIPS | sed '/Failed to fetch/d' | sed '/Unable to fetch/d' | sed '/Logging initialized/d')

if [ $BATCH = 'true' ]; then
  BRANCH_NAME="dependencies/clojure/$(date +"%Y-%m-%d-%H-%M-%S")"
  git checkout -b $BRANCH_NAME
  for upgrade in $UPGRADES; do
    IFS=',' temp=($upgrade)
    DEP_NAME=${temp[0]}
    OLD_VERSION=${temp[1]}
    NEW_VERSION=${temp[2]}
    echo "Updating" $DEP_NAME "version" $OLD_VERSION "to" $NEW_VERSION
    ESCAPED_DEP_NAME=`echo $DEP_NAME | sed 's/\//\\\\\//'`
    sed -e "/$ESCAPED_DEP_NAME/s/$OLD_VERSION/$NEW_VERSION/" deps.edn > deps2.edn
    mv deps2.edn deps.edn
    git add deps.edn
    git commit -m "Bump $DEP_NAME from $OLD_VERSION to $NEW_VERSION"
  done
  git push -u "https://$GITHUB_ACTOR:$TOKEN@github.com/$GITHUB_REPOSITORY.git" $BRANCH_NAME
  gh pr create --fill --head $BRANCH_NAME --base $BRANCH
  echo
  git checkout $BRANCH
else
  for upgrade in $UPGRADES; do
    IFS=',' temp=($upgrade)
    DEP_NAME=${temp[0]}
    OLD_VERSION=${temp[1]}
    NEW_VERSION=${temp[2]}
    BRANCH_NAME="dependencies/clojure/$DEP_NAME-$NEW_VERSION"
    echo "Updating" $DEP_NAME "version" $OLD_VERSION "to" $NEW_VERSION
    git checkout -b $BRANCH_NAME
    if [[ $? == 0 ]]; then
      ESCAPED_DEP_NAME=`echo $DEP_NAME | sed 's/\//\\\\\//'`
      sed -e "/$ESCAPED_DEP_NAME/s/$OLD_VERSION/$NEW_VERSION/" deps.edn > deps2.edn
      mv deps2.edn deps.edn
      git add deps.edn
      git commit -m "Bump $DEP_NAME from $OLD_VERSION to $NEW_VERSION"
      git push -u "https://$GITHUB_ACTOR:$TOKEN@github.com/$GITHUB_REPOSITORY.git" $BRANCH_NAME
      gh pr create --fill --head $BRANCH_NAME --base $BRANCH
      echo
      git checkout $BRANCH
    fi
  done
fi
