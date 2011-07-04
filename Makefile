REBAR ?= $(shell which rebar 2>/dev/null || which ./rebar)
EBAR_FLAGS ?=

VSN := "0.1"
BUILD_DATE := `LANG=C date +"%a %b %d %Y"`
NAME := radiusproxy

ERLANG_ROOT := $(shell erl -eval 'io:format("~s", [code:root_dir()])' -s init stop -noshell)
ERLDIR=$(ERLANG_ROOT)/lib/$(NAME)-$(VSN)

EBIN_DIR := ebin
ERL_SOURCES  := $(wildcard src/*.erl)
ERL_OBJECTS  := $(ERL_SOURCES:src/%.erl=$(EBIN_DIR)/%.beam)
APP_FILE := $(EBIN_DIR)/$(NAME).app

all: compile

compile:
	VSN=$(VSN) BUILD_DATE=$(BUILD_DATE) $(REBAR) compile $(REBAR_FLAGS)

test: compile
	$(REBAR) eunit $(REBAR_FLAGS)

install: all
	install -D -p -m 0644 $(APP_FILE) $(DESTDIR)$(ERLDIR)/$(APP_FILE)
	install -p -m 0644 $(ERL_OBJECTS) $(DESTDIR)$(ERLDIR)/$(EBIN_DIR)
	install -D -p -m 0644 priv/$(NAME).config $(DESTDIR)/etc/$(NAME).config
	install -D -p -m 0755 priv/$(NAME).init $(DESTDIR)/etc/rc.d/init.d/$(NAME)
	install -D -p -m 0644 priv/$(NAME).sysconfig $(DESTDIR)/etc/sysconfig/$(NAME)

clean:
	$(REBAR) clean $(REBAR_FLAGS)

dialyzer:
	$(REBAR) dialyze $(REBAR_FLAGS)
