ifndef QCONFIG
QCONFIG=qconfig.mk
endif
include $(QCONFIG)

include $(MKFILES_ROOT)/qmacros.mk

NAME=llama.cpp
QNX_PROJECT_ROOT ?= $(shell readlink -f $(PROJECT_ROOT)/../../../$(NAME))

#where to install:
LLAMA_INSTALL_ROOT ?= $(INSTALL_ROOT_$(OS))

PREFIX ?= /usr/local

#choose Release or Debug
CMAKE_BUILD_TYPE ?= Debug

#override 'all' target to bypass the default QNX build system
ALL_DEPENDENCIES = llama_all
.PHONY: llama_all test

CFLAGS += $(FLAGS)

include $(MKFILES_ROOT)/qtargets.mk

#CMake env
CMAKE_MODULE_PATH := $(QNX_TARGET)/$(CPUVARDIR)/$(PREFIX)/lib/cmake;$(INSTALL_ROOT)/$(CPUVARDIR)/$(PREFIX)/lib/cmake

CFLAGS += -I$(INSTALL_ROOT)/$(PREFIX)/include 
LDFLAGS += -lgomp -lsocket -lc++

CMAKE_ARGS = -DCMAKE_TOOLCHAIN_FILE=$(PROJECT_ROOT)/qnx.nto.toolchain.cmake \
             -DCMAKE_SYSTEM_PROCESSOR=$(CPUVARDIR) \
             -DCPU=${CPU} \
             -DCMAKE_INSTALL_PREFIX=$(LLAMA_INSTALL_ROOT)/$(CPUVARDIR)/$(PREFIX) \
             -DCMAKE_INSTALL_INCLUDEDIR=$(LLAMA_INSTALL_ROOT)/$(PREFIX)/include \
             -DCMAKE_MODULE_PATH="$(CMAKE_MODULE_PATH)" \
             -DCMAKE_FIND_ROOT_PATH="$(CMAKE_FIND_ROOT_PATH)" \
             -DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) \
             -DEXTRA_CMAKE_C_FLAGS="$(CFLAGS)" \
             -DEXTRA_CMAKE_CXX_FLAGS="$(CFLAGS)" \
             -DEXTRA_CMAKE_LINKER_FLAGS="$(LDFLAGS)" \
             -DGCC_VER=${GCC_VER}

MAKE_ARGS ?= -j $(firstword $(JLEVEL) 4)

ifndef NO_TARGET_OVERRIDE
include $(PROJECT_ROOT)/patch.mk

llama_all: apply-patch
	@mkdir -p build
	cd build && cmake $(CMAKE_ARGS) $(QNX_PROJECT_ROOT)
	cd build && make all $(MAKE_ARGS)


install: llama_all
	@cd build && make $(MAKE_ARGS) install 

clean iclean spotless: clean-patch
	rm -fr build

cuninstall uninstall:

test: 
	cd build && $(PROJECT_ROOT)/ctest2cmd.sh $(PROJECT_ROOT) $(QNX_PROJECT_ROOT)

endif
