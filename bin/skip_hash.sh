#!/bin/bash

SPECS_TO_SKIP_FILE=/opt/spack-environment/only-dependencies.json
SPACK_LOCK_FILE=/opt/spack-environment/spack.lock

# Do not skip anything if the file does not exist
# This means the helper script is called without --only-dependencies
if [ ! -f $SPECS_TO_SKIP_FILE ]; then
   exit 1
fi

SPECS_TO_SKIP=$(cat $SPECS_TO_SKIP_FILE)
HASHES_TO_SKIP=$(jq --raw-output --argjson specs "$SPECS_TO_SKIP" '."roots"[] | select(.spec | IN($specs[])).hash' ${SPACK_LOCK_FILE})

find_hash() {
    for h in ${HASHES_TO_SKIP[@]}
    do
    if [[ $1 == $h ]]; then
        return 0
    fi
    done

    return 1
}

find_hash $1
