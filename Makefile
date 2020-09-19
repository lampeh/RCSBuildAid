NAME      =  RCSBuildAid
MANAGED   =  $(KSPDIR)/KSP_Data/Managed
GAMEDATA  =  $(KSPDIR)/GameData
PLUGINDIR =  $(GAMEDATA)/$(NAME)
BUILD     ?= $(PWD)/bin
PLUGIN    =  $(BUILD)/$(NAME).dll
SOURCES   =  $(wildcard Plugin/*.cs Plugin/*/*.cs)
DOC       =  $(BUILD)/README.html
IMGURL    ?= https://github.com/m4v/RCSBuildAid/raw/master/doc

TOOLBAR     =  $(BUILD)/RCSBuildAidToolbar.dll
TOOLBAR_SRC =  $(wildcard RCSBuildAidToolbar/*.cs)
TOOLBAR_LIB ?= $(GAMEDATA)/000_Toolbar/Plugins

VERSION = $(shell git describe --tags --always)
ZIPNAME = $(NAME)_$(VERSION).zip

GMCS   ?= mcs -sdk:4.5
REFERENCE = Assembly-CSharp,UnityEngine,UnityEngine.UI,UnityEngine.CoreModule,$\
			UnityEngine.TextRenderingModule,UnityEngine.IMGUIModule,$\
			UnityEngine.AnimationModule,UnityEngine.InputLegacyModule,$\
			UnityEngine.PhysicsModule
REFERENCE_TOOLBAR = Assembly-CSharp,UnityEngine,UnityEngine.CoreModule,$\
					aaa_Toolbar

# "export DEBUG=1" for enable debug build
ifdef DEBUG
	CFLAGS += -debug -define:DEBUG -define:UNITY_ASSERTIONS
else
	CFLAGS ?= -optimize
endif
# "export PROFILER=1" for enable profiling
ifdef PROFILER
	CFLAGS += -define:ENABLE_PROFILER
endif

.PHONY: all
all: plugin toolbar

.PHONY: info
info:
	@echo "VERSION    $(VERSION)"
	@echo "KSP PATH   $(KSPDIR)"
	@echo "GAMEDATA   $(GAMEDATA)"
	@echo "PLUGIN DIR $(PLUGINDIR)"
	@echo "BUILD PATH $(BUILD)"
	@echo "GMCS       $(GMCS)"
	@echo "CFLAGS     $(CFLAGS)"
	@echo "IMGURL     $(IMGURL)"
	
.PHONY: info_verbose
info_verbose: info
	@echo "Source files:"
	@for source in $(SOURCES); do echo "$$source"; done

.PHONY: plugin
plugin: $(PLUGIN) doc

.PHONY: toolbar
toolbar: $(TOOLBAR)

$(PLUGIN): $(SOURCES) | check
	@echo "\n== Compiling $(NAME)"
	mkdir -p "$(BUILD)"
	$(GMCS) $(CFLAGS) -t:library -lib:"$(MANAGED)" \
		-r:"$(REFERENCE)" \
		-out:$@ $(SOURCES)

$(TOOLBAR): $(PLUGIN) $(TOOLBAR_SRC) | check
	@echo "\n== Compiling toolbar support"
	mkdir -p "$(BUILD)"
	$(GMCS) $(CFLAGS) -t:library -lib:"$(MANAGED),$(TOOLBAR_LIB)" \
		-r:$(REFERENCE_TOOLBAR),$(PLUGIN) \
		-out:$@ $(TOOLBAR_SRC)

.PHONY: clean
clean:
	rm -rfv "$(BUILD)"/*

define install_plugin_at
	@echo "\n== Installing $(NAME) at $(1)"
	mkdir -p "$(1)/Plugins/PluginData"
	mkdir -p "$(1)/Textures"
	cp $(PLUGIN) "$(1)/Plugins"
	cp Textures/iconAppLauncher.png "$(1)/Textures"
	cp RCSBuildAid.version "$(1)"
	cp README.asciidoc "$(1)"
	cp CHANGELOG.asciidoc "$(1)"
	cp LICENSE "$(1)"
	cp $(DOC) "$(1)"
endef

define install_toolbar_at
	@echo "\n== Installing toolbar support at $(1)"
	mkdir -p "$(1)/Plugins"
	mkdir -p "$(1)/Textures"
	cp $(TOOLBAR) "$(1)/Plugins"
	cp Textures/iconToolbar.png "$(1)/Textures"
	cp Textures/iconToolbar_active.png "$(1)/Textures"
endef

.PHONY: install
install: all install_plugin install_toolbar

.PHONY: install_plugin
install_plugin: plugin
	$(call install_plugin_at,$(PLUGINDIR))
ifeq ($(DEBUG),1)
	cp $(PLUGIN).mdb "$(PLUGINDIR)/Plugins"
endif

.PHONY: install_toolbar
install_toolbar: toolbar
	$(call install_toolbar_at,$(PLUGINDIR))
ifeq ($(DEBUG),1)
	cp $(TOOLBAR).mdb "$(PLUGINDIR)/Plugins"
endif

.PHONY: package
package: all
	rm -rf Package/$(NAME)
	$(call install_plugin_at,Package/$(NAME))
	$(call install_toolbar_at,Package/$(NAME))
	@echo "\n== Making zip"
	rm -f Package/$(ZIPNAME)
	cd Package && zip -r $(ZIPNAME) $(NAME)

.PHONY: package_plugin
package_plugin: plugin
	rm -rf Package/$(NAME)
	$(call install_plugin_at,Package/$(NAME))
	@echo "\n== Making zip"
	rm -f Package/$(ZIPNAME)
	cd Package && zip -r $(ZIPNAME) $(NAME)

.PHONY: doc
doc: $(DOC)

$(DOC): README.adoc
	@echo "\n== Building HTML documentation"
	asciidoctor -a imagesdir="$(IMGURL)" README.adoc -o $(DOC)

.PHONY: uninstall
uninstall: | check
	rm -rfv "$(PLUGINDIR)"

.PHONY: check
check:
ifndef KSPDIR
	$(error KSPDIR envar not set)
endif
