# Developing QGIS using Homebrew dependencies 

In addition to using this tap to install [QGIS development formulae](../Formula), you can also use it to fully set up a development environment for an externally built QGIS from a clone of the current [development (master) branch](https://github.com/qgis/QGIS) of the source code tree.

> Note: This setup, though heavily tested, is currently _experimental_ and may change.

For the terminally lazy, who are already comfortable with Homebrew, [jump to sample Terminal session](#terminal).

## Development Tools

This tutorial is based upon the following software:
* [Qt Creator](http://qt-project.org/downloads) for CMake/C++ development of ([core source](https://github.com/qgis/QGIS/tree/master/src) and [plugins](https://github.com/qgis/QGIS/tree/master/src/plugins))
* [PyCharm Community Edition](http://www.jetbrains.com/pycharm/download/) for Python development of ([PyQGIS plugins/apps](http://docs.qgis.org/testing/en/docs/pyqgis_developer_cookbook/), [Python unit tests](https://github.com/qgis/QGIS/tree/master/tests/src/python), [reStructuredText for documentation](https://github.com/qgis/QGIS-Documentation)).
* macOS XCode (download via Mac App Store and _launch at least once_) and Xcode Command Line Tools (run `xcode-select --install` after installing Xcode), for Homebrew and building QGIS source. QGIS's [CMake](http://www.cmake.org) build process uses generated build files for building QGIS source directly with the `clang` compiler, _not via Xcode project files_.

## Homebrew

See http://brew.sh and [Homebrew docs](https://github.com/Homebrew/brew/tree/master/docs) for info on installing Homebrew.

After Homebrew is installed run the following and fix everything that it mentions, if you can:
```sh
brew doctor
```

### Homebrew configuration

Homebrew now defaults to _auto-updating_ itself (runs `brew update`) upon *every* `brew install` invocation. While this can be handy for keeping up with the latest changes, it can also quickly break an existing build's linked-to libraries. Consider setting the `HOMEBREW_NO_AUTO_UPDATE` environment variable to turn this off, thereby forcing manual running of `brew update`:

```sh
export HOMEBREW_NO_AUTO_UPDATE=1
```

See end of `man brew` for other environment variables.

### Homebrew prefix

While all of the formulae and scripts support building QGIS using Homebrew installed to a non-standard prefix, e.g. `/opt/homebrew`, **do yourself a favor** (especially if you are new to Homebrew) and [install in the default directory of `/usr/local`](https://github.com/Homebrew/brew/blob/master/docs/Installation.md). QGIS has many dependencies which are available as ["bottles"](https://github.com/Homebrew/brew/blob/master/docs/Bottles.md) (pre-built binary installs) from the Homebrew project. Installing Homebrew to a non-standard prefix will force many of the bottled formulae to be built from source, since many of the available bottles are built specific to `/usr/local`. Such unnecessary building from source can comparatively take hours and hours more, depending upon your available CPU cores.

If desired, this setup supports QGIS builds where the dependencies are in a non-standard Homebrew location, e.g. `/opt/homebrew`, instead of `/usr/local`. This allows for multiple build scenarios, though often requires a more meticulous CMake configuration of QGIS.

You can programmatically find the prefix with `brew --prefix`. In formulae code, it is denoted with the HOMEBREW_PREFIX environment variable.

### Homebrew formula install prefixes

By default, Homebrew installs to a versioned prefix in the 'Cellar', e.g. `/usr/local/Cellar/gdal2/2.1.2/`. Using the versioned path for dependencies _might_ lead to it being hardcoded into the linking phase of your builds. This is an issue because the version can change often with formula changes that are unrelated to the actual dependency's version, e.g. `2.1.2_1`. When defining paths for CMake, always try the formula's 'opt prefix' first, e.g. `/usr/local/opt/gdal2`, which is a symbolic link that _always_ points to the latest versioned install prefix of the formula. This often avoids the issue, though some CMake find modules _may_ resolve the symbolic link back to the versioned install prefix.

### Install some basic formulae

Always read the 'Caveats' section output at the end of `brew info <formula>` or `brew install <formula>`. 

```sh
brew install bash-completion
brew install git
```

## Python Dependencies

### Select an interpreter

The first important decision to make is regarding whether to use Homebrew's or or another Python 3.x. Currently macOS does not ship with Python 3, and QGIS 3 should be built against Python 3.x.

> Note: The more Homebrew formulae you install from bottles, the higher likelihood you will end up running into a formulae that requires installing Homebrew's Python 3, since bottles are always built against that Python.

If using Homebrew Python 3.x, install with:

```sh
# review options
brew info python3
brew install python3 [--with-option ...]
```

Regardless of which Python interpreter you use, always ensure it is the first found `python3` on PATH in your Terminal session where you run `brew` commands, i.e. `which python3` points to the correct Python 3 you wish to use when building formulae.

### Install required Python packages

Use [pip3](https://pypi.python.org/pypi/pip/) that was installed against the same Python 3 you are using when installing formulae. You can also tap [homebrew/python](https://github.com/Homebrew/homebrew-python) for some more complex package installs.

Reference `pip3 --help` for info on usage (usually just `pip install <package>`).

* [future](https://pypi.python.org/pypi/future)
* [numpy](https://pypi.python.org/pypi/numpy)
* [psycopg2](https://pypi.python.org/pypi/psycopg2)
* [matplotlib](https://pypi.python.org/pypi/matplotlib)
* [pyparsing](https://pypi.python.org/pypi/pyparsing)
* [mock](https://pypi.python.org/pypi/mock)
* [pyyaml](https://pypi.python.org/pypi/PyYAML)
* [nose2](https://pypi.python.org/pypi/nose2)

Other Python packages **automatically installed** by Homebrew from QGIS dependencies:

* [sip](https://github.com/Homebrew/homebrew-core/blob/master/Formula/sip.rb)
* [PyQt5](https://github.com/Homebrew/homebrew-core/blob/master/Formula/pyqt5.rb)
* [QScintilla2](https://github.com/Homebrew/homebrew-core/blob/master/Formula/qscintilla2.rb)
* [pyspatialite](https://github.com/OSGeo/homebrew-osgeo4mac/blob/master/Formula/pyspatialite.rb) (deprecated)
* [`osgeo.gdal` and `osgeo.ogr`, etc.](https://github.com/OSGeo/homebrew-osgeo4mac/blob/master/Formula/gdal2.rb)

## Install Build and Linked Library Dependencies

### Install dependencies from QGIS formulae

> Note: substitute **`qgis3-xx`** for whatever QGIS formula you are using for dependencies, e.g. `qgis3-dev`.

```sh
# add this tap
brew tap qgis/qgisdev
# review options
brew info qgis3-xx
# see what dependencies will be included
brew deps --tree qgis3-xx [--with[out]-some-option ...]
# install dependencies, but not QGIS
brew install qgis3-xx --only-dependencies [--with[out]-some-option ...]
```

You do not have to actually do `brew install qgis3-xx` unless you also want that version installed. If you do have QGIS 3 formulae installed, and are planning on _installing_ your development build (not just running from the build directory), you should unlink the formulae installs, e.g.:

```sh
brew unlink qgis3-xx
```

This will ensure the `qgis.core`, etc. Python modules of the formula(e) installs are not overwritten by the development build upon `make install`. All `qgis-xx` formulae QGIS applications will run just fine from their Cellar keg install directory. _Careful_, though, as multiple QGIS installs will probably all share the same application preference files; so, don't run them concurrently.

### Optional External Dependencies

The [Processing framework](http://docs.qgis.org/testing/en/docs/user_manual/processing/index.html) of QGIS can leverage many external geospatial applications and utilities, which _do not_ need to be built as dependencies prior to building QGIS:

* [`grass7`](https://github.com/OSGeo/homebrew-osgeo4mac/blob/master/Formula/grass7.rb) (`--with-grass` option) - [GRASS 7](http://grass.osgeo.org), which is also used by the GRASS core plugin in QGIS
* [`orfeo5`](https://github.com/OSGeo/homebrew-osgeo4mac/blob/master/Formula/orfeo5.rb) (`--with-orfeo5` option) - [Orfeo Toolbox](http://orfeo-toolbox.org/otb/)
* [`r`](http://www.r-project.org/) (`--with-r` option) - [R Project](http://www.r-project.org/)
* [`saga-gis`](https://github.com/OSGeo/homebrew-osgeo4mac/blob/master/Formula/saga-gis.rb) (`--with-saga-gis` option) - [System for Automated Geoscientific Analyses](http://www.saga-gis.org)
* [`taudem`](https://github.com/OSGeo/homebrew-osgeo4mac/blob/master/Formula/taudem.rb) - [Terrain Analysis Using Digital Elevation Models](http://hydrology.usu.edu/taudem/taudem5/index.html).

The `gpsbabel` formula can be installed as a dependency, though you may have to define the path to its binary when using QGIS's [GPS Tools](http://docs.qgis.org/testing/en/docs/user_manual/working_with_gps/plugins_gps.html).

> Note: if you install Processing external utilities _after_ installing a QGIS formula or building your own QGIS, you may need to configure the individual utility's paths in Processing's options dialog. 

## Clone QGIS Source

See the QGIS [INSTALL](https://github.com/qgis/QGIS/blob/master/INSTALL) document for information on using git to clone the source tree.

QGIS's build setup uses CMake, which supports 'out-of-source' build directories. It is recommended to create a separate build directory, either within the source tree, or outside of it. Since the (re)build process can generate _many_ files, consider creating a separate partition on which to place the build directory. Such a setup can significantly reduce fragmentation on your main startup drive. Use of Solid State Disks is recommended.

## Customize Build Scripts

This tap offers several convenience scripts for use in Qt Creator, or wrapper build scripts, to aid in building/installing QGIS, located at:

```sh
$(brew --prefix)/Homebrew/Library/Taps/qgis/homebrew-qgisdev/scripts
```

> Note: **Copy the directory elsewhere** and use it from there. It's important to not edit the scripts where they are located, in the tap, because it is a git repository. You should keep that working tree clean so that `brew update` always works.

The scripts will be used when configuring/building/installing the QGIS project in Qt Creator, or can be used independent of Qt Creator.

### Open and review scripts

> Note: scripts expect the HOMEBREW_PREFIX environment variable to be set, e.g. in your `.bash_profile`:

  ```sh
  # after prepending `brew --prefix` to PATH (not needed for default /usr/local Homebrew)
  export HOMEBREW_PREFIX=$(brew --prefix)
  ```

* [qgis-cmake-setup.sh](../scripts/qgis-cmake-setup.sh) - For generating CMake option string for use in Qt Creator (or build scripts) when built off dependencies from this and other taps. Edit CMake options to suit your build needs. Note, the current script usually has CMake options for building QGIS with *most* core options that the current `qgis3-xx` Homebrew formula supports, which may not include things like Oracle support, etc. You will probably want to edit it and (un)comment out such lines for an initial build. 

* [qgis-set-app-env.py](../scripts/qgis-set-app-env.py) - For setting env vars in dev build and installed QGIS.app, to ensure they are available on double-click run. _Needs to stay in the same directory as the next scripts._ Generally, you will not need to edit this script.

* [qgis-dev-build.sh](../scripts/qgis-dev-build.sh) - Sets up the build environ and ensures the QGIS.app in the build directory can find resources, so it can run from there.

* [qgis-dev-install.sh](../scripts/qgis-dev-install.sh) - Installs the app and ensures QGIS.app has proper environment variables, so it can be moved around on the filesystem. Currently, QGIS.app bundling beyond [QGIS_MACAPP_BUNDLE=0](https://github.com/qgis/QGIS/tree/master/mac) is not supported. Since all dependencies are in your `HOMEBREW_PREFIX`, _no complex bundling is necessary_, unless you intend to relocate the built app to another Mac (which is a planned feature).

## <a name="terminal"></a>Configure/build/install QGIS in a Terminal.app session

**Example** Terminal.app session for cloning and building QGIS from scratch, based off of `qgis-3-dev` formula dependencies and assuming Xcode.app, Xcode Command Line Tools, and Homebrew are _already installed_. BASH used here.

```sh
# Setup environment variables
export HOMEBREW_PREFIX=$(brew --prefix)
export HOMEBREW_NO_AUTO_UPDATE=1

# Optionally update Homebrew (recommended)
brew update

# Install some handy base formulae
brew install bash-completion
brew install git
brew install cmake

# Decide to use recommended Homebrew's Python3
# (could use Anaconda's Python 3, etc. instead, though bottles may not work)
brew install python3

# Install some Python dependencies
# NOTE: may require `sudo` if Python 3 is installed in a root-owned location 
pip3 install future numpy psycopg2 matplotlib pyparsing pyyaml mock nose2

# Add some useful Homebrew taps
# NOTE: try to avoid tapping homebrew/boneyard
brew tap homebrew/science
brew tap homebrew/python
brew tap qgis/qgisdev
brew tap osgeo/osgeo4mac

# Make sure deprecated Qt4 formulae are not linked
brew unlink qt
brew unlink pyqt

# Install and verify GDAL/OGR with decent driver support
# Do NOT install `gdal` (1.11.x) formula, unless you truely need it otherwise
# NOTE: keg-only, e.g. only available from HOMEBREW_PREFIX/opt/gdal2 prefix
brew install osgeo/osgeo4mac/gdal2 --with-complete --with-libkml --with-python3
brew test osgeo/osgeo4mac/gdal2

# If failure, review any .dylib errors when loading drivers (scroll to top of output)
$HOMEBREW_PREFIX/opt/gdal2/bin/gdalinfo --formats
$HOMEBREW_PREFIX/opt/gdal2/bin/ogrinfo --formats

# Optionally add and verify Processing framework extra utilities
brew install osgeo/osgeo4mac/grass7
brew install osgeo/osgeo4mac/gdal2-grass7
brew test osgeo/osgeo4mac/grass7
brew test osgeo/osgeo4mac/gdal2-grass7

brew install osgeo/osgeo4mac/saga-gis --with-app
brew test osgeo/osgeo4mac/saga-gis

# This one's huge, bringing in large dependencies
brew install orfeo5
brew test orfeo5

# Install remaining dependencies for qgis3-dev formula, but not QGIS
# This may take a loooong time if there are missing bottles, which need built
brew install qgis3-dev --only-dependencies [--with-other-options]

# Base directory path of src, install and build directories
BASE_DIR=$HOME/src
mkdir -p $BASE_DIR
cd $BASE_DIR

# Create and save a directory to install a final QGIS.app
QGIS_INSTALL=$BASE_DIR/QGIS_install
mkdir -p $QGIS_INSTALL

# Clone QGIS source tree
QGIS_SRC=$BASE_DIR/QGIS
# This may take a looong time, depending upon connection speed
git clone https://github.com/qgis/QGIS.git $QGIS_SRC
cd $QGIS_SRC

# Setup out-of-source build directory, inside of QGIS tree
BUILD_DIR=$BASE_DIR/QGIS/build
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Where you have copied the build scripts (here using the defaults, as is)
BUILD_SCRIPTS=$(brew --repository qgis/qgisdev)/scripts

# Configure CMake and generate build files
# usage: qgis-cmake-setup.sh 'source directory' 'build directory' 'install directory'
#        (directories need to absolute paths)
$BUILD_SCRIPTS/qgis-cmake-setup.sh $QGIS_SRC $BUILD_DIR $QGIS_INSTALL

# Review or edit what was configured (almost all dependencies should be from Homebrew)
ccmake $BUILD_DIR

# Build QGIS
# usage: qgis-dev-build.sh 'absolute path to build directory'
$BUILD_SCRIPTS/qgis-dev-build.sh $BUILD_DIR

# Run QGIS test suite from build directory
# source environment and run tests inside of a bash subshell, 
#   so your shell environment is not polluted
( source $BUILD_SCRIPTS/qgis-dev.env $BUILD_DIR && ctest )

# Install QGIS.app
# note: app bundle is moveable about the filesystem, but not to another Mac
$BUILD_SCRIPTS/qgis-dev-install.sh $BUILD_DIR
```

## Configure/build/install QGIS in Qt Creator.app

TODO
