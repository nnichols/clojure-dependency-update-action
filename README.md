# Clojure Dependency Update Action

A simple GitHub action to create Pull Requests for your out-of-date dependencies in clojure projects.
This action can automatically update the following dependency files:

- [deps.edn](https://github.com/clojure/tools.deps.alpha)
- [shadow-cljs.edn](https://github.com/thheller/shadow-cljs)
- [project.clj](https://github.com/technomancy/leiningen)
- [build.boot](https://github.com/boot-clj/boot)
- [pom.xml](https://github.com/apache/maven)

This action uses [antq](https://github.com/liquidz/antq) to check dependencies.

## Sample Usage

### Basic

```yml
name: Clojure Dependency Checking

on: [push]

jobs:
  build:

    runs-on: ubuntu-latest

    steps:
    - name: Checkout Latest Commit
      uses: actions/checkout@v3.0.2

    - name: Check deps
      uses: nnichols/clojure-dependency-update-action@v4
      with:
        github-token: ${{ secrets.github_token }}
```

### Advanced

```yml

name: Batch Dependency Update

on: workflow_dispatch

jobs:
  build:

    runs-on: ubuntu-latest

    steps:
    - name: Checkout Latest Commit
      uses: actions/checkout@v3.0.2

    - name: Check deps
      uses:  nnichols/clojure-dependency-update-action@v4
      with:
        github-token: ${{ secrets.github_token }}
        git-username: nnichols
        skips: "pom boot"
        batch: true
        branch: "main"
        directories: "cli web"
```

## Supported Arguments

- `github-token`: The only required argument. Can either be the default token, as seen above, or a personal access token with write access to the repository.
- `branch`: The branch that dependencies should be checked on and Pull Requests created against. Defaults to `master`
- `git-email`: The email address each commit should be associated with. Defaults to a github provided noreply address
- `git-username`: The GitHub username each commit should be associated with. Defaults to `github-actions[bot]`
- `excludes`: Artifact names to be excluded from the `antq` check. Defaults to an empty list. See [antq-action](https://github.com/liquidz/antq-action#inputs) for more information.
- `directories`: Directories to search for project files in. Defaults to the root of the repository. See [antq-action](https://github.com/liquidz/antq-action#inputs) for more information.
- `skips`: Build tools/files to skip by default. Defaults to an empty list. See [antq-action](https://github.com/liquidz/antq-action#inputs) for more information.
- `batch`:  Updates all outdated dependencies in a single pull request. Set to "true" to enable

## Acknowledgements

Special thanks to [Chad Taylor](https://github.com/tessellator) for figuring out the initial bash script this is based on.

## Licensing

Copyright © 2021-2023 [Nick Nichols](https://nnichols.github.io/)

Distributed under the [MIT License](https://github.com/nnichols/clojure-dependency-update-action/blob/master/LICENSE)
