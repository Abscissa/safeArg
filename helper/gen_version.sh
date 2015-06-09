#!/bin/sh
gitver=$(git describe) || gitver=unknown
echo "module safearg.version_;" > src/safearg/version_.d
echo "enum appVersion = \"$gitver\";" >> src/safearg/version_.d
