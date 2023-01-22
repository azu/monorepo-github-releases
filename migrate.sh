#!/bin/bash

# Select lerna or npm
declare packageType
packageType=$(test -f lerna.json && echo "lerna" || echo "npm")
declare packageManager
packageManager=$(test -f yarn.lock && echo "yarn" || echo "npm")

# This script is used to migrate to GitHub Release-based workflow.
function echo_message() {
  echo "🤖 $1"
}

function downLoadLernaWorkflows() {
  mkdir -p .github/workflows
  echo_message "Download .github/workflows for Lerna"
  curl -fsSL "https://raw.githubusercontent.com/azu/monorepo-github-releases/main/.github/workflows/create-release-pr.yml" >.github/workflows/create-release-pr.yml
  echo_message "Create .github/workflows/create-release-pr.yml"
  curl -fsSL "https://raw.githubusercontent.com/azu/monorepo-github-releases/main/.github/workflows/release.yml" |
    sed -r "s/^(\s*)(.*)# \[EXAMPLE\]$/\1#\2/g" |
    sed -e "s/# registry-url/registry-url/" |
    sed -e "s/# NODE_AUTH_TOKEN/NODE_AUTH_TOKEN/g" >.github/workflows/release.yml
  if [[ "$packageManager" = "npm" ]]; then
    sed -e "s/yarn install/npm ci/g" .github/workflows/release.yml
  fi
  echo_message "Create .github/workflows/release.yml"

}
function downLoadNpmWorkflows() {
  mkdir -p .github/workflows
  echo_message "Download .github/workflows"
  curl -fsSL "https://raw.githubusercontent.com/azu/monorepo-github-releases/main/.github/workflows/create-release-pr.yml" |
    sed -e "s/lerna.json/package.json/g" >.github/workflows/create-release-pr.yml

  echo_message "Create .github/workflows/create-release-pr.yml"
  curl -fsSL "https://raw.githubusercontent.com/azu/monorepo-github-releases/main/.github/workflows/release.yml" |
    sed -e "s/lerna.json/package.json/g" |
    sed -r "s/^(\s*)(.*)# \[EXAMPLE\]$/\1#\2/g" |
    sed -e "s/# registry-url/registry-url/" |
    sed -e "s/# NODE_AUTH_TOKEN/NODE_AUTH_TOKEN/g" >.github/workflows/release.yml
  if [[ "$packageManager" = "npm" ]]; then
    sed -e "s/yarn install/npm ci/g" .github/workflows/release.yml
  fi
  echo_message "Create .github/workflows/release.yml"
}

function migrateLerna() {
  echo_message "Migrate package.json for Lerna"
  npm pkg set "versionup"="lerna version"
  npm pkg set "ci:versionup:patch"="lerna version patch --no-push --no-git-tag-version --yes && npm run commit-version"
  npm pkg set "ci:versionup:minor"="lerna version minor --no-push --no-git-tag-version --yes && npm run commit-version"
  npm pkg set "ci:versionup:major"="lerna version major --no-push --no-git-tag-version --yes && npm run commit-version"
  npm pkg set "commit-version"="git add . && git commit -m \"chore(release): v\$(node -p 'require(\"./lerna.json\").version')\""
  npm pkg set "release"="lerna publish from-package"
  npm pkg set "ci:release"="lerna publish from-package --yes"
}

function migrateNpm() {
  echo_message "Migrate package.json"
  npm pkg set "ci:versionup:patch"="npm version patch --no-push --no-git-tag-version --yes && npm run commit-version"
  npm pkg set "ci:versionup:minor"="npm version minor --no-push --no-git-tag-version --yes && npm run commit-version"
  npm pkg set "ci:versionup:major"="npm version major --no-push --no-git-tag-version --yes && npm run commit-version"
  npm pkg set "commit-version"="git add . && git commit -m \"chore(release): v\$(node -p 'require(\"./package.json\").version')\""
  npm pkg set "ci:release"="npm publish --yes"
}

if [ "$packageType" = "lerna" ]; then
  migrateLerna
  downLoadLernaWorkflows
else
  migrateNpm
  downLoadNpmWorkflows
fi
