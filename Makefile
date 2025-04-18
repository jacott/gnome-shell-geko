# Basic Makefile

UUID = geko@geoffjacobsen.gmail.com
BASE_MODULES = extension.js stylesheet.css metadata.json COPYING README.md
EXTRA_MODULES = Utils.js NavManager.js CommandManager.js TileManager.js SystemMonitor.js SoundControl.js # Settings.ui
# EXTRA_MEDIA = logo.svg glossy.svg
# TOLOCALIZE =  prefs.js appIcons.js
MSGSRC = $(wildcard po/*.po)
ifeq ($(strip $(DESTDIR)),)
	INSTALLTYPE = local
	INSTALLBASE = $(HOME)/.local/share/gnome-shell/extensions
else
	INSTALLTYPE = system
	SHARE_PREFIX = $(DESTDIR)/usr/share
	INSTALLBASE = $(SHARE_PREFIX)/gnome-shell/extensions
endif
INSTALLNAME = $(UUID)

# The command line passed variable VERSION is used to set the version string
# in the metadata and in the generated zip-file. If no VERSION is passed, the
# current commit SHA1 is used as version number in the metadata while the
# generated zip file has no string attached.
ifdef VERSION
	VSTRING = _v$(VERSION)
else
	VERSION = $(shell git rev-parse HEAD)
	VSTRING =
endif

all: extension

clean:
	rm -f ./schemas/gschemas.compiled

extension: ./schemas/gschemas.compiled $(MSGSRC:.po=.mo)

./schemas/gschemas.compiled: ./schemas/org.gnome.shell.extensions.geko.gschema.xml
	glib-compile-schemas ./schemas/

# potfile: ./po/dashtodock.pot

# mergepo: potfile
# 	for l in $(MSGSRC); do \
# 		msgmerge -U $$l ./po/dashtodock.pot; \
# 	done;

# ./po/dashtodock.pot: $(TOLOCALIZE) Settings.ui
# 	mkdir -p po
# 	xgettext -k --keyword=__ --keyword=N__ --add-comments='Translators:' -o po/dashtodock.pot --package-name "Dash to Dock" $(TOLOCALIZE)
# 	intltool-extract --type=gettext/glade Settings.ui
# 	xgettext -k --keyword=_ --keyword=N_ --join-existing -o po/dashtodock.pot Settings.ui.h

# ./po/%.mo: ./po/%.po
# 	msgfmt -c $< -o $@

install: install-local

install-local: _build
	rm -rf $(INSTALLBASE)/$(INSTALLNAME)
	mkdir -p $(INSTALLBASE)/$(INSTALLNAME)
	cp -r ./_build/* $(INSTALLBASE)/$(INSTALLNAME)/
ifeq ($(INSTALLTYPE),system)
# system-wide settings and locale files
	rm -r $(INSTALLBASE)/$(INSTALLNAME)/schemas $(INSTALLBASE)/$(INSTALLNAME)/locale
	mkdir -p $(SHARE_PREFIX)/glib-2.0/schemas $(SHARE_PREFIX)/locale
	cp -r ./schemas/*gschema.* $(SHARE_PREFIX)/glib-2.0/schemas
	cp -r ./_build/locale/* $(SHARE_PREFIX)/locale
endif
#	pkill -HUP gnome-shell
	-rm -fR _build
	echo done

install-gkj: _build
	rsync -r ./_build/ gkj:$(INSTALLBASE)/$(INSTALLNAME)
	echo done

install-lenny: _build
	rsync --delete -r ./_build/ lenny:$(INSTALLBASE)/$(INSTALLNAME)
	echo done

zip-file: _build
	cd _build ; \
	zip -qr "$(UUID)$(VSTRING).zip" .
	mv _build/$(UUID)$(VSTRING).zip ./
	-rm -fR _build

_build: all
	-rm -fR ./_build
	mkdir -p _build
	cp $(BASE_MODULES) $(EXTRA_MODULES) _build
# mkdir -p _build/media
# cd media ; cp $(EXTRA_MEDIA) ../_build/media/
	mkdir -p _build/schemas
	cp schemas/*.xml _build/schemas/
	cp schemas/gschemas.compiled _build/schemas/
	mkdir -p _build/locale
# for l in $(MSGSRC:.po=.mo) ; do \
# 	lf=_build/locale/`basename $$l .mo`; \
# 	mkdir -p $$lf; \
# 	mkdir -p $$lf/LC_MESSAGES; \
# 	cp $$l $$lf/LC_MESSAGES/dashtodock.mo; \
# done;
	sed -i 's/"version": -1/"version": "$(VERSION)"/'  _build/metadata.json;
