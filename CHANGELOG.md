# Changelog

## v5 - 04/01/2023

- Group logs emitted during the action for easier consumption
- Emit intermittent logs to describe settings and progress
- FIX: Explicitly set the Pull Request title/body for more recent GitHub CLI requirements
- Add advisory not regrading `actions/checkout` version requirements

## v4 - 01/29/2022

- Dependency update commit messages now link to the github diff between the old and new version.
- Utilize antq instead of sed for updating dependencies
- Fix multi-directory support

## v3 - 01/30/2021

- Enable a batch update mode

## v2 - 01/09/2021

- Use Docker image with dependencies pre-loaded

## v1 - 01/06/2021

- Initial Implementation
