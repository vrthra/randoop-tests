PROJECT_TAR=MATH_3_6_RC2.tar.gz
PROJECT_WWW=https://github.com/apache/commons-math/archive/$(PROJECT_TAR)
PROJECT_DIR=build/commons-math-MATH_3_6_RC2/
PKG_NAME=org.apache.commons.math3
JAR_NAME=commons-math3-3.6.jar

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

build_project: $(JAR_NAME)

$(JAR_PATH): tars/$(PROJECT_TAR) | build
	cd build && $(ZCAT) ../tars/$(PROJECT_TAR) | tar -xvpf -
	cd $(PROJECT_DIR) && mvn clean compile package

lib: ; mkdir -p lib
tars: ; mkdir -p tars
build: ; mkdir -p build

build/classes.txt: $(JAR_PATH)
	jar -tf $(JAR_PATH) | grep '\.class$$' | sed -e 's#.class##g' -e 's#/#.#g' | grep -v '[$$]' > $@_
	mv $@_ $@

RANDOOP_TESTS_OUTPUT_DIR=build/randoop

gen_tests_%: $(JAR_PATH) $(RANDOOP_JAR) build/classes.txt | build
	cat build/classes.txt | sed -ne '$*p' > build/classname.txt
	java -classpath $(RANDOOP_JAR):$(JAR_PATH):$(LIB_PATH) \
		randoop.main.Main gentests \
		--classlist=./build/classname.txt \
		--check-compilable=true \
		--flaky-test-behavior=DISCARD \
		--regression-test-basename=RT$*_ \
		--no-error-revealing-tests=true \
		--junit-package-name=$(PKG_NAME).randoop \
		--junit-output-dir=$(RANDOOP_TESTS_OUTPUT_DIR)/java 
	cat build/classname.txt >> tested_classes.txt

