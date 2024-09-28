#!/bin/bash

set -eo pipefail

commit_hashes=$(git log --since="Aug 1 2020 00:00+00:00" --format=%H)

mkdir -p patches
mkdir -p files

for hash in $commit_hashes; do
  commit_date_timestamp=$(git show -s --format=%ct "$hash")
#  commit_date=$(date -r "$commit_date_timestamp" -u "+%Y-%m-%dT%H:%M:%S")
  commit_date=$(date -d "@$commit_date_timestamp" -u "+%Y-%m-%dT%H:%M:%S")

  filename="${commit_date}_${hash}"

  list_file="patches/${filename}_files.txt"
  patch_file="patches/$filename.patch"

  git diff-tree --no-commit-id --name-only -r -m "$hash" > "$list_file"
  touch -d "$commit_date" "$list_file"
  ok_files="t"
  while read -r f; do
    case "$f" in
      *.scala|*.java|*.json|*.properties|*.sbt|*.gradle)
        ;;
      *)
        ok_files="f"
        ;;
    esac
  done < "$list_file"

  if [[ $ok_files == "t" ]]; then
    git format-patch --1 "$hash" --stdout > "$patch_file"
    touch -d "$commit_date" "$patch_file"

    mkdir -p "files/$filename"
    while read -r f; do
      mkdir -p "files/$filename/${f%/*}"
      git show "$hash^1:$f" 2>/dev/null > "files/$filename/$f" || rm -rf "files/$filename/$f"
    done < "$list_file"

    echo "Created patch file: $filename"
  else
    rm -rf "$list_file"
    rm -rf "$patch_file"
    rm -rf "files/$filename"

    echo "Skipped patch file: $filename"
  fi
done

echo "Done"
