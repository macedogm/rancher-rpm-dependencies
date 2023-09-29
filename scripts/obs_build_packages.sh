#!/bin/bash

set -eu

OBS_PACKAGE_CONFIG="package_meta.xml"
# TODO - improvement - get the home from the oscrc file when running local test builds
OBS_PROJECT="home:gmacedo:rancher:devel:deps"
CONFIG_FILES=("_service" ".spec" "package_meta.xml")
MISSING_FILES=()
PKG_DIRS=()
WKD_DIR="$(pwd)"
PR_NUMBER="-local_build"
MODIFIED_DIRS=$(git diff --name-status --no-renames origin/main~ | sed -n -e "s,^[^D].*\(rancher/packages/[^/]*\).*,\1,p" | sort -u)

if [ -v GITHUB_REF_NAME ]; then
	if [ "$GITHUB_REF_NAME" == "main" ]; then
		OBS_PROJECT="home:gmacedo:rancher:deps"
		PR_NUMBER=""
	else
		PR_NUMBER="-pr_$(echo $GITHUB_REF_NAME | sed 's/^\([0-9]\+\)\/merge$/\1/')"
	fi
fi

for d in ${MODIFIED_DIRS[@]}; do
	pkg_dir="$WKD_DIR/$d"
	cd "$pkg_dir"

	ok_dir=true
	for f in "${CONFIG_FILES[@]}"; do
		if ! test -f *"$f"; then
			MISSING_FILES+=("$d/$f")
			ok_dir=false
		fi
	done

	if test "$ok_dir" = true; then
		PKG_DIRS+=("$pkg_dir")
	fi

	cd "$WKD_DIR"
done

if [ "${#MISSING_FILES[@]}" -ne 0 ]; then
	echo "==> The following needed config files are missing, please add before proceeding"
	echo "${MISSING_FILES[@]}" | sed "s/ /\n/g"
	exit 1
fi

if [ "${#PKG_DIRS[@]}" -eq 0 ]; then
	echo "==> No new package to add"
	exit 0
fi

for f in ${PKG_DIRS[@]}; do
	f="$f/$OBS_PACKAGE_CONFIG"
 	package_name=$(grep -Po '<package name="\K.*?(?=")' "$f")

	package_name_pr_id="${package_name}${PR_NUMBER}"
	pkg_dir=$(dirname "$f")

	tmp_dir="$(mktemp -d -p .)"
	cd "$tmp_dir"

	sed "s/<package\s\+name=\"$package_name\"/<package name=\"$package_name_pr_id\"/" "$f" > pkg.xml

	echo "==> Creating/updating package $package_name"
	osc meta pkg -F pkg.xml "$OBS_PROJECT" "$package_name_pr_id"
	osc init "$OBS_PROJECT" "$package_name_pr_id"

	mkdir -p "$package_name"
	osc co -o "$package_name" "$OBS_PROJECT" "$package_name_pr_id"
	cd "$package_name"

	cp "$pkg_dir"/* .
	# TODO remove the old generated versioned tar.xz files
	ls -lha
	cat helm.spec


	echo "==> Downloading artifacts"
	osc service manualrun

	echo "==> Listing files that were created/deleted/modified"
	osc st
	osc ar

	if [ -v GITHUB_REF ]; then
		echo "==> Submitting $package_name"
		osc ci -m "committing $package_name"
	else
		echo "==> This is a local build - $package_name will not be submitted"
		osc rdelete -m "deleting project" -r "$OBS_PROJECT" "$package_name_pr_id"
	fi

	cd "$WKD_DIR"
	echo "==> Removing temporary working files"
	rm -rf .osc "$tmp_dir"
	echo ""
done

