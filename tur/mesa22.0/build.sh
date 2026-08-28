TERMUX_PKG_HOMEPAGE=https://www.mesa3d.org
TERMUX_PKG_DESCRIPTION="An open-source implementation of the OpenGL specification"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_LICENSE_FILE="docs/license.rst"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION=22.0.5
TERMUX_PKG_SRCURL=https://archive.mesa3d.org/older-versions/${TERMUX_PKG_VERSION%%.*}.x/mesa-${TERMUX_PKG_VERSION}.tar.xz
TERMUX_PKG_SHA256=5ee2dc06eff19e19b2867f12eb0db0905c9691c07974f6253f2f1443df4c7a35
TERMUX_PKG_DEPENDS="libandroid-shmem, libc++, libdrm, libexpat, libglvnd, libx11, libxext, libxfixes, libxshmfence, libxxf86vm, ncurses, vulkan-loader, xorg-xrandr, zlib, zstd"
TERMUX_PKG_BUILD_DEPENDS="libllvm-11-static, libglvnd-dev, xorgproto, vulkan-headers"

TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--cmake-prefix-path ${TERMUX__PREFIX__OPT_DIR}/libllvm-11;${TERMUX_PREFIX}
--prefix ${TERMUX__PREFIX__OPT_DIR}/${TERMUX_PKG_NAME}
-Dcpp_rtti=false
-Dgbm=enabled
-Degl=enabled
-Dgles1=disabled
-Dgles2=enabled
-Ddri3=enabled
-Dllvm=enabled
-Dshared-llvm=disabled
-Dglx=dri
-Dplatforms=x11
-Ddri-drivers=
-Dgallium-drivers=zink
-Dvulkan-drivers=
-Dosmesa=false
-Dglvnd=true
"

termux_step_pre_configure() {
	termux_setup_cmake
	termux_setup_meson

	CPPFLAGS+=" -D__USE_GNU"
	LDFLAGS+=" -landroid-shmem -ltinfo"
	LDFLAGS+=" -Wl,--undefined-version"

	_WRAPPER_BIN=${TERMUX_PKG_CACHEDIR}/cmake-wrapper/bin
	mkdir -p "$_WRAPPER_BIN"
	if [[ ${TERMUX_ON_DEVICE_BUILD} = false ]]; then
		sed "s|@CMAKE@|$(command -v cmake)|g" \
			"${TERMUX_PKG_BUILDER_DIR}"/cmake-wrapper.in \
			>"${_WRAPPER_BIN}/cmake"
		chmod 0700 "${_WRAPPER_BIN}/cmake"
	fi
	PATH=${_WRAPPER_BIN}:${PATH}

	# Revert this commit on meson as it breaks custom llvm
	patch -d "$(dirname "${TERMUX_MESON}")" -p1 -R <"${TERMUX_PKG_BUILDER_DIR}"/9999-meson-89146e84c9eab649d3847af101d61047cac45765.diff || true
}

termux_step_post_make_install() {
	# Avoid hard links
	local f1
	for f1 in "${TERMUX__PREFIX__LIB_DIR}"/dri/*; do
		if [[ ! -f "${f1}" ]]; then
			continue
		fi
		local f2
		for f2 in "${TERMUX__PREFIX__LIB_DIR}"/dri/*; do
			local s1 s2
			if [[ -f ${f2} ]] && [[ "${f1}" != "${f2}" ]]; then
				s1=$(stat -c "%i" "${f1}")
				s2=$(stat -c "%i" "${f2}")
				if [[ "${s1}" = "${s2}" ]]; then
					ln -sfr "${f1}" "${f2}"
				fi
			fi
		done
	done

	# Create symlinks
	ln -sf libEGL_mesa.so "${TERMUX__PREFIX__LIB_DIR}"/libEGL_mesa.so.0
	ln -sf libGLX_mesa.so "${TERMUX__PREFIX__LIB_DIR}"/libGLX_mesa.so.0
}
