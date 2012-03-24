#!/bin/bash

rebuild_config () {
    config="$1"
    hookdir="$2"
    if [ $# != 2 ]; then
      echo "BUG: rebuild_config called by $0 with incorrect # of parameters" >&2
      return 1
    fi

    magic_string="# Autogenerated from $0 via rebuild_config"
    magic_string_re="^# Autogenerated from ($0|.* via rebuild_config)"

    if [ -L "$config" ]; then
        echo "Error: $config is a symlink; won't overwrite." >&2
        return 1
    fi

    if [ -e "$config" ]; then
        if ! [ -s "$config" ]; then
            echo "# $config is empty"
        elif ! grep -Eq "$magic_string_re" "$config"; then
            cat <<EOF >&2
Error: can't find '$magic_string_re' in $config
Presumably hand-written so won't overwrite; please break into parts.
EOF
            return 1
        fi
    fi

    echo "# Rebuilding $config ..."

    cat <<EOF > "$config"
# Autogenerated from $0 via rebuild_config at `date`

EOF

    # Ensure we have $ZDOT_FIND_HOOKS; if this is being invoked from
    # be.sh then we probably don't.
    source $ZDOTDIR/.shared_env 

    # sort by filename not by path
    $ZDOT_FIND_HOOKS "$hookdir" | \
    sed 's/\(.\+\)\/\(.\+\)/\2 -%- \1\/\2/' | \
    sort -k1 | \
    sed 's/.* -%- //' | \
    while read conf; do
        echo "#   Appending $conf"
        # Allow for executable hooks, for generating content dynamically,
        # triggered by including a magic cookie in the hook file.
        if grep -q '%% Executable hook %%' "$conf"; then
            echo "# Output of $conf follows:" >> "$config"
            "$conf" >> "$config"
        else
            echo "# Include of $conf follows:" >> "$config"
            cat "$conf" >> "$config"
        fi
        echo >> "$config"
    done
}
