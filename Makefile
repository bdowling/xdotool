PREFIX?=/usr/local
INSTALLBIN?=$(PREFIX)/bin
INSTALLLIB?=$(PREFIX)/lib
INSTALLMAN?=$(PREFIX)/man
INSTALLINCLUDE?=$(PREFIX)/include

MINOR=0
MICROVERSION?=00

WARNFLAGS+=-pedantic -Wall -W -Wundef \
           -Wendif-labels -Wshadow -Wpointer-arith -Wbad-function-cast \
           -Wcast-align -Wwrite-strings -Wstrict-prototypes \
           -Wmissing-prototypes -Wnested-externs -Winline \
           -Wdisabled-optimization -Wno-missing-field-initializers

CFLAGS?=-pipe $(WARNFLAGS)

DEFAULT_LIBS=-L/usr/X11R6/lib -L/usr/local/lib -lX11 -lXtst
DEFAULT_INC=-I/usr/X11R6/include -I/usr/local/include

LIBS=$(shell pkg-config --libs x11 xtst 2> /dev/null || echo "$(DEFAULT_LIBS)")
INC=$(shell pkg-config --cflags x11 xtst 2> /dev/null || echo "$(DEFAULT_INC)")

CFLAGS+=-std=c99 $(INC)
LDFLAGS+=$(LIBS)

all: xdotool xdotool.1

install: installlib installprog installman installheader

installprog: xdotool
	install -m 755 xdotool $(INSTALLBIN)/

installlib: libxdo.so
	install libxdo.so $(INSTALLLIB)/libxdo.so.$(MINOR)
	ln -sf libxdo.so.$(MINOR) $(INSTALLLIB)/libxdo.so

installheader: xdo.h
	install xdo.h $(INSTALLINCLUDE)/xdo.h

installman: xdotool.1
	[ -d $(INSTALLMAN) ] || mkdir $(INSTALLMAN)
	[ -d $(INSTALLMAN)/man1 ] || mkdir $(INSTALLMAN)/man1
	install -m 644 xdotool.1 $(INSTALLMAN)/man1/

deinstall: uninstall
uninstall: 
	rm -f $(INSTALLBIN)/xdotool
	rm -f $(INSTALLMAN)/man1/xdotool.1
	rm -f $(INSTALLLIB)/libxdo.so
	rm -f $(INSTALLLIB)/libxdo.so.$(MINOR)

clean:
	rm -f *.o xdotool xdotool.1 libxdo.so libxdo.so.$(MINOR) || true

xdo.o: xdo.c
	$(CC) $(CFLAGS) -fPIC -c xdo.c

xdotool.o: xdotool.c
	$(CC) $(CFLAGS) -c xdotool.c

xdo.c: xdo.h
xdotool.c: xdo.h

libxdo.so: xdo.o
	$(CC) $(LDFLAGS) -shared -Wl,-soname=libxdo.so.$(MINOR) $< -o $@

xdotool: xdotool.o libxdo.so
	$(CC) -o $@ xdotool.o -L. -lxdo $(LDFLAGS) 

xdotool.1: xdotool.pod
	pod2man -c "" -r "" xdotool.pod > $@

package: test-package-build create-package

test:
	cd t/; sh run.sh

create-package: 
	@RELEASE=`date +%Y%m%d`.$(MICROVERSION); \
	NAME=xdotool-$$RELEASE; \
	echo "Creating package: $$NAME"; \
	mkdir $${NAME}; \
	rsync --exclude .svn -a `ls -d *.pod COPYRIGHT *.c *.h examples t CHANGELIST README Makefile* 2> /dev/null` $${NAME}/; \
	echo $$RELEASE > $${NAME}/RELEASE; \
	tar -zcf $${NAME}.tar.gz $${NAME}/; \
	rm -rf $${NAME}/

# Make sure the package we're building compiles.
test-package-build: create-package
	@RELEASE=`date +%Y%m%d`.$(MICROVERSION); \
	NAME=xdotool-$$RELEASE; \
	echo "Testing package $$NAME"; \
	tar -zxf $${NAME}.tar.gz; \
	make -C $${NAME} xdotool; \
	rm -rf $${NAME}/
	rm -f $${NAME}.tar.gz

