#!/bin/bash

SITE_DOMAIN_DIR="$1"
OUTPUT_DOMAIN_DIR="$2"
PREFIX_MATCH="$3"

IDENTICAL=1

function check_exists() {
	local reference_dir="$1"
	local check_dir="$2"
	for domain_file in "$reference_dir"/*; do
		domain_file_name=$(basename "$domain_file")

		if [[ "$domain_file_name" != $PREFIX_MATCH* ]]; then
			continue
		fi

		if [ ! -f "$check_dir/$domain_file_name" ]; then
			echo "File $domain_file_name exists in $reference_dir but not in $check_dir"
			IDENTICAL=0
		else
			echo "File $domain_file_name exists in both $reference_dir and $check_dir"
		fi
	done
}

# Validate all files with prefix exist in both directories
check_exists "$SITE_DOMAIN_DIR" "$OUTPUT_DOMAIN_DIR"
check_exists "$OUTPUT_DOMAIN_DIR" "$SITE_DOMAIN_DIR"

for domain_file in "$SITE_DOMAIN_DIR"/*; do
	domain_file_name=$(basename "$domain_file")
	if [[ "$domain_file_name" != $PREFIX_MATCH* ]]; then
		continue
	fi

	echo "Comparing $domain_file"

	if [ ! -f "$OUTPUT_DOMAIN_DIR/$domain_file_name" ]; then
		echo "File $domain_file_name exists in $SITE_DOMAIN_DIR but not in $OUTPUT_DOMAIN_DIR"
		IDENTICAL=0
		continue
	fi

	FILE_DIFF=$(diff -u "$SITE_DOMAIN_DIR/$domain_file_name" "$OUTPUT_DOMAIN_DIR/$domain_file_name")
	if [ -n "$FILE_DIFF" ]; then
		echo "Differences found in $domain_file_name:"
		echo "$FILE_DIFF"
		IDENTICAL=0
	fi
done

if [ $IDENTICAL -eq 1 ]; then
	echo "All files with prefix '$PREFIX_MATCH' are identical in both directories."
	exit 0
else
	echo "Some files with prefix '$PREFIX_MATCH' differ between the directories."
	exit 1
fi
