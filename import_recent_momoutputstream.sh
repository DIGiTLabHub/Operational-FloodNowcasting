#!/bin/sh

set -eu

REPO_URL="https://github.com/Global-Flood-Assessment/MoMOutputStream.git"
DEST_ROOT="external/MoMOutputStream_recent"
TEMP_CLONE="external/_temp_MoMOutputStream"
RECENT_LIST="external/recent_files.txt"
SINCE_WINDOW="24 hours ago"

echo "Starting import from $REPO_URL"
echo "Files changed since: $SINCE_WINDOW"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: run this script from inside your Git repository."
  exit 1
fi

rm -rf "$TEMP_CLONE"
rm -f "$RECENT_LIST"

mkdir -p "$DEST_ROOT"
mkdir -p "$(dirname "$TEMP_CLONE")"

echo "Cloning source repository..."
git clone --depth 1 "$REPO_URL" "$TEMP_CLONE"

cd "$TEMP_CLONE"

echo "Collecting changed files..."
git log --since="$SINCE_WINDOW" --name-only --pretty=format: \
  | sed '/^$/d' \
  | sort -u \
  > "../recent_files.txt"

cd ..

if [ ! -s "recent_files.txt" ]; then
  echo "No files changed in the last 24 hours."
  rm -rf "_temp_MoMOutputStream"
  rm -f "recent_files.txt"
  exit 0
fi

echo "Copying files into $DEST_ROOT ..."

while IFS= read -r f; do
  [ -e "_temp_MoMOutputStream/$f" ] || continue
  mkdir -p "MoMOutputStream_recent/$(dirname "$f")"
  cp -R "_temp_MoMOutputStream/$f" "MoMOutputStream_recent/$f"
done < "recent_files.txt"

cd "_temp_MoMOutputStream"
git log --since="$SINCE_WINDOW" --oneline > ../MoMOutputStream_recent/UPSTREAM_COMMITS.txt || true
cd ..

rm -rf "_temp_MoMOutputStream"
rm -f "recent_files.txt"

echo "Done."
echo "Imported files are in: $DEST_ROOT"
echo
echo "Next steps:"
echo "  git add $DEST_ROOT"
echo "  git commit -m \"Import MoMOutputStream files changed in last 24 hours\""
echo "  git push origin main"
