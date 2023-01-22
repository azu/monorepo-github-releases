#!/bin/bash

# This script is used to migrate to GitHub Release-based workflow.
function echo_message() {
  echo "\033[31m=>\033[0m \033[036m$1\033[0m"
}

# Select lerna or npm
declare package_manager
package_manager=$(test -f lerna.json && echo "lerna" || echo "npm")

if [ "$package_manager" = "lerna" ]; then
  migrateLerna
  downLoadLernaWorkflows
else
  migrateNpm
  downLoadNpmWorkflows
fi

function downLoadLernaWorkflows() {
  echo_message "Download .github/workflows for Lerna"
  curl -fsSL "https://raw.githubusercontent.com/azu/monorepo-github-releases/main/.github/workflows/create-release-pr.yml" >.github/workflows/create-release-pr.yml
  curl -fsSL "https://raw.githubusercontent.com/azu/monorepo-github-releases/main/.github/workflows/release.yml" >.github/workflows/release.yml
}
function downLoadNpmWorkflows() {
  echo_message "Download .github/workflows"
  curl -fsSL "https://raw.githubusercontent.com/azu/monorepo-github-releases/main/.github/workflows/create-release-pr.yml" |
    sed -e "s/lerna.json/package.json/g" >.github/workflows/create-release-pr.yml
  curl -fsSL "https://raw.githubusercontent.com/azu/monorepo-github-releases/main/.github/workflows/release.yml" |
    sed -e "s/lerna.json/package.json/g" >.github/workflows/release.yml
}

function migrateLerna() {
  echo_message "Migrate package.json for Lerna"
  npm pkg set "versionup"="lerna version",
  npm pkg set "ci:versionup:patch"="lerna version patch --no-push --no-git-tag-version --yes && npm run commit-version",
  npm pkg set "ci:versionup:minor"="lerna version minor --no-push --no-git-tag-version --yes && npm run commit-version",
  npm pkg set "ci:versionup:major"="lerna version major --no-push --no-git-tag-version --yes && npm run commit-version",
  npm pkg set "commit-version"="git add . && git commit -m \"chore(release): v$(node -p 'require(\"./lerna.json\").version')\"",
  npm pkg set "release"="lerna publish from-package",
  npm pkg set "ci:release"="lerna publish from-package --yes"
}

function migrateNpm() {
  echo_message "Migrate package.json"
  npm pkg set "ci:versionup:patch"="npm version patch --no-push --no-git-tag-version --yes && npm run commit-version",
  npm pkg set "ci:versionup:minor"="npm version minor --no-push --no-git-tag-version --yes && npm run commit-version",
  npm pkg set "ci:versionup:major"="npm version major --no-push --no-git-tag-version --yes && npm run commit-version",
  npm pkg set "commit-version"="git add . && git commit -m \"chore(release): v$(node -p 'require(\"./package.json\").version')\"",
  npm pkg set "ci:release"="npm publish --yes",
}
