# Builds Diary.app on Mac OS X 10.5 (Xcode 3.1) or 10.4 (Xcode 2.5):
#   make            a Universal app (PowerPC and Intel) for 10.4 and later
#   make ARCHS=ppc  PowerPC only, e.g. on a Mac without the 10.4u SDK
#   make zip        Diary.zip for copying to other Macs
#
# No Xcode project or nib files: the window and menus are built in code.

ARCHS   = ppc i386
SDK     = /Developer/SDKs/MacOSX10.4u.sdk
CC      = gcc-4.0
CFLAGS  = -Os -Wall -mmacosx-version-min=10.4 $(addprefix -arch ,$(ARCHS))
ifneq ($(wildcard $(SDK)),)
CFLAGS += -isysroot $(SDK)
LDFLAGS = -Wl,-syslibroot,$(SDK)
endif

SOURCES = main.m DiaryController.m CalendarView.m DiaryServer.m EntryStore.m
HEADERS = DiaryController.h CalendarView.h DiaryServer.h EntryStore.h Dates.h

APP = Diary.app

all: $(APP)

$(APP): $(SOURCES) $(HEADERS) Info.plist Diary.icns
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(APP)/Contents/MacOS/Diary $(SOURCES) -framework Cocoa
	cp Info.plist $(APP)/Contents/
	cp Diary.icns $(APP)/Contents/Resources/
	printf 'APPLDIAR' > $(APP)/Contents/PkgInfo

zip: $(APP)
	rm -f Diary.zip
	ditto -c -k --keepParent $(APP) Diary.zip

clean:
	rm -rf $(APP) Diary.zip

.PHONY: all zip clean
