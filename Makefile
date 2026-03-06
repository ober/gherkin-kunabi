SCHEME = $(HOME)/.local/bin/scheme
GHERKIN = $(or $(GHERKIN_DIR),$(HOME)/mine/gherkin/src)
GHERKIN_AWS = $(or $(GHERKIN_AWS_DIR),gherkin-aws/src)
CHEZ_LEVELDB = $(or $(CHEZ_LEVELDB_DIR),$(HOME)/mine/chez-leveldb)
LIBDIRS = src:$(GHERKIN):$(GHERKIN_AWS):$(CHEZ_LEVELDB)
COMPILE = $(SCHEME) -q --libdirs $(LIBDIRS) --compile-imported-libraries

.PHONY: all compile gherkin binary clean help run deps

all: deps gherkin compile

# Build gherkin-aws dependency (translate its .ss → .sls)
deps:
	$(MAKE) -C gherkin-aws gherkin

# Step 1: Translate .ss → .sls via gherkin compiler
gherkin:
	$(COMPILE) < build-gherkin.ss
	@# Post-translation fixups for Gerbil-specific syntax
	@for f in src/ober/*.sls; do \
	  sed -i "s/#\[keyword-object \"snapshot\"\]/'snapshot:/g" "$$f" 2>/dev/null || true; \
	  sed -i 's/(table? /(hash-table? /g' "$$f" 2>/dev/null || true; \
	done
	@# kunabi-storage: add try/finally import
	@sed -i '/(compat pregexp)/a\    (only (compat sugar) try finally)' src/ober/kunabi-storage.sls 2>/dev/null || true
	@# kunabi-loader: add wg and chez-zlib imports
	@sed -i '/(gerbil-aws s3-api)/a\    (compat wg)' src/ober/kunabi-loader.sls 2>/dev/null || true
	@sed -i '/(gerbil-aws s3-api)/a\    (chez-zlib)' src/ober/kunabi-loader.sls 2>/dev/null || true
	@# kunabi-loader: use native gzip decompression in download-and-parse
	@sed -i '/define (download-and-parse/,/records)))/c\  (define (download-and-parse client bucket-name key compact?)\n    (let* ([raw (get-object client bucket-name key)]\n           [data (if (gzip-data? raw)\n                     (utf8->string (gunzip-bytevector raw))\n                     (if (bytevector? raw)\n                         (utf8->string raw)\n                         raw))]\n           [records (parse-cloudtrail data)])\n      (if compact?\n          (map strip-response-elements records)\n          records)))' src/ober/kunabi-loader.sls 2>/dev/null || true
	@# kunabi-main: show help when no arguments are passed
	@sed -i '/call-with-getopt kunabi-main args/i\    (when (null? args)\n      (let ([gopt (getopt '\''program: "kunabi" '\''help:\n                    "CloudTrail log analyzer" load-cmd report-cmd list-cmd\n                    detect-cmd billing-cmd search-cmd get-cmd purge-cmd\n                    compact-cmd leveldb-compact-cmd reindex-cmd)])\n        (getopt-display-help gopt)\n        (exit 0)))' src/ober/kunabi-main.sls 2>/dev/null || true

# Step 2: Compile .sls → .so via Chez
compile: gherkin
	$(COMPILE) < build-all.ss

# Build = full pipeline
build: binary

# Native binary
binary: clean deps gherkin compile
	$(SCHEME) -q --libdirs $(LIBDIRS) --program build-binary.ss

# Run interpreted
run: all
	$(SCHEME) -q --libdirs $(LIBDIRS) --program kunabi.ss

clean:
	rm -f kunabi-main.o leveldb_shim.o chez_ssl_shim.o chez_zlib_shim.o kunabi_program.h
	rm -f kunabi_petite_boot.h kunabi_scheme_boot.h kunabi_app_boot.h
	rm -f kunabi.boot kunabi-all.so kunabi.so kunabi.wpo
	rm -f petite.boot scheme.boot
	find src -name '*.so' -o -name '*.wpo' | xargs rm -f 2>/dev/null || true

help:
	@echo "Targets:"
	@echo "  all       - Translate .ss→.sls + compile .sls→.so"
	@echo "  build     - Build standalone binary (./kunabi)"
	@echo "  binary    - Same as build"
	@echo "  run       - Run interpreted"
	@echo "  gherkin   - Translate .ss → .sls only"
	@echo "  compile   - Compile .sls → .so only"
	@echo "  clean     - Remove all build artifacts"
	@echo "  help      - Show this help"
