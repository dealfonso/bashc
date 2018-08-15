#!/bin/bash
#
# bashkeleton - Skeleton for Bash applications
# https://github.com/dealfonso/bashkeleton
#
# Copyright (C) caralla@upv.es
# Developed by Carlos A. caralla@upv.es
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# USAGE:
# This script will be called as 
#
# ./INSTALL <src folder> <prefix>
#
# It will install the application into the folder <prefix>. If you want to
#   make a system-wide installation, please include / as prefix. The purpose
#   of using a prefix is mainly to generate packages.
#
# CONFIGURATION:
#
# Update the following values for the files that implement your package

# Files that will be bashflattened to get a single file without dependencies 
#   (i.e. will try to remove "source" dependencies of the scripts). These
#   files will be copied to <PREFIX>/usr/share/$APPNAME folder
APPBASHFLATTEN=""

# Files that will be copied as-is to <PREFIX>/usr/share/$APPNAME folder
APPFILES="version LICENSE"

# Files that will be copied as-is to <PREFIX>/usr/bin folder
APPBINFILES=""

# Files that will be bashflattened to get a single file without dependencies 
#   (i.e. will try to remove "source" dependencies of the scripts). These
#   files will be copied to <PREFIX>/usr/bin folder
APPBASHFLATTENBINFILES="bashkeleton"

# ---------------------------------------------------------------------
# DO NOT MODIFY from here on
# ---------------------------------------------------------------------

function _chmod() {
  local RECURSE="$1"
  local MODE
  if [ "$RECURSE" == "-R" ]; then
    shift
    MODE="$1"
  else
    MODE="$RECURSE"
    RECURSE=
  fi
  shift
  if [ "$1" != "" ]; then
    chmod $RECURSE "$MODE" "$@"
  fi
}

SRCFOLDER="${1:-.}"
PREFIX="${2:-/}"

source "${SRCFOLDER}/appname"
if [ $? -ne 0 -o "$APPNAME" == "" ]; then
  echo "could not find the name of the application"
  exit 1
fi

APPDIR="/usr/share/$APPNAME"
ETCDIR="/etc/$APPNAME"

mkdir -p "${PREFIX}/usr/bin"
mkdir -p "${PREFIX}/$APPDIR"
mkdir -p "${PREFIX}/${ETCDIR}"

for i in $APPFILES; do
  D="$(dirname $i)"
  if [ "$D" == ".." -o "$D" == "." ]; then
    D=
  fi
  D="${PREFIX}/$APPDIR/$D"
  mkdir -p "$D"
  cp -r "$SRCFOLDER/$i" "$D"
done

for i in $APPBASHFLATTEN; do
  F="$(basename "$i")"
  ${SRCFOLDER}/bashflatten -C "${SRCFOLDER}/$i" > "${PREFIX}/$APPDIR/$F" 
done

for i in $APPBINFILES; do
  cp -r "$SRCFOLDER/$i" "${PREFIX}/usr/bin/"
  _chmod -R 755 "${PREFIX}/usr/bin/$i"
done

for i in $APPBASHFLATTENBINFILES; do
  F="$(basename "$i")"
  ${SRCFOLDER}/bashflatten -C "${SRCFOLDER}/$i" > "${PREFIX}/usr/bin/$F" 
  _chmod 755 "${PREFIX}/usr/bin/$F"
done

APPETCFILES="etc/$APPNAME"
for i in "$APPETCFILES"; do
  D="$(dirname $i)"
  if [ "$D" == ".." -o "$D" == "." ]; then
    D=
  fi
  if [ -e "$SRCFOLDER/$i" ]; then
    D="${PREFIX}/$D"
    mkdir -p "$D"
    cp -r "$SRCFOLDER/$i" "$D"
  fi
done

if [ "$PREFIX" != "/" ]; then
  _chmod 755 ${PREFIX}/etc
fi

_chmod 755 $(find ${PREFIX}/${ETCDIR} -type d)
_chmod 644 $(find ${PREFIX}/${ETCDIR} ! -type d)
_chmod 755 ${PREFIX}/$APPDIR
_chmod 755 $(find ${PREFIX}/$APPDIR/ -type d)
_chmod 644 $(find ${PREFIX}/$APPDIR/ ! -type d)
