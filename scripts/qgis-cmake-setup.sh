#!/bin/bash

#***************************************************************************
# Script for CMake configure and generation setup prior to use in Qt
# Creator with dev builds and installs of QGIS when built off dependencies
# from Homebrew project
#                              -------------------
#        begin    : November 2016
#        copyright: (C) 2016 Larry Shaffer
#        email    : larrys at dakotacarto dot com
# ***************************************************************************/
#
#/***************************************************************************
# *                                                                         *
# *   This program is free software; you can redistribute it and/or modify  *
# *   it under the terms of the GNU General Public License as published by  *
# *   the Free Software Foundation; either version 2 of the License, or     *
# *   (at your option) any later version.                                   *
# *                                                                         *
# ***************************************************************************/

# exit on errors
set -e

usage(){
  echo "usage: <script> 'source directory' 'build directory' 'install directory'"
  echo "       (directories must exist and be provided as absolute paths)"
  exit 1
}

if [ "$#" -ne 3 ]; then
  usage
fi

SRC_DIR="${1}"
BUILD_DIR="${2}"
INSTALL_DIR="${3}"

if ! [[ "$SRC_DIR" = /* ]] || ! [ -d "$SRC_DIR" ]; then
  usage
fi

if ! [[ "$BUILD_DIR" = /* ]] || ! [ -d "$BUILD_DIR" ]; then
  usage
fi

if ! [[ "$INSTALL_DIR" = /* ]] || ! [ -d "$INSTALL_DIR" ]; then
  usage
fi

if ! (which -s cmake); then
  echo "CMake executable 'cmake' not found in \$PATH"
  exit 1
fi

# parent directory of script
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd -P)

# if HOMEBREW_PREFIX undefined in env, then set to standard prefix
if [ -z "$HOMEBREW_PREFIX" ]; then
  HB=$(brew --prefix)
else
  HB=$HOMEBREW_PREFIX
fi

if [ -L $HB/var/homebrew/linked/qt ]; then
  echo 'Unlink Qt4 Homebrew formula: `brew unlink qt`'
  exit 1
fi

if [ -L $HB/var/homebrew/linked/pyqt ]; then
  echo 'Unlink PyQt4 Homebrew formula: `brew unlink pyqt`'
  exit 1
fi

# comment this out if you don't what to clear existing build files
rm -Rf $BUILD_DIR/*

cd $BUILD_DIR

if (which -s ninja); then
  CMAKE_GENERATOR='Ninja'
else
  CMAKE_GENERATOR='Unix\ Makefiles'
fi

echo "CMake generator: ${CMAKE_GENERATOR}"

# cmake options
cmd="cmake"

cmd+=" -G ${CMAKE_GENERATOR}"
cmd+=" -DCMAKE_INSTALL_PREFIX:PATH='${INSTALL_DIR}'"
cmd+=" -DCMAKE_BUILD_TYPE:STRING=RelWithDebInfo"
cmd+=" -DCMAKE_FIND_FRAMEWORK:STRING=LAST"
cmd+=" -DCMAKE_PREFIX_PATH:STRING='$HB/opt/qt5;$HB/opt/qt5-webkit;"\
"$HB/opt/gdal2;$HB/opt/expat;$HB/opt/sqlite;$HB/opt/flex;$HB/opt/bison'"

# testing options
cmd+=" -DENABLE_MODELTEST:BOOL=FALSE"
cmd+=" -DENABLE_TESTS:BOOL=TRUE"

# dependency options
cmd+=" -DGDAL_LIBRARY:FILEPATH=$HB/opt/gdal2/lib/libgdal.dylib"
cmd+=" -DGEOS_LIBRARY:FILEPATH=$HB/opt/geos/lib/libgeos_c.dylib"
cmd+=" -DGSL_CONFIG:FILEPATH=$HB/opt/gsl/bin/gsl-config"
cmd+=" -DGSL_INCLUDE_DIR:PATH=$HB/opt/gsl/include"
cmd+=" -DGSL_LIBRARIES:STRING='-L$HB/opt/gsl/lib -lgsl -lgslcblas'"
cmd+=" -DWITH_QWTPOLAR:BOOL=TRUE"
cmd+=" -DWITH_INTERNAL_QWTPOLAR:BOOL=FALSE"

# GRASS7 C++ plugin
cmd+=" -DWITH_GRASS:BOOL=FALSE" # this is for GRASS6
cmd+=" -DWITH_GRASS7:BOOL=TRUE"
cmd+=" -DGRASS_PREFIX7:PATH=$HB/opt/grass7/grass-base"

# boolean options
cmd+=" -DWITH_APIDOC:BOOL=FALSE"
cmd+=" -DWITH_ASTYLE:BOOL=TRUE"
cmd+=" -DWITH_CUSTOM_WIDGETS:BOOL=TRUE"
cmd+=" -DWITH_GLOBE:BOOL=FALSE"
cmd+=" -DWITH_ORACLE:BOOL=FALSE"
cmd+=" -DWITH_QSCIAPI:BOOL=FALSE"
cmd+=" -DWITH_QSPATIALITE:BOOL=FALSE"
cmd+=" -DWITH_QTWEBKIT:BOOL=TRUE"
cmd+=" -DWITH_SERVER:BOOL=TRUE"
cmd+=" -DWITH_STAGED_PLUGINS:BOOL=TRUE"

# macOS options
# cmd+=" -DQGIS_MACAPP_DEV_PREFIX:PATH="$BUILD_DIR/qgis-dev""
# cmd+=" -DQGIS_MACAPP_INSTALL_DEV:BOOL=TRUE"
cmd+=" -DQGIS_MACAPP_BUNDLE:STRING=0"

# cmd+=" -Wno-dev"
# cmd+=" -DCMAKE_C_FLAGS_RELEASE:STRING=-DNDEBUG"
# cmd+=" -DCMAKE_CXX_FLAGS_RELEASE:STRING=-DNDEBUG"
# cmd+=" -DCMAKE_CXX_FLAGS:STRING=-I$HB/opt/gettext/include"
# cmd+=" -DCMAKE_VERBOSE_MAKEFILE:BOOL=TRUE"
# cmd+=" -DSUPPRESS_QT_WARNINGS:BOOL=TRUE"

# cmd+=" -DBISON_EXECUTABLE:FILEPATH=$HB/opt/bison/bin/bison"
# cmd+=" -DFCGI_INCLUDE_DIR:PATH=$HB/opt/fcgi/include"
# cmd+=" -DFCGI_LIBRARY:FILEPATH=$HB/opt/fcgi/lib/libfcgi.dylib"
# cmd+=" -DFLEX_EXECUTABLE:FILEPATH=$HB/opt/flex/bin/flex"
# cmd+=" -DGDAL_INCLUDE_DIR:PATH=$HB/opt/gdal2/include"
# cmd+=" -DGDAL_LIBRARY:FILEPATH=$HB/opt/gdal2/lib/libgdal.dylib"
# cmd+=" -DGEOS_INCLUDE_DIR:PATH=$HB/opt/geos/include"
# cmd+=" -DGSL_INCLUDE_DIR:PATH=$HB/opt/gsl/include"
# cmd+=" -DPOSTGRES_CONFIG:FILEPATH=$HB/opt/postgresql/bin/pg_config"
# cmd+=" -DPROJ_INCLUDE_DIR:PATH=$HB/opt/proj/include"
# cmd+=" -DPYTHON_EXECUTABLE:FILEPATH=$HB/bin/python3"
# cmd+=" -DQCA_INCLUDE_DIR:PATH=$HB/opt/qca/lib/qca-qt5.framework/Headers"
# cmd+=" -DQSCI_SIP_DIR:PATH=$HB/opt/qscintilla2/share/sip"
# cmd+=" -DQSCINTILLA_INCLUDE_DIR:PATH=$HB/opt/qscintilla2/include"
# cmd+=" -DQSCINTILLA_LIBRARY:FILEPATH=$HB/opt/qscintilla2/lib/libqscintilla2.dylib"
# cmd+=" -DQWT_INCLUDE_DIR:PATH=$HB/opt/qwt/lib/qwt.framework/Headers"
# cmd+=" -DQWT_LIBRARY:FILEPATH=$HB/opt/qwt/lib/qwt.framework/qwt"
# cmd+=" -DSPATIALINDEX_INCLUDE_DIR:PATH=$HB/opt/spatialindex/include/spatialindex"
# cmd+=" -DSPATIALITE_INCLUDE_DIR:PATH=$HB/opt/libspatialite/include"
# cmd+=" -DSQLITE3_INCLUDE_DIR:PATH=$HB/opt/sqlite/include"

cmd+=" '${SRC_DIR}'"

#echo $cmd
eval $cmd

