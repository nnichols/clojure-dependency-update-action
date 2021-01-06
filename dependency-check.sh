#!/bin/bash

git config --global user.email $EMAIL
git config --global user.name $NAME

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

UPGRADES=$(clojure -Sdeps '{:deps {antq/antq {:mvn/version "RELEASE"}}}' -m antq.core --reporter=format --error-format="{{name}},{{version}},{{latest-version}}" $EXCLUDES $DIRECTORIES $SKIPS | sed '/Failed to fetch/d')

for upgrade in $upgrades; do
  IFS=',' temp=($upgrade)
  dep_name=${temp[0]}
  old_version=${temp[1]}
  new_version=${temp[2]}
  branch_name="dependencies/clojure/$dep_name-$new_version"
  git checkout -b $branch_name
  if [[ $? == 0 ]]; then
    escaped_dep_name=`echo $dep_name | sed 's/\//\\\\\//'`
    sed -e "/$escaped_dep_name/s/$old_version/$new_version/" deps.edn > deps2.edn
    mv deps2.edn deps.edn
    git add deps.edn
    git commit -m "Bump $dep_name from $old_version to $new_version"
    git push
    gh pr create --fill --base $BRANCH
    git checkout $BRANCH
  fi
done
