TSC ?= tsc
BROWSERIFY ?= browserify
UGLIFYJS ?= uglifyjs

NODE ?= node
SHELL = ash

CP = cp -af
RM = rm -rf

.PHONY: all

all: check_command check_install dist assets

output = src/opsplash.js dist/index.html dist/bundle.js 
res = assets/CircleCashTeamLogo.png

COMMAND = $(TSC) $(BROWSERIFY) $(UGLIFYJS)
check_command:
	@if command -v npm > /dev/null 2>&1; then \
		echo "npm is installed."; \
	else \
		echo "npm is not installed."; \
		exit 1; \
	fi
	@if command -v $(TSC) > /dev/null 2>&1; then \
		echo "$(TSC) is installed."; \
	else \
		echo "$(TSC) is not installed."; \
		exit 1; \
	fi
	@if command -v $(BROWSERIFY) > /dev/null 2>&1; then \
		echo "$(BROWSERIFY) is installed."; \
	else \
		echo "$(BROWSERIFY) is not installed."; \
		exit 1; \
	fi
	@if command -v $(UGLIFYJS) > /dev/null 2>&1; then \
		echo "$(UGLIFYJS) is installed."; \
	else \
		echo "$(UGLIFYJS) is not installed."; \
		exit 1; \
	fi

check_install:
	@if [ ! -e node_modules ]; then \
		npm install; \
	else \
		echo "node modules has been installed."; \
	fi

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
	$(UGLIFYJS) $@ -o $@

dist/index.html: index.html
	@mkdir -p dist
	$(CP) $^ $@

src/opsplash.js:
	$(TSC)

clean:
	$(RM) src/opsplash.js
	$(RM) bundle.js
	$(RM) dist