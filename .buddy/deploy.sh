#!/bin/bash

# Store the mr- environment name
export PANTHEON_ENV=$BUDDY_EXECUTION_BRANCH
export PANTHEON_SITE=${PANTHEON_SITE}


# Create a function for determining if a multidev exists
TERMINUS_DOES_MULTIDEV_EXIST()
{
    # Don't create dev for main because it always exists
    if [[ $BUDDY_EXECUTION_BRANCH == ${MAIN_BRANCH} ]]
    then
        return 0;
    fi

    # Stash a list of Pantheon multidev environments
    PANTHEON_MULTIDEV_LIST="$(terminus multidev:list ${PANTHEON_SITE} --format=list --field=id)"

    while read -r multiDev; do
        if [[ "${multiDev}" == "$1" ]]
        then
            return 0;
        fi
    done <<< "$PANTHEON_MULTIDEV_LIST"

    return 1;
}

if [[ $CIRCLE_BRANCH != "master" ]]
then
    echo 'export PANTHEON_ENV=$(echo ${PANTHEON_ENV} | tr '"'"'[:upper:]'"'"' '"'"'[:lower:]'"'"' | sed '"'"'s/[^0-9a-z-]//g'"'"' | cut -c -11 | sed '"'"'s/-$//'"'"')' >> $PANTHEON_ENV
else
	export PANTHEON_ENV = 'dev';
fi

# If the mutltidev doesn't exist
if ! TERMINUS_DOES_MULTIDEV_EXIST $BUDDY_EXECUTION_BRANCH
then
    # Create it with Terminus
    echo "No multidev for $BUDDY_EXECUTION_BRANCH found, creating one..."
    terminus multidev:create $PANTHEON_SITE.dev $PANTHEON_ENV --clone-content --yes
else
    echo "The multidev $BUDDY_EXECUTION_BRANCH already exists, skipping creating it..."
    cd .. && terminus build:env:push -n "$PANTHEON_SITE.$PANTHEON_ENV" --yes
fi