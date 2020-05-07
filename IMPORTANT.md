commons-math:

`build_project` will fail with
```
An Ant BuildException has occured: /SSD/gopinath/randoop-tests/build/commons-math-MATH_3_6_RC2/target/test-classes does not exist
```

However, the jar `build/commons-math-MATH_3_6_RC2/target/commons-math3-3.6.jar` will be created. Simply copy over the jar to build, and continue.

```
cp build/commons-math-MATH_3_6_RC2 && mvn dependency:copy-dependencies -DoutputDirectory=target/lib
find build/commons-math-MATH_3_6_RC2/target/lib -name \*.jar | xargs echo | sed -e 's# #:#g' > build/.dep-classpath
cp build/commons-math-MATH_3_6_RC2/target/commons-math3-3.6.jar build/
```
