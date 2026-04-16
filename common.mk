ifndef QCONFIG
QCONFIG=qconfig.mk
endif
include $(QCONFIG)

include $(MKFILES_ROOT)/qmacros.mk

NAME=llama.cpp
QNX_PROJECT_ROOT ?= $(shell readlink -f $(PROJECT_ROOT)/../../../$(NAME))

# staging
QNX_BASE:=$(notdir $(shell readlink -f $(QNX_HOST)/../../../))
INSTALL_ROOT_nto := /usr/local/stage
$(NAME)_INSTALL_ROOT ?= $(INSTALL_ROOT_nto)/$(NAME)/$(QNX_BASE)

PREFIX ?= /usr/local

CMAKE_BUILD_TYPE ?= Release

#override 'all' target to bypass the default QNX build system
ALL_DEPENDENCIES = $(NAME)_all
.PHONY: $(ANME)_all install clean test

CFLAGS += $(FLAGS) -D_QNX_SOURCE -O3 -fPIC 
CFLAGS += -I$(INSTALL_ROOT_$(OS))/$(PREFIX)/include -I$(INSTALL_ROOT_$(OS))/$(CPUVARDIR)/$(PREFIX)/include
CXXFLAGS += $(CFLAGS)
LDFLAGS += -lgomp -lsocket -lc++
include $(MKFILES_ROOT)/qtargets.mk

#CMake env
#CMAKE_FIND_ROOT_PATH := $(QNX_TARGET);$(QNX_TARGET)/$(CPUVARDIR);$(INSTALL_ROOT_$(OS))/$(CPUVARDIR)
#CMAKE_MODULE_PATH := $(QNX_TARGET)/$(CPUVARDIR)/$(PREFIX)/lib/cmake;$(INSTALL_ROOT_$(OS))/$(CPUVARDIR)/$(PREFIX)/lib/cmake

CMAKE_ARGS = -DCMAKE_TOOLCHAIN_FILE=$(PROJECT_ROOT)/qnx.nto.toolchain.cmake \
             -DCMAKE_SYSTEM_PROCESSOR=$(CPUVARDIR) \
             -DCPU=${CPU} \
             -DCMAKE_INSTALL_PREFIX=$($(NAME)_INSTALL_ROOT)/$(CPUVARDIR)/$(PREFIX) \
             -DCMAKE_INSTALL_INCLUDEDIR=$($(NAME)_INSTALL_ROOT)/$(PREFIX)/include \
             -DCMAKE_MODULE_PATH="$(CMAKE_MODULE_PATH)" \
             -DCMAKE_FIND_ROOT_PATH="$(CMAKE_FIND_ROOT_PATH)" \
             -DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) \
             -DEXTRA_CMAKE_C_FLAGS="$(CFLAGS)" \
             -DEXTRA_CMAKE_CXX_FLAGS="$(CXXFLAGS)" \
             -DEXTRA_CMAKE_LINKER_FLAGS="$(LDFLAGS)" \
             -DGCC_VER=${GCC_VER} 

MAKE_ARGS ?= -j $(firstword $(JLEVEL) 4)
BUILDDIR ?= build_$(QNX_BASE)

include $(PROJECT_ROOT)/patch.mk

CMAKE_DEBUG =


$(NAME)_all: apply-patch
	@mkdir -p $(BUILDDIR) 
	cd $(BUILDDIR) && cmake $(CMAKE_DEBUG) $(CMAKE_ARGS) $(QNX_PROJECT_ROOT)
	cd $(BUILDDIR) && make all $(MAKE_ARGS)

TARGET_INSTALL=@cd $(BUILDDIR) && make $(MAKE_ARGS) install 
EXTRA_ICLEAN=$(BUILDDIR)

clean_all: clean-patch 
	rm -rf $(BUILDDIR)
	rm -rf $($(NAME)_INSTALL_ROOT) 

test: 
	cd build && $(PROJECT_ROOT)/ctest2cmd.sh $(PROJECT_ROOT) $(QNX_PROJECT_ROOT)

