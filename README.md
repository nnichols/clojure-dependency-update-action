# Clojure Dependency Update Action

A simple GitHub action to create Pull Requests for your out-of-date tools.deps dependencies.

This action uses [antq](https://github.com/liquidz/antq) to check dependencies.

## Sample Usage

```yml
name: Clojure Dependency Checking

on: [push]

jobs:
  build:

    runs-on: ubuntu-latest

    steps:
    - name: Checkout Latest Commit
      uses: actions/checkout@v1

    - name: Check deps
      uses: nnichols/clojure-dependency-update-action@v1
      with:
        github-token: ${{ secrets.github_token }}
```

## Supported Arguments

* `github-token`: The only required argument. Can either be the default token, as seen above, or a personal access token with write access to the repository.
* `branch`: The branch that dependencies should be checked on and Pull Requests created against. Defaults to `master`
* `git-email`: The email address each commit should be associated with. Defaults to a github provided noreply address
* `git-username`: The GitHub username each commit should be associated with. Defaults to `github-actions[bot]`
* `excludes`: Artifact names to be excluded from the `antq` check. Defaults to an empty list. See [antq-action](https://github.com/liquidz/antq-action#inputs) for more information.
* `directories`: Directories to search for project files in. Defaults to the root of the repository. See [antq-action](https://github.com/liquidz/antq-action#inputs) for more information.
* `skips`: Build tools/files to skip by default. Defaults to an empty list. See [antq-action](https://github.com/liquidz/antq-action#inputs) for more information.

## Acknowledgements

Special thanks to [Chad Taylor](https://github.com/tessellator) for figuring out the initial bash script this is based on.
