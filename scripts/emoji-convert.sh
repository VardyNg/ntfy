#!/bin/bash

# This script reduces the size and converts the emoji.json file from https://github.com/github/gemoji/blob/master/db/emoji.json
# to be used in the Android app (app/src/main/resources/emoji.json) and the Web UI (server/static/js/emoji.js).

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"
ROOTDIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ -z "$1" ]; then
    echo "Syntax: $0 FILE.(js|json|md)"
    echo "Example:"
    echo "  $0 emoji-converted.json"
    echo "  $0 $ROOTDIR/web/src/app/emojis.js"
    echo "  $0 $ROOTDIR/docs/emojis.md"
    exit 1
fi

if [[ "$1" == *.js ]]; then
  echo -n "// This file is generated by scripts/emoji-convert.sh to reduce the size
// Original data source: https://github.com/github/gemoji/blob/master/db/emoji.json
export const rawEmojis = " > "$1"
    cat "$SCRIPTDIR/emoji.json" | jq -rc 'map({emoji: .emoji, aliases: .aliases, tags: .tags, category: .category, description: .description, unicode_version: .unicode_version})' >> "$1"
elif [[ "$1" == *.md ]]; then
  echo "# Emoji reference

<!-- This file was generated by scripts/emoji-convert.sh -->

You can [tag messages](../publish/#tags-emojis) with emojis 🥳 🎉 and other relevant strings. Matching tags are automatically
converted to emojis. This is a reference of all supported emojis. To learn more about the feature, please refer to the
[tagging and emojis page](../publish/#tags-emojis).

<table class="remove-md-box"><tr>
" > "$1"

  count="$(cat "$SCRIPTDIR/emoji.json" | jq -r '.[] | .emoji' | wc -l)"
  percolumn=$(($count / 3)) # This will misbehave if the count is not divisible by 3
  for col in 0 1 2; do
    from="$(($col * $percolumn + 1))"
    to="$(($col * $percolumn + 1 + $percolumn))"
    echo "<td><table><thead><tr><th>Tag</th><th>Emoji</th></tr></thead><tbody>" >> "$1"
    cat "$SCRIPTDIR/emoji.json" \
      | jq -r '.[] | "<tr><td><code>" + .aliases[0] + "</code></td><td>" + .emoji + "</td></tr>"' \
      | sed -n "${from},${to}p" >> "$1"
    echo "</tbody></table></td>" >> "$1"
  done
  echo "</tr></table>" >> "$1"
else
  cat "$SCRIPTDIR/emoji.json" | jq -rc 'map({emoji: .emoji,aliases: .aliases})' > "$1"
fi
