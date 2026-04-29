#!/bin/bash -e

# test the AppImage built with build.sh
# again, this only works on aarch64

VERSION="5.16.0-rc1"

BOLD="\x1b[1m"
RED="\x1b[31m"
GREEN="\x1b[32m"
RESET="\x1b[0m"

# make sure we are root
if [ "$(id -u)" != 0 ]; then
	echo -e "${BOLD}${RED}This script must be run as root!${RESET}"
	exit 1
fi

# make sure no other luanti processes are running
if [ "$(ps aux | grep luanti | wc -l)" != 1 ]; then
	echo -e "${BOLD}${RED}No Luanti processes may be running while this script is run.${RESET}"
	exit 1
fi

# check if the AppImage even exists
echo -e "${BOLD}Checking if AppImage exists...${RESET}"

if [ ! -f luanti-${VERSION}-aarch64.AppImage ]; then
	echo -e "${BOLD}${RED}AppImage not found, have you run build.sh?${RESET}"
	exit 1
fi

# list of dependencies needed to make the AppImage
DEPS=(
	git
	g++
	make
	ninja-build
	libc6-dev
	cmake
	curl
	libpng-dev
	libjpeg-dev
	libxi-dev
	libgl1-mesa-dev
	libsqlite3-dev
	libogg-dev
	libvorbis-dev
	libopenal-dev
	libcurl4-openssl-dev
	libfreetype6-dev
	zlib1g-dev
	libgmp-dev
	libsdl2-dev
	libzstd-dev
	libleveldb-dev
	gettext
	desktop-file-utils
	ca-certificates
	file
)

# remove the dependencies
echo -e "${BOLD}Removing dependencies...${RESET}"

for d in "${DEPS[@]}"; do
	apt remove ${d} -y
done

# test the AppImage
echo -e "${BOLD}${GREEN}Testing AppImage in 5 seconds${RESET}"
sleep 5

./luanti-${VERSION}-aarch64.AppImage &

sleep 10

if [ "$(ps | grep luanti | wc -l)" == 0 ]; then
	echo -e "${BOLD}${RED}AppImage test failed.${RESET}"
	exit 1
fi

# kill luanti
pkill -9 luanti

echo -e "${BOLD}${GREEN}AppImage test sucessful.${RESET}"
echo -e "${BOLD}Reinstalling dependencies...${RESET}"

# reinstall the dependencies
for d in "${DEPS[@]}"; do
	apt-get install -y ${d}
done

exit 0
