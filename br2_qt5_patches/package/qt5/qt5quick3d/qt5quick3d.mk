################################################################################
#
# qt5quick3d
#
################################################################################

QT5QUICK3D_VERSION = $(QT5_VERSION)
QT5QUICK3D_SITE = $(QT5_SITE)/qtquick3d/-/archive/v$(QT5QUICK3D_VERSION)
QT5QUICK3D_SOURCE = qtquick3d-v$(QT5QUICK3D_VERSION).tar.bz2
QT5QUICK3D_DEPENDENCIES = qt5declarative qt5base
QT5QUICK3D_INSTALL_STAGING = YES
QT5QUICK3D_SYNC_QT_HEADERS = YES

QT5QUICK3D_LICENSE = GPL-2.0 or GPL-3.0 or LGPL-3.0
QT5QUICK3D_LICENSE_FILES = LICENSE.GPL2 LICENSE.GPL3 LICENSE.LGPLv3

$(eval $(qmake-package))
