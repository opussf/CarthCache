#!/bin/sh
# Perform a vital caching feature of Carthage

carthageCacheDir="/tmp/"

if [ ! -f Cartfile.resolved ]; then
	echo "----> Please run this where the Cartfile.resolved file is located."
	exit 1
fi

carthageParameters="--platform ios --no-use-binaries --cache-builds --verbose"

function wipeCarthage {
	# This wipes out the Carthage dir
	if [ -d Carthage ]; then
		echo "Carthage dir exists.  Delete it."
		rm -rf Carthage
	fi
}

function processCartfile {
	while IFS= read -r line
	do
		carthageZipfile="carthage_"`md5 -q -s "$line"`".tgz"
		carthageCacheFile="${carthageCacheDir}${carthageZipfile}"
		carthageDependencyType="$(cut -d' ' -f1 <<<"$line")"
		carthageDependency=`cut -d' ' -f2 <<<"$line" | sed 's/\"//g'`
		echo "Carthage line: $line"

		if [ $carthageDependencyType != "binary" ]; then  # only do this for a non-binary dependency
			echo "Asks to build: $carthageDependency"
			echo "Stored in    : $carthageZipfile"
			carthageDependency="$(cut -d'/' -f2 <<<"$carthageDependency")"
			if [ ! -f $carthageCacheFile ]; then # The cache of this project does not exist.
				echo "Cachefile    : Missing -> Build $carthageDependency"
				wipeCarthage  # Wipe the Carthage dir to have a clean package
				run=1         # Need to rerun after to get all the other dependencies back
				$(carthage bootstrap $carthageParameters $carthageDependency)
				tar -czf $carthageCacheFile Carthage
				echo "Cached in    : $carthageZipfile"
			else   # The cache file exists
				echo "Cachefile    : Found   -> Restore $carthageDependency from $carthageZipfile"
				tar -xzf $carthageCacheFile
			fi
		fi
		echo "=+=+=+=+=+=+=+=+=+="

	done < Cartfile.resolved
}

run=1
while [ "$run" == "1" ]; do
	run=0
	processCartfile
done
