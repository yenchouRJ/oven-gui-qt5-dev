################################################################################
#
# qt6shadertools
#
################################################################################

QT6SHADERTOOLS_VERSION = $(QT6_VERSION)
QT6SHADERTOOLS_SITE = $(QT6_SITE)
QT6SHADERTOOLS_SOURCE = qtshadertools-$(QT6_SOURCE_TARBALL_PREFIX)-$(QT6SHADERTOOLS_VERSION).tar.xz
QT6SHADERTOOLS_INSTALL_STAGING = YES
QT6SHADERTOOLS_SUPPORTS_IN_SOURCE_BUILD = NO

QT6SHADERTOOLS_CMAKE_BACKEND = ninja

QT6SHADERTOOLS_LICENSE = \
	GPL-2.0+ or LGPL-3.0, \
	GPL-3.0 with exception (tools), \
	GFDL-1.3 (docs), \
	BSD-3-Clause

QT6SHADERTOOLS_LICENSE_FILES = \
	LICENSES/BSD-3-Clause.txt \
	LICENSES/GFDL-1.3-no-invariants-only.txt \
	LICENSES/GPL-2.0-only.txt \
	LICENSES/GPL-3.0-only.txt \
	LICENSES/LGPL-3.0-only.txt \
	LICENSES/Qt-GPL-exception-1.0.txt

QT6SHADERTOOLS_CONF_OPTS = \
	-DQT_HOST_PATH=$(HOST_DIR) \
	-DBUILD_WITH_PCH=OFF \
	-DQT_BUILD_EXAMPLES=OFF \
	-DQT_BUILD_TESTS=OFF

QT6SHADERTOOLS_DEPENDENCIES = \
	host-pkgconf \
	host-qt6shadertools \
	qt6base

# Host build: provides the 'qsb' (Qt Shader Baker) tool, which is
# required at build time by qt6quick3d to pre-compile GLSL shaders.
# QT_HOST_PATH must NOT be set here: this IS the host build, so Qt6
# builds qsb natively without looking for a pre-existing host tool.
HOST_QT6SHADERTOOLS_CMAKE_BACKEND = ninja
HOST_QT6SHADERTOOLS_SUPPORTS_IN_SOURCE_BUILD = NO

HOST_QT6SHADERTOOLS_CONF_OPTS = \
	-DBUILD_WITH_PCH=OFF \
	-DQT_BUILD_EXAMPLES=OFF \
	-DQT_BUILD_TESTS=OFF

HOST_QT6SHADERTOOLS_DEPENDENCIES = \
	host-pkgconf \
	host-qt6base

$(eval $(cmake-package))
$(eval $(host-cmake-package))
