TSC ?= tsc
BROWSERIFY ?= browserify

NODE ?= node
SHELL = ash

CP = cp -af
RM = rm -rf

.PHONY: all

all: dist assets

output = src/opsplash.js dist/index.html dist/bundle.js 
res = assets/CircleCashTeamLogo.png

test:
	$(TSC)
	$(BROWSERIFY) -o bundle.js index.js

dist: $(output)
	@mkdir -p dist
	$(CP) index.html dist/index.html
	$(CP) assets dist/assets

dist/bundle.js: index.js
	@mkdir -p dist
	$(BROWSERIFY) $^ -o $@

dist/index.html: index.html
	@mkdir -p dist
	$(CP) $^ $@

src/opsplash.js:
	$(TSC)

clean:
	$(RM) src/opsplash.js
	$(RM) bundle.js
	$(RM) dist