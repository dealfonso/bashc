#!/bin/bash
#
# DoSH - Docker SHell
# https://github.com/grycap/dosh
#
# Copyright (C) GRyCAP - I3M - UPV 
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
#

SRCFOLDER=$1
if [ "$SRCFOLDER" == "" ]; then
  SRCFOLDER="."
fi

source "$SRCFOLDER/appname"
if [ $? -ne 0 -o "$APPNAME" == "" ]; then
  echo "could not find the name of the application"
  exit 1
fi

source "$SRCFOLDER/version"
if [ $? -ne 0 -o "$VERSION" == "" ]; then
  echo "could not find the version for the package"
  exit 1
fi

MANFOLDER="$SRCFOLDER/doc/man"
if [ ! -d "$MANFOLDER" ]; then
  MANFOLDER=
fi

REVISION=${VERSION##*-}
VERSION=${VERSION%%-*}

FNAME=build/${APPNAME}-${VERSION}
rm -rf "$FNAME"

${SRCFOLDER}/INSTALL.sh "${SRCFOLDER}" "${FNAME}"

tar czf ${APPNAME}-${VERSION}.tar.gz -C build ${APPNAME}-${VERSION}
TARFILES="$(tar tf ${APPNAME}-${VERSION}.tar.gz | sed "s/${APPNAME}-${VERSION}//g" | sed '/\/$/d')"

cat > ${APPNAME}.spec <<EOF
%define version $VERSION
%define revision $REVISION
Summary:        bashkeleton - skeleton of a bash application
License:        Apache 2.0
Name:           ${APPNAME}
EOF

cat >> ${APPNAME}.spec <<\EOF
Version:        %{version}
Release:        %{revision}
Group:          System Environment
URL:            https://github.com/dealfonso/bashkeleton
Packager:       Carlos A. <caralla@upv.es>
Requires:       bash, tar, coreutils, glibc-common
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch

%description 
 skeleton of a bash application 

%prep
%setup -q
%build

%install
mkdir -p $RPM_BUILD_ROOT
cp -r * $RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%post

%postun

EOF
cat >> ${APPNAME}.spec <<EOF
%files
%defattr(-,root,root,755)
$(echo "$TARFILES" | grep -v '^/etc' | grep '/bin/')
%defattr(-,root,root,644)
$(echo "$TARFILES" | grep -v '^/etc' | grep -v '/bin/')
EOF

if [ "$(ls $FNAME/etc)" != "" ]; then
cat >> ${APPNAME}.spec <<EOF
%config
$(echo "$TARFILES" | grep '^/etc' | grep -v '/bin/')
EOF
fi

cp ${APPNAME}-${VERSION}.tar.gz ~/rpmbuild/SOURCES/
rpmbuild -ba ${APPNAME}.spec
cp ~/rpmbuild/RPMS/noarch/${APPNAME}-${VERSION}-${REVISION}.noarch.rpm .