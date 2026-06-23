# Defects4J container images
Container images for running [Defects4J](https://github.com/rjust/defects4j) in reproducible environments.

## Usage
Quick start:
```bash
docker run --rm -it ghcr.io/lukas-png/defects4j-docker:2.0.0
```

Inside the container: check out, compile, and run tests for a bug in `/work`
```bash
d4j-checkout Lang-1
cd /work/Lang/1
defects4j test
```

To persistently keep the checked out bugs in a local directory, mount that as a volume to the `/work` directory inside the container (using the local directory `defects4j-bugs` as an example here):
```bash
docker run --rm -it -v ./defects4j-bugs:/work ghcr.io/lukas-png/defects4j-docker:2.0.0
```

### Helper scripts
The image includes a few convenience wrappers around Defects4J for listing, checking out, and compiling bugs.
Every checkout lands at `/work/<Project>/<BugID>` (e.g. `/work/Math/5`).

| Script             | Description                                                       |
|--------------------|-------------------------------------------------------------------|
| `d4j-list`         | List available Defects4J bug IDs, optionally filtered by project. |
| `d4j-checkout`     | Checkout and compile a single Defects4J bug.                      |
| `d4j-checkout-all` | Checkout and compile all bugs returned by `d4j-list`.             |

Project filters for `d4j-list` and `d4j-checkout-all` are specified via `-p` and may be given multiple times:
```bash
# Checkout all Lang and Math bugs into /work/<Project>/<BugID>
d4j-checkout-all -p Lang -p Math
```

## Available images
Images are published as: `ghcr.io/lukas-png/defects4j-docker:<Defects4J version>`

| Image tag | Defects4J | JDK version    | #Projects | #Bugs   | D4J Tag Date |
|-----------|-----------|----------------|-----------|---------|--------------|
| `0.1.0`   | 0.1.0     | Zulu OpenJDK 7 |         5 |     357 |   2015-06-11 |
| `0.2.0`   | 0.2.0     | Zulu OpenJDK 7 |         5 |     357 |   2015-11-04 |
| `1.0.0`   | 1.0.0     | Zulu OpenJDK 7 |         5 |     357 |   2016-02-14 |
| `1.0.1`   | 1.0.1     | Zulu OpenJDK 7 |         5 |     357 |   2016-04-01 |
| `1.1.0`   | 1.1.0     | Zulu OpenJDK 7 |     **6** | **395** |   2016-10-21 |
| `1.2.0`   | 1.2.0     | Zulu OpenJDK 7 |         6 |     395 |   2018-02-07 |
| `1.3.0`   | 1.3.0     | Zulu OpenJDK 7 |         6 |     395 |   2019-01-16 |
| `1.3.1`   | 1.3.1     | Zulu OpenJDK 7 |         6 |     395 |   2019-01-18 |
| `1.4.0`   | 1.4.0     | Zulu OpenJDK 7 |         6 |     395 |   2019-01-20 |
| `1.5.0`   | 1.5.0     | Zulu OpenJDK 7 |         6 | **438** |   2019-09-01 |
| `2.0.0`   | 2.0.0     |  **OpenJDK 8** |    **17** | **835** |   2020-09-15 |
| `2.0.1`   | 2.0.1     |      OpenJDK 8 |        17 |     835 |   2023-08-25 |
| `2.1.0`   | 2.1.0     |      OpenJDK 8 |        17 |     835 |   2024-09-12 |
| `3.0.0`   | 3.0.0     | **OpenJDK 11** |        17 | **854** |   2024-09-19 |
| `3.0.1`   | 3.0.1     |     OpenJDK 11 |        17 |     854 |   2024-11-27 |

## Building locally
```bash
# build all versions
./build.sh

# build a single version
./build.sh 2.0.0
```

`build.sh` uses `podman` if available, otherwise `docker`. Set `ENGINE=docker` to override.

Some archives under `resources/` are downloaded automatically on first build (several hundred MB total, not tracked in Git).

## Differences to historical/original setup
- The original `defects4j-repos.zip` used by Defects4J before 2.0.0 is no longer available.
  We use the one from Defects4J 2.0.0 for versions 0.* and 1.* as well.
  As only additional bugs are added for Defects4J 2.0.0, the "old" bugs used by the versions 1.* and 0.* remained identical in this archive.
- The same goes for the gradle dependencies that are hosted in the `defects4j-gradle-deps.zip` and  `defects4j-gradle-dists.zip` archives; we use the versions hosted for Defects4J 2.0.0.
  Additionally, these were introduced in Defects4J 1.2.0, but we also include them in the image for all versions before that.
- The included version of the Major tool, which bundles the Ant tool used by Defects4J, differs for versions 1.0.0 through 1.2.0.
  For these, we use the same Major version as used in Defects4J 1.3.0 and later.
- Additional tools (e.g. the test generation tools EvoSuite and Randoop) that are usually installed via `init.sh` are not included.
  They are not required for base functionality of Defects4J (`checkout`, `compile`, and `test`).
  This reduces the external dependencies to download for the image creation.

## Reproducibility issues
We validate the reproducibility of the bugs in Defects4J with the script `validation/validate-failing-tests.sh`.
For each bug, it validates that the actually failing tests match what Defects4J expects, by checking out the buggy version, running `defects4j test` on it, and comparing the output with the list of expected failing tests.
We use this script to check that the environment in the container images is suitable for reproducing the bugs.

While validating the reproducibility, we encountered a few discrepancies in the test results: some tests fail although they shouldn't.
Here is an overview of the unexpectedly failing tests we encountered, which Defects4J version / container image we encountered them in, as well as whether they are consistently failing or not:

| Version | Bug ID     | Unexpectedly failing test                                                                      | Consistent? |
|---------|------------|------------------------------------------------------------------------------------------------|-------------|
| `0.1.0` |     Math 1 | `org.apache.commons.math3.optimization.direct.CMAESOptimizerTest::testCigarWithBoundaries`     |  no (flaky) |
| `0.1.0` |    Math 10 | `org.apache.commons.math3.optim.nonlinear.scalar.noderiv.CMAESOptimizerTest::testMaximize`     |  no (flaky) |
| `0.1.0` |    Math 48 | `org.apache.commons.math.optimization.direct.CMAESOptimizerTest::testDiagonalRosen`            |  no (flaky) |
| `1.0.1` |     Math 4 | `org.apache.commons.math3.optim.nonlinear.scalar.noderiv.CMAESOptimizerTest::testMaximize`     |  no (flaky) |
| `1.0.1` |    Math 74 | `org.apache.commons.math.stat.descriptive.moment.MeanTest::testWeightedConsistency`            |  no (flaky) |
| `1.1.0` | Mockito 26 | `org.mockitousage.verification.VerificationWithTimeoutTest::shouldFailVerificationWithTimeout` |         yes |
| `1.2.0` | Mockito 26 | `org.mockitousage.verification.VerificationWithTimeoutTest::shouldFailVerificationWithTimeout` |         yes |
| `1.4.0` |     Math 9 | `org.apache.commons.math3.optim.nonlinear.scalar.noderiv.CMAESOptimizerTest::testCigTab`       |  no (flaky) |
| `1.4.0` |    Math 45 | `org.apache.commons.math.stat.descriptive.moment.MeanTest::testWeightedConsistency`            |  no (flaky) |
| `2.0.0` |    Math 16 | `org.apache.commons.math3.genetics.FixedElapsedTimeTest::testIsSatisfied`                      |  no (flaky) |
| `2.0.0` |    Math 41 | `org.apache.commons.math.analysis.function.LogitTest::testDerivativeWithInverseFunction`       |  no (flaky) |
| `2.0.1` |    Math 16 | `org.apache.commons.math3.genetics.FixedElapsedTimeTest::testIsSatisfied`                      |  no (flaky) |
| `2.0.1` |    Math 54 | `org.apache.commons.math.optimization.direct.CMAESOptimizerTest::testAckley`                   |  no (flaky) |
| `2.1.0` |    Math 16 | `org.apache.commons.math3.genetics.FixedElapsedTimeTest::testIsSatisfied`                      |  no (flaky) |

Two of them consistently appear, both from the Mockito project.
All of the others are from the Math project and are flaky, i.e. they sometimes fail and sometimes not.
A brief investigation suggests that the underlying tests might be timing-sensitive and we observed that they seem to fail more likely if system load is high.
Because of this, we believe that there is no problem in the testing environment for the flaky tests (i.e. the environment in the container is not faulty).

We also encountered another type of discrepancy in the test results: tests that do not fail although they should.
Here is an overview of them:

| Version | Bug ID  | Missing failing test                                                                  | Consistent? |
|---------|---------|---------------------------------------------------------------------------------------|-------------|
| `1.0.0` | Math 14 | `org.apache.commons.math3.fitting.PolynomialFitterTest::testLargeSample`              |  no (flaky) |
| `1.1.0` | Math 13 | `org.apache.commons.math3.optimization.fitting.PolynomialFitterTest::testLargeSample` |  no (flaky) |
| `1.3.1` | Math 14 | `org.apache.commons.math3.fitting.PolynomialFitterTest::testLargeSample`              |  no (flaky) |
| `1.4.0` | Math 13 | `org.apache.commons.math3.optimization.fitting.PolynomialFitterTest::testLargeSample` |  no (flaky) |

Overall, we can see that there is only one bug (Mockito 26) in the versions `1.1.0` and `1.2.0` which consistently cannot be reproduced.
All the other discrepancies here are only flaky.
They can be largely mitigated by keeping overall system load low (i.e. not running experiments in parallel on the same machine).
Note, however, that we did not systematically search for flaky tests here; we only encountered them by chance, so there might be more flaky tests in hiding.

## License
Defects4J is distributed under its own license; see the [upstream repository](https://github.com/rjust/defects4j).
This repo only provides the container build and packaging layer.
