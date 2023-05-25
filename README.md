# Clojure Dependency Update Action

A GitHub Action to create Pull Requests for your out-of-date dependencies in clojure projects.
This action can automatically update the following dependency files:

- [deps.edn](https://github.com/clojure/tools.deps.alpha)
- [shadow-cljs.edn](https://github.com/thheller/shadow-cljs)
- [project.clj](https://github.com/technomancy/leiningen)
- [build.boot](https://github.com/boot-clj/boot)
- [pom.xml](https://github.com/apache/maven)

This action uses [antq](https://github.com/liquidz/antq) to check and update dependencies.

## Requirements

The Actions platform is constantly being refined by the GitHub team.
To ensure the safety of all end-users, they occasionally deprecate functionality which poses security risks.
This impacts all first and third party Actions which you may use in your workflows.
When diagnosing issues, please check your Actions tab for any deprecation notices.

As of writing, this action requires that `actions/checkout` is set to at least `3.x.y`.

## Maintenance Mode

As of May 25, 2023 this action is now in maintenence mode.
I will continue to support existing users by applying patches and fixes, but new feature development is frozen.
I recommend upgrading dependency management to a cross-language tool such as [Renovate.](https://github.com/renovatebot/renovate "The RenovateBot repository")

If you prefer per-language tools, you are free to fork this repository or reference its implementation in the Actions you maintain.

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
      uses: actions/checkout@v3.5.0
      with:
        ref: ${{ github.head_ref }}

    - name: Check Clojure Dependencies
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
      uses: actions/checkout@v3.5.0
      with:
        ref: ${{ github.head_ref }}

    - name: Check Clojure Dependencies
      uses: nnichols/clojure-dependency-update-action@v4
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

## Alternatives

As the Clojure ecosystem matures, more first-class options for dependency management now support the language.
The following is a growing list of alternative tools to consider:

- [Renovatebot](https://github.com/renovatebot/renovate "The RenovateBot repository")

## Acknowledgements

Special thanks to [Chad Taylor](https://github.com/tessellator "Chad's GitHub Profile") for figuring out the initial bash script this is based on.

## Licensing

Copyright © 2021-2023 [Nick Nichols](https://nnichols.github.io/)

Distributed under the [MIT License](https://github.com/nnichols/clojure-dependency-update-action/blob/master/LICENSE)
