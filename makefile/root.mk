APPNAME = roku-iptv
DISTDIR = dist/apps
SOURCE_DIR = source
APP_ZIP_FILE = $(DISTDIR)/$(APPNAME).zip
ZIP_EXCLUDE = -x \*.pkg -x storeassets\* -x keys\* -x \*/.\* -x .DS_Store -x \*/.DS_Store

.PHONY: all package check clean

all: package

package:
	@mkdir -p $(DISTDIR)
	@rm -f $(APP_ZIP_FILE)
	@cd $(SOURCE_DIR) && zip -0 -r "../$(APP_ZIP_FILE)" . -i \*.png $(ZIP_EXCLUDE)
	@cd $(SOURCE_DIR) && zip -9 -r "../$(APP_ZIP_FILE)" . -x \*~ -x \*.png $(ZIP_EXCLUDE)
	@echo "*** packaged $(APP_ZIP_FILE) ***"

check: package
	@echo "*** Note: BrightScript static check tool is not wired in this repo layout ***"

clean:
	@rm -f $(APP_ZIP_FILE)
