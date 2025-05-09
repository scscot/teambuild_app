#!/bin/bash

# -------------------------
# Git Sync Script with Semantic Versioning
# -------------------------

SRC_DIR=~/Desktop/tbp
DEST_DIR=~/Desktop/tbp_git
REPO_URL="https://github.com/scscot/tbp_git.git"
DEFAULT_BUMP="patch"

# --- Sync files ---
echo "🔄 Syncing $SRC_DIR → $DEST_DIR"
rsync -av --exclude='.git' --exclude='build' --exclude='.dart_tool' --exclude='.idea' --exclude='.DS_Store' --delete "$SRC_DIR/" "$DEST_DIR/"

cd "$DEST_DIR" || exit 1

# Init repo if needed
if [ ! -d .git ]; then
  echo "🧱 Initializing Git repo..."
  git init
  git remote add origin "$REPO_URL"
fi

# --- Commit changes ---
git add .
read -p "📝 Commit message: " COMMIT_MSG
COMMIT_MSG=${COMMIT_MSG:-"Auto-sync from tbp"}
git commit -m "$COMMIT_MSG"

# --- Determine latest version ---
LATEST_TAG=$(git tag --sort=-v:refname | head -n 1)
LATEST_TAG=${LATEST_TAG:-v1.0.0}

# Parse version numbers
IFS='.' read -r MAJOR MINOR PATCH <<<"${LATEST_TAG#v}"

# --- Choose bump type ---
read -p "🔢 Bump version type (patch/minor/major) [default: patch]: " BUMP
BUMP=${BUMP:-$DEFAULT_BUMP}

case $BUMP in
  major)
    ((MAJOR++))
    MINOR=0
    PATCH=0
    ;;
  minor)
    ((MINOR++))
    PATCH=0
    ;;
  patch|*)
    ((PATCH++))
    ;;
esac

NEW_TAG="v$MAJOR.$MINOR.$PATCH"

# --- Tag and push ---
git branch -M main
git tag "$NEW_TAG"
git push origin main --tags

echo "✅ Pushed to GitHub tbp_git repository with tag: $NEW_TAG"
