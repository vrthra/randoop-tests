project=compress
include Makefile.$(project)

ZCAT=zcat

RANDOOP_V=4.2.3
RANDOOP_NAME=randoop-all-$(RANDOOP_V).jar
RANDOOP_JAR=lib/$(RANDOOP_NAME)
JAR_PATH=$(PROJECT_DIR)/target/$(JAR_NAME)

LIB_PATH=$(shell ruby -e  'puts Dir[Dir.pwd + "/lib/*.jar"].join(":")')

libpath:
	echo -- -$(LIB_PATH)-

randoop: $(RANDOOP_JAR)
$(RANDOOP_JAR): | lib
	wget -c https://github.com/randoop/randoop/releases/download/v$(RANDOOP_V)/$(RANDOOP_NAME)
	mv $(RANDOOP_NAME) $(RANDOOP_JAR)


get_project:tars/$(PROJECT_TAR)

tars/$(PROJECT_TAR): | tars
	wget -c $(PROJECT_WWW)
	mv $(PROJECT_TAR) tars

build_project: build/$(JAR_NAME)

build/$(JAR_NAME): tars/$(PROJECT_TAR) | build
	cd build && $(ZCAT) ../tars/$(PROJECT_TAR) | tar -xvpf -
	cat tars/$(PROJECT_TAR).patch | (cd $(PROJECT_DIR) && patch pom.xml -p1)
	cd $(PROJECT_DIR) && mvn clean compile package -Drat.skip=true -Dmaven.test.skip=true
	cp $(JAR_PATH) build/

lib: ; mkdir -p lib
tars: ; mkdir -p tars
build: ; mkdir -p build

build/classes.txt: build/$(JAR_NAME)
	jar -tf build/$(JAR_NAME) | grep '\.class$$' | sed -e 's#.class##g' -e 's#/#.#g' | grep -v '[$$]' > $@_
	mv $@_ $@

RANDOOP_TESTS_OUTPUT_DIR=build/randoop

#	cat build/classes.txt | sed -ne '$*p' > build/classname.txt
#	cat build/classname.txt >> tested_classes.txt
#		--testjar=./build/$(JAR_NAME) \

gen_tests: .gen_tests
.gen_tests: build/$(JAR_NAME) $(RANDOOP_JAR) build/classes.txt | build
	java -classpath $(RANDOOP_JAR):build/$(JAR_NAME):$(LIB_PATH) \
		randoop.main.Main gentests \
		--classlist=./build/classes.txt \
		--check-compilable=true \
		--flaky-test-behavior=DISCARD \
		--regression-test-basename=RT_ \
		--no-error-revealing-tests=true \
		--junit-package-name=$(PKG_NAME).randoop \
		--junit-output-dir=$(RANDOOP_TESTS_OUTPUT_DIR)/java 
	touch .gen_tests

gen_all_tests: build/classes.txt
	for i in $$(seq 1 $$(wc -l build/classes.txt | sed -e 's# .*##g')); do \
		echo $$i; \
		$(MAKE) gen_tests_$$i; \
		done


save_tests: build/saved_tests.tar
build/saved_tests.tar: .gen_tests | build
	tar -cf build/saved_tests.tar_ $(TEST_PATH)
	mv build/saved_tests.tar_ build/saved_tests.tar

copy_tests: build/.copied
build/.randooptests: build/saved_tests.tar
	rm -rf $(TEST_PATH)/java
	cp -r build/randoop/java/ $(TEST_PATH)
	touch build/.randooptests

#	-cd $(PROJECT_DIR) && mvn org.pitest:pitest-maven:mutationCoverage -Dmutators=NONE -Drat.skip=true

run_randoop_tests: build/.randooptests
	cd $(PROJECT_DIR) && mvn clean test -Drat.skip=true
	cd $(PROJECT_DIR) && mvn -o \
		-DoutputFormats=XML \
		-DexportLineCoverage=true \
		-DtimestampedReports=false \
		org.pitest:pitest-maven:mutationCoverage \
		-DfullMutationMatrix=true \
		-Dmutators=ALL \
		-Drat.skip=true

