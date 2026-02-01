#!/bin/bash -e

# run this script on an aarch64 computer, running modern debian or
#    something similar, otherwise it's not going to work...

VERSION="5.15.0"

BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
RESET="\033[0m"

# make sure we are root
if [ "$(id -u)" != 0 ]; then
	echo -e "${BOLD}${RED}This script must be run as root!${RESET}"
	exit 1
fi

# install deps
echo -e "${BOLD}Downloading deps...${RESET}"
apt-get install -y --no-install-recommends \
	git \
	g++ \
	make \
	ninja-build \
	libc6-dev \
	cmake \
	curl \
	libpng-dev \
	libjpeg-dev \
	libxi-dev \
	libgl1-mesa-dev \
	libsqlite3-dev \
	libogg-dev \
	libvorbis-dev \
	libopenal-dev \
	libcurl4-openssl-dev \
	libfreetype6-dev \
	zlib1g-dev \
	libgmp-dev \
	libsdl2-dev \
	libzstd-dev \
	libleveldb-dev \
	gettext \
	desktop-file-utils \
	ca-certificates \
	file

# download source code
echo -e "${BOLD}Downloading LuaJIT and Luanti source code...${RESET}"
git clone --depth 1 https://github.com/LuaJIT/LuaJIT.git luajit
curl -Lo luanti.zip https://github.com/luanti-org/luanti/archive/refs/tags/${VERSION}.zip
unzip luanti.zip
mv luanti-${VERSION} luanti/

# compile luajit
echo -e "${BOLD}Compiling LuaJIT...${RESET}"
cd luajit
make amalg -j$(nproc)
cd ..

# prepare to compile luanti
cd luanti
mkdir -p build
cd build

echo -e "${BOLD}Downloading AppImageTool${RESET}"
curl -Lo appimagetool https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-aarch64.AppImage
chmod +x appimagetool

# compile and install into AppDir
echo -e "${BOLD}Compiling Luanti...${RESET}"
cmake .. -G Ninja \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=AppDir/usr \
	-DBUILD_UNITTESTS=OFF \
	-DENABLE_SYSTEM_JSONCPP=OFF \
	-DLUA_INCLUDE_DIR=../../luajit/src/ \
	-DLUA_LIBRARY=../../luajit/src/libluajit.a

ninja install -j$(nproc)

# build the appimage itself
cd AppDir

echo -e "${BOLD}Building AppImage...${RESET}"
# put desktop and icon at root
ln -sf usr/share/applications/org.luanti.luanti.desktop luanti.desktop
ln -sf usr/share/icons/hicolor/128x128/apps/luanti.png luanti.png
ln -sf luanti.png .DirIcon

# fix locales
mv usr/share/locale usr/share/luanti

cat > AppRun <<'APPRUN'
#!/bin/sh
APP_PATH="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${APP_PATH}"/usr/lib/:"${LD_LIBRARY_PATH}"
exec "${APP_PATH}/usr/bin/luanti" "$@"
APPRUN
chmod +x AppRun

# bundle the libraries
INCLUDE_LIBS=(
	libopenal.so.1
	libSDL2-2.0.so.0
	 libsndio.so.7.0
	  libbsd.so.0
	   libmd.so.0
	libjpeg.so.62
	libpng16.so.16
	libvorbisfile.so.3
	 libogg.so.0
	 libvorbis.so.0
	libzstd.so.1
	libsqlite3.so.0
	libleveldb.so.1d
	 libsnappy.so.1
)

mkdir -p usr/lib/
for i in "${INCLUDE_LIBS[@]}"; do
	cp /usr/lib/aarch64-linux-gnu/$i usr/lib/
done

# finally make the appimage
cd ..
ARCH=aarch64 ./appimagetool --appimage-extract-and-run AppDir/

# move the appimage to this script's folder
mv Luanti-aarch64.AppImage ../../luanti-${VERSION}-aarch64.AppImage

# clean up
cd ../..

rm -rf luanti{,.zip}
rm -rf luajit/

# done :D
echo -e "${BOLD}${GREEN}Done!${RESET}"
