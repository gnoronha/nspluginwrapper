#!/bin/sh
#
#  nspluginwrapper Makefile (C) 2005-2007 Gwenole Beauchesne
#
-include config.mak

CFLAGS += -Wall

ifeq ($(SRC_PATH),)
SRC_PATH = .
endif

PACKAGE = nspluginwrapper
ifeq ($(VERSION),)
VERSION := $(shell sed < $(SRC_PATH)/$(PACKAGE).spec -n '/^\%define version[	]*/s///p')
endif
ifeq ($(RELEASE),)
RELEASE := $(shell sed < $(SRC_PATH)/$(PACKAGE).spec -n '/^\%define release[	]*/s///p')
endif
ifeq ($(SVNDATE),)
SVNDATE := $(shell sed < $(SRC_PATH)/$(PACKAGE).spec -n '/^\%define svndate[ 	]*/s///p')
endif
ifeq ($(SVNDATE),)
SVNDATE := $(shell date '+%Y%m%d')
endif
ifeq ($(SNAPSHOT),)
SNAPSHOT := $(shell echo "$(RELEASE)" | grep "^0")
ifeq ($(SNAPSHOT),$(RELEASE))
SNAPSHOT := 1
endif
endif
ifeq ($(SNAPSHOT),1)
VERSION_SUFFIX = -$(SVNDATE)
endif

ifneq ($(DONT_STRIP), yes)
STRIP_OPT = -s
endif

ifneq (,$(findstring $(OS),linux))
libdl_LDFLAGS = -ldl
endif

libpthread_LDFLAGS = -lpthread
ifeq ($(OS),dragonfly)
libpthread_LDFLAGS = -pthread
endif

X_CFLAGS  = -I$(x11prefix)/include
X_LDFLAGS = -L$(x11prefix)/$(lib64) -lX11 -lXt
ifneq (,$(findstring $(OS),netbsd dragonfly))
X_LDFLAGS += -Wl,--rpath,$(x11prefix)/$(lib64)
endif

ARCH_32 = $(ARCH)
ifeq ($(biarch), yes)
ARCH_32 = $(TARGET_ARCH)
LSB_LIBS = $(LSB_OBJ_DIR)/libc.so $(LSB_OBJ_DIR)/libgcc_s_32.so
LSB_LIBS += $(LSB_CORE_STUBS:%=$(LSB_OBJ_DIR)/%.so)
LSB_LIBS += $(LSB_CORE_STATIC_STUBS:%=$(LSB_OBJ_DIR)/%.a)
LSB_LIBS += $(LSB_DESKTOP_STUBS:%=$(LSB_OBJ_DIR)/%.so)
endif

LSB_TOP_DIR = $(SRC_PATH)/lsb-build
LSB_INC_DIR = $(LSB_TOP_DIR)/headers
LSB_SRC_DIR = $(LSB_TOP_DIR)/stub_libs
LSB_OBJ_DIR = lsb-build-$(ARCH_32)
LSB_CORE_STUBS = $(shell cat $(LSB_SRC_DIR)/core_filelist)
LSB_CORE_STATIC_STUBS = $(shell cat $(LSB_SRC_DIR)/core_static_filelist)
LSB_DESKTOP_STUBS = $(shell cat $(LSB_SRC_DIR)/desktop_filelist)

ifeq (i386,$(TARGET_ARCH))
TARGET_ELF_ARCH = elf32-i386
endif
ifeq (ppc,$(TARGET_ARCH))
TARGET_ELF_ARCH = elf32-powerpc
endif

MOZILLA_CFLAGS = -I$(SRC_PATH)/npapi -I$(SRC_PATH)/npapi/nspr

npwrapper_LIBRARY = npwrapper.so
npwrapper_RAWSRCS = npw-wrapper.c npw-rpc.c rpc.c debug.c utils.c npruntime.c
npwrapper_SOURCES = $(npwrapper_RAWSRCS:%.c=$(SRC_PATH)/src/%.c)
npwrapper_OBJECTS = $(npwrapper_RAWSRCS:%.c=npwrapper-%.os)
npwrapper_CFLAGS  = $(CFLAGS) $(X_CFLAGS) $(MOZILLA_CFLAGS) $(GLIB_CFLAGS)
npwrapper_LDFLAGS = $(X_LDFLAGS) $(libpthread_LDFLAGS)
npwrapper_LDFLAGS += $(GLIB_LDFLAGS)

npviewer_PROGRAM = npviewer.bin
npviewer_RAWSRCS = npw-viewer.c npw-rpc.c rpc.c debug.c utils.c npruntime.c
npviewer_SOURCES = $(npviewer_RAWSRCS:%.c=$(SRC_PATH)/src/%.c)
npviewer_OBJECTS = $(npviewer_RAWSRCS:%.c=npviewer-%.o)
ifeq ($(biarch),yes)
npviewer_CFLAGS  = $(CFLAGS_32)
npviewer_CFLAGS += -I$(LSB_INC_DIR)
npviewer_CFLAGS += -I$(LSB_INC_DIR)/glib-2.0
npviewer_CFLAGS += -I$(LSB_INC_DIR)/gtk-2.0
npviewer_LDFLAGS = $(LDFLAGS_32) -L$(LSB_OBJ_DIR)
npviewer_LDFLAGS += -lgtk-x11-2.0 -lgdk-x11-2.0 -lgobject-2.0 -ldl -lglib-2.0 -lX11 -lXt
else
npviewer_CFLAGS += $(GTK_CFLAGS)
npviewer_LDFLAGS = $(GTK_LDFLAGS) $(X_LDFLAGS)
endif
npviewer_CFLAGS  += $(MOZILLA_CFLAGS)
npviewer_LDFLAGS += $(libdl_LDFLAGS) $(libpthread_LDFLAGS)
ifeq ($(TARGET_ARCH),i386)
npviewer_MAPFILE = $(SRC_PATH)/src/npw-viewer.map
endif
ifneq ($(npviewer_MAPFILE),)
npviewer_LDFLAGS += -Wl,--export-dynamic
npviewer_LDFLAGS += -Wl,--version-script,$(npviewer_MAPFILE)
endif
ifeq ($(OS):$(TARGET_ARCH),linux:i386)
npviewer_SOURCES += $(SRC_PATH)/src/cxxabi-compat.cpp
npviewer_OBJECTS += npviewer-cxxabi-compat.o
npviewer_LDFLAGS += -lsupc++
endif

libxpcom_LIBRARY = libxpcom.so
libxpcom_RAWSRCS = libxpcom.c debug.c
libxpcom_SOURCES = $(libxpcom_RAWSRCS:%.c=$(SRC_PATH)/src/%.c)
libxpcom_OBJECTS = $(libxpcom_RAWSRCS:%.c=libxpcom-%.o)
libxpcom_CFLAGS  = -fPIC
ifeq ($(biarch),yes)
libxpcom_CFLAGS += -I$(LSB_INC_DIR)
libxpcom_LDFLAGS = $(LDFLAGS_32) -L$(LSB_OBJ_DIR)
endif

npconfig_PROGRAM = npconfig
npconfig_RAWSRCS = npw-config.c
npconfig_SOURCES = $(npconfig_RAWSRCS:%.c=$(SRC_PATH)/src/%.c)
npconfig_OBJECTS = $(npconfig_RAWSRCS:%.c=npconfig-%.o)
npconfig_LDFLAGS = $(libdl_LDFLAGS)
ifneq (,$(findstring $(OS),netbsd dragonfly))
# We will try to dlopen() the native plugin library. If that lib is
# linked against libpthread, then so must our program too.
# XXX use the ELF decoder for native plugins too?
npconfig_LDFLAGS += $(libpthread_LDFLAGS)
endif

nploader_PROGRAM = npviewer
nploader_RAWSRCS = npw-viewer.sh
nploader_SOURCES = $(nploader_RAWSRCS:%.sh=$(SRC_PATH)/src/%.sh)

CPPFLAGS	= -I. -I$(SRC_PATH)
TARGETS		= $(npconfig_PROGRAM)
TARGETS		+= $(nploader_PROGRAM)
TARGETS		+= $(npwrapper_LIBRARY)
ifeq ($(build_viewer),yes)
TARGETS		+= $(npviewer_PROGRAM)
TARGETS		+= $(libxpcom_LIBRARY)
endif

archivedir	= files/
SRCARCHIVE	= $(PACKAGE)-$(VERSION)$(VERSION_SUFFIX).tar
FILES		= configure Makefile nspluginwrapper.spec
FILES		+= README NEWS TODO COPYING ChangeLog
FILES		+= $(wildcard utils/*.sh)
FILES		+= $(wildcard utils/*.c)
FILES		+= $(wildcard src/*.c)
FILES		+= $(wildcard src/*.cpp)
FILES		+= $(wildcard src/*.h)
FILES		+= $(wildcard src/*.sh)
FILES		+= $(wildcard src/*.map)
FILES		+= $(wildcard tests/*.html)
FILES		+= $(wildcard npapi/*.h npapi/nspr/*.h npapi/nspr/obsolete/*.h)
FILES		+= $(LSB_TOP_DIR)/headers/core_filelist
FILES		+= $(addprefix $(LSB_TOP_DIR)/headers/,$(shell cat $(LSB_TOP_DIR)/headers/core_filelist))
FILES		+= $(LSB_TOP_DIR)/headers/desktop_filelist
FILES		+= $(addprefix $(LSB_TOP_DIR)/headers/,$(shell cat $(LSB_TOP_DIR)/headers/desktop_filelist))
FILES		+= $(LSB_SRC_DIR)/LibNameMap.txt
FILES		+= $(LSB_SRC_DIR)/core_filelist
FILES		+= $(LSB_SRC_DIR)/core_static_filelist
FILES		+= $(LSB_SRC_DIR)/desktop_filelist
FILES		+= $(patsubst %,$(LSB_SRC_DIR)/%.c,$(LSB_CORE_STUBS))
FILES		+= $(patsubst %,$(LSB_SRC_DIR)/%.Version,$(LSB_CORE_STUBS))
FILES		+= $(patsubst %,$(LSB_SRC_DIR)/%.c,$(LSB_CORE_STATIC_STUBS))
FILES		+= $(patsubst %,$(LSB_SRC_DIR)/%.c,$(LSB_DESKTOP_STUBS))
FILES		+= $(patsubst %,$(LSB_SRC_DIR)/%.Version,$(LSB_DESKTOP_STUBS))

all: $(TARGETS)

clean:
	rm -f $(TARGETS) *.o *.os
	rm -rf $(LSB_OBJ_DIR)

distclean: clean
	rm -f config-host.* config.*

uninstall: uninstall.wrapper uninstall.viewer uninstall.libxpcom uninstall.loader uninstall.config uninstall.mkruntime uninstall.dirs
uninstall.dirs:
	rmdir $(DESTDIR)$(pkglibdir)/noarch
	rmdir $(DESTDIR)$(pkglibdir)/$(ARCH)/$(OS)
	rmdir $(DESTDIR)$(pkglibdir)/$(ARCH)
ifneq ($(ARCH),$(ARCH_32))
	rmdir $(DESTDIR)$(pkglibdir)/$(ARCH_32)/$(TARGET_OS)
	rmdir $(DESTDIR)$(pkglibdir)/$(ARCH_32)
endif
uninstall.wrapper:
	rm -f $(DESTDIR)$(pkglibdir)/$(ARCH)/$(OS)/$(npwrapper_LIBRARY)
uninstall.viewer:
	rm -f $(DESTDIR)$(pkglibdir)/$(ARCH_32)/$(TARGET_OS)/$(npviewer_PROGRAM)
	rm -f $(DESTDIR)$(pkglibdir)/$(ARCH_32)/$(TARGET_OS)/$(npviewer_PROGRAM:%.bin=%)
uninstall.libxpcom:
	rm -f $(DESTDIR)$(pkglibdir)/$(ARCH_32)/$(TARGET_OS)/$(libxpcom_LIBRARY)
uninstall.loader:
	rm -f $(DESTDIR)$(pkglibdir)/noarch/$(nploader_PROGRAM)
uninstall.config:
	rm -f $(DESTDIR)$(bindir)/nspluginwrapper
	rm -f $(DESTDIR)$(pkglibdir)/$(ARCH)/$(OS)/$(npconfig_PROGRAM)
uninstall.mkruntime:
	rm -f $(DESTDIR)$(pkglibdir)/noarch/mkruntime

install: install.dirs install.wrapper install.viewer install.libxpcom install.loader install.config install.mkruntime
install.dirs:
	mkdir -p $(DESTDIR)$(pkglibdir)/noarch
	mkdir -p $(DESTDIR)$(pkglibdir)/$(ARCH)
	mkdir -p $(DESTDIR)$(pkglibdir)/$(ARCH)/$(OS)
ifneq ($(ARCH),$(ARCH_32))
	mkdir -p $(DESTDIR)$(pkglibdir)/$(ARCH_32)
	mkdir -p $(DESTDIR)$(pkglibdir)/$(ARCH_32)/$(TARGET_OS)
endif
install.wrapper: $(npwrapper_LIBRARY)
	install -m 755 $(STRIP_OPT) $(npwrapper_LIBRARY) $(DESTDIR)$(pkglibdir)/$(ARCH)/$(OS)/$(npwrapper_LIBRARY)
ifeq ($(build_viewer),yes)
install.viewer: install.viewer.bin install.viewer.glue
install.libxpcom: do.install.libxpcom
else
install.viewer:
install.libxpcom:
endif
install.viewer.bin: $(npviewer_PROGRAM)
	install -m 755 $(STRIP_OPT) $(npviewer_PROGRAM) $(DESTDIR)$(pkglibdir)/$(ARCH_32)/$(TARGET_OS)/$(npviewer_PROGRAM)
install.viewer.glue::
	p=$(DESTDIR)$(pkglibdir)/$(ARCH_32)/$(TARGET_OS)/$(npviewer_PROGRAM:%.bin=%);	\
	echo "#!/bin/sh" > $$p;								\
	echo "TARGET_OS=$(TARGET_OS)" >> $$p;						\
	echo "TARGET_ARCH=$(TARGET_ARCH)" >> $$p;					\
	echo ". $(pkglibdir)/noarch/$(nploader_PROGRAM)" >> $$p;			\
	chmod 755 $$p
do.install.libxpcom: $(libxpcom_LIBRARY)
	install -m 755 $(STRIP_OPT) $(libxpcom_LIBRARY) $(DESTDIR)$(pkglibdir)/$(ARCH_32)/$(TARGET_OS)/$(libxpcom_LIBRARY)
install.config: $(npconfig_PROGRAM)
	install -m 755 $(STRIP_OPT) $(npconfig_PROGRAM) $(DESTDIR)$(pkglibdir)/$(ARCH)/$(OS)/$(npconfig_PROGRAM)
	mkdir -p $(DESTDIR)$(bindir)
	ln -sf $(pkglibdir)/$(ARCH)/$(OS)/$(npconfig_PROGRAM) $(DESTDIR)$(bindir)/nspluginwrapper
install.loader: $(nploader_PROGRAM)
	install -m 755 $(nploader_PROGRAM) $(DESTDIR)$(pkglibdir)/noarch/$(nploader_PROGRAM)
install.mkruntime: $(SRC_PATH)/utils/mkruntime.sh
	install -m 755 $< $(DESTDIR)$(pkglibdir)/noarch/mkruntime

$(archivedir)::
	[ -d $(archivedir) ] || mkdir $(archivedir) > /dev/null 2>&1

tarball:
	$(MAKE) -C $(SRC_PATH) do_tarball
do_tarball: $(archivedir) $(archivedir)$(SRCARCHIVE).bz2

$(archivedir)$(SRCARCHIVE): $(archivedir) $(FILES)
	BUILDDIR=`mktemp -d /tmp/buildXXXXXXXX`						; \
	mkdir -p $$BUILDDIR/$(PACKAGE)-$(VERSION)					; \
	(cd $(SRC_PATH) && tar c $(FILES)) | tar x -C $$BUILDDIR/$(PACKAGE)-$(VERSION)	; \
	[ "$(SNAPSHOT)" = "1" ] && svndate_def="%" || svndate_def="#"			; \
	sed -e "s/^[%#]define svndate.*/$${svndate_def}define svndate $(SVNDATE)/" 	  \
	  < $(SRC_PATH)/nspluginwrapper.spec						  \
	  > $$BUILDDIR/$(PACKAGE)-$(VERSION)/nspluginwrapper.spec			; \
	(cd $$BUILDDIR && tar cvf $(SRCARCHIVE) $(PACKAGE)-$(VERSION))			; \
	mv -f $$BUILDDIR/$(SRCARCHIVE) $(archivedir)					; \
	rm -rf $$BUILDDIR
$(archivedir)$(SRCARCHIVE).bz2: $(archivedir)$(SRCARCHIVE)
	bzip2 -9vf $(archivedir)$(SRCARCHIVE)

RPMBUILD = \
	RPMDIR=`mktemp -d`								; \
	mkdir -p $$RPMDIR/{SPECS,SOURCES,BUILD,RPMS,SRPMS}				; \
	rpmbuild --define "_topdir $$RPMDIR" -ta $(2) $(1) &&				  \
	find $$RPMDIR/ -name *.rpm -exec mv -f {} $(archivedir) \;			; \
	rm -rf $$RPMDIR

distrpm: $(archivedir)$(SRCARCHIVE).bz2
	$(call RPMBUILD,$<,--with generic)

localrpm: $(archivedir)$(SRCARCHIVE).bz2
	$(call RPMBUILD,$<)

changelog: ../common/authors.xml
	svn_prefix=`svn info .|sed -n '/^URL *: .*\/svn\/\(.*\)$$/s//\1\//p'`; \
	svn2cl --strip-prefix=$$svn_prefix --authors=../common/authors.xml || :
changelog.commit: changelog
	svn commit -m "Generated by svn2cl." ChangeLog

$(npwrapper_LIBRARY): $(npwrapper_OBJECTS)
	$(CC) -o $@ -shared $(npwrapper_OBJECTS) $(npwrapper_LDFLAGS)

npwrapper-%.os: $(SRC_PATH)/src/%.c
	$(CC) -o $@ -c $< -fPIC $(CPPFLAGS) $(npwrapper_CFLAGS) -DBUILD_WRAPPER

$(npviewer_PROGRAM): $(npviewer_OBJECTS) $(npviewer_MAPFILE) $(LSB_OBJ_DIR) $(LSB_LIBS)
	$(CC) $(LDFLAGS_32) -o $@ $(npviewer_OBJECTS) $(npviewer_LDFLAGS)

npviewer-%.o: $(SRC_PATH)/src/%.c
	$(CC) $(CFLAGS_32) -o $@ -c $< $(CPPFLAGS) $(npviewer_CFLAGS) -DBUILD_VIEWER

npviewer-%.o: $(SRC_PATH)/src/%.cpp
	$(CXX) $(CFLAGS_32) -o $@ -c $< $(CPPFLAGS) $(npviewer_CFLAGS) -DBUILD_VIEWER

$(libxpcom_LIBRARY): $(libxpcom_OBJECTS) $(LSB_OBJ_DIR) $(LSB_LIBS)
	$(CC) $(LDFLAGS_32) -shared -o $@ $(libxpcom_OBJECTS) $(libxpcom_LDFLAGS) -Wl,--soname,libxpcom.so

libxpcom-%.o: $(SRC_PATH)/src/%.c
	$(CC) $(CFLAGS_32) -o $@ -c $< $(CPPFLAGS) $(libxpcom_CFLAGS) -DBUILD_XPCOM

$(npconfig_PROGRAM): $(npconfig_OBJECTS)
	$(CC) -o $@ $(npconfig_OBJECTS) $(npconfig_LDFLAGS)

npconfig-%.o: $(SRC_PATH)/src/%.c
	$(CC) -o $@ -c $< $(CPPFLAGS) $(CFLAGS)

$(nploader_PROGRAM): $(nploader_SOURCES)
	sed -e "s|%NPW_LIBDIR%|$(pkglibdir)|" $< > $@
	chmod 755 $@

$(LSB_OBJ_DIR)::
	@[ -d $(LSB_OBJ_DIR) ] || mkdir $(LSB_OBJ_DIR) > /dev/null 2>&1

$(LSB_OBJ_DIR)/%.o: $(LSB_SRC_DIR)/%.c
	$(CC) $(CFLAGS_32) -nostdinc -fno-builtin -I. -I$(LSB_INC_DIR) -c $< -o $@

$(LSB_OBJ_DIR)/%.a: $(LSB_OBJ_DIR)/%.o
	$(AR) rc $@ $<

$(LSB_OBJ_DIR)/libc.so: $(LSB_OBJ_DIR)/libc_main.so $(LSB_OBJ_DIR)/libc_nonshared.a
	@echo "OUTPUT_FORMAT($(TARGET_ELF_ARCH))" > $@
	@echo "GROUP ( $(LSB_OBJ_DIR)/libc_main.so $(LSB_OBJ_DIR)/libc_nonshared.a )" >> $@

$(LSB_OBJ_DIR)/libgcc_s_32.so: $(LSB_OBJ_DIR)/libgcc_s.so
	ln -sf libgcc_s.so $@

$(LSB_OBJ_DIR)/%.so: $(LSB_OBJ_DIR)/%.o
	$(CC) $(LDFLAGS_32) -nostdlib -shared $< -o $@ \
		-Wl,--version-script,$(patsubst $(LSB_OBJ_DIR)/%.o,$(LSB_SRC_DIR)/%.Version,$<) \
		-Wl,-soname,`grep "$(patsubst $(LSB_OBJ_DIR)/%.o,%,$<) " $(LSB_SRC_DIR)/LibNameMap.txt | cut -f2 -d' '`
