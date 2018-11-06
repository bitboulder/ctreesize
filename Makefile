all:
DEBUG: all

clean:

install:
	install -D ctreesize	$(DESTDIR)/usr/bin/ctreesize

uninstall:
	rm -f $(DESTDIR)/usr/bin/ctreesize
