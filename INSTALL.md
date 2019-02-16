
# COMPILING Oblige

## Dependencies

1. C++ compiler (GNU's G++) and associated tools
   * packages: `g++` `binutils`

2. GNU make
   * package: `make`

3. FLTK 1.3 
   * website: http://www.fltk.org/
   * package: `libfltk1.3-dev`
   * You may also need: `libxft-dev` `libxinerama-dev` `libjpeg-dev` `libpng-dev`

4. zlib
   * website: http://www.zlib.net/
   * package: `zlib1g-dev`

5. XDG Utils
   * (only needed for Linux, to install the desktop and icon files)
   * package: `xdg-utils`

## Linux Compilation

Assuming all those dependencies are met, then the following shell
command will build the Oblige binary. (The '>' is just the prompt)

    > make

## Windows Compilation

I personally compile the Win32 binaries on Linux using what's
called a "Cross Compiler".  That means I don't need to reboot
out of Linux in order to create the Win32 packages.

Sorry, but if you want to compile the Win32 binary under
Windows itself then you are on your own.

Assuming you have a working cross-compiler, like the "mingw32"
package in Debian or Ubuntu Linux, then the following command
will build the EXE:

    > make -f Makefile.xming


# INSTALLING Oblige

For a system-wide Linux installation you should run "make install"
as root (the superuser) after building, which installs the binary
program plus all the script and data files.  It also uses the XDG
tools to install a desktop file and icon, allowing Oblige to appear
in your system's applications menu -- though if this step fails,
Oblige will still work when invoked from the command line.



# MISCELLANEOUS NOTES

To build FLTK with the WIN32 cross-compiler:

1. read README.CMake.txt and copy the cross-compiling snippet in there to a file: Toolchain-mingw32.cmake

2. edit Toolchain-mingw32.cmake and set the proper paths for the cross-compiling tools (for me: i586-mingw32msvc)

3. `mkdir mingw ; cd mingw`

4. `cmake -DCMAKE_TOOLCHAIN_FILE=../Toolchain-mingw32.cmake CMAKE_BUILD_TYPE=Release -DOPTION_USE_GL=OFF -DOPTION_USE_THREADS=OFF`

5. make
   * Note that the build fails when it gets to some stuff which require FLUID to process some .fl files.  That doesn't matter since the needed libraries (in mingw/lib) have been built by then.
