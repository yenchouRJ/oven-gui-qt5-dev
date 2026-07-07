################################################################################
#
# qt6quick3d
#
################################################################################

QT6QUICK3D_VERSION = $(QT6_VERSION)
QT6QUICK3D_SITE = $(QT6_SITE)
QT6QUICK3D_SOURCE = qtquick3d-$(QT6_SOURCE_TARBALL_PREFIX)-$(QT6QUICK3D_VERSION).tar.xz
QT6QUICK3D_INSTALL_STAGING = YES
QT6QUICK3D_SUPPORTS_IN_SOURCE_BUILD = NO

QT6QUICK3D_CMAKE_BACKEND = ninja

QT6QUICK3D_LICENSE = \
	GPL-2.0+ or LGPL-3.0, \
	GPL-3.0 with exception (tools), \
	GFDL-1.3 (docs), \
	BSD-3-Clause

QT6QUICK3D_LICENSE_FILES = \
	LICENSES/BSD-3-Clause.txt \
	LICENSES/GFDL-1.3-no-invariants-only.txt \
	LICENSES/GPL-2.0-only.txt \
	LICENSES/GPL-3.0-only.txt \
	LICENSES/LGPL-3.0-only.txt \
	LICENSES/Qt-GPL-exception-1.0.txt

QT6QUICK3D_CONF_OPTS = \
	-DQT_HOST_PATH=$(HOST_DIR) \
	-DBUILD_WITH_PCH=OFF \
	-DQT_BUILD_EXAMPLES=OFF \
	-DQT_BUILD_TESTS=OFF \
	-DFEATURE_system_assimp=OFF

QT6QUICK3D_DEPENDENCIES = \
	host-pkgconf \
	host-qt6quick3d \
	host-qt6shadertools \
	qt6base \
	qt6declarative \
	qt6shadertools

ifeq ($(BR2_PACKAGE_QT6QUICKTIMELINE),y)
QT6QUICK3D_DEPENDENCIES += qt6quicktimeline
endif

HOST_QT6QUICK3D_DEPENDENCIES = \
	host-qt6base \
	host-qt6declarative \
	host-qt6shadertools

HOST_QT6QUICK3D_CONF_OPTS = \
	-DBUILD_WITH_PCH=OFF \
	-DQT_BUILD_EXAMPLES=OFF \
	-DQT_BUILD_TESTS=OFF \
	-DFEATURE_system_assimp=OFF

$(eval $(cmake-package))
$(eval $(host-cmake-package))
