# Defects4J — prebuilt container images

Docker/Podman images for [Defects4J](https://github.com/rjust/defects4j) with all
active bugs already checked out and compiled at build time. Containers start with
a fully populated `/work`, so there is no download or compile step at startup.

## Requirements

- Docker or Podman (`build.sh` prefers `podman`, then `docker`)
- The base archives under `common/` (`defects4j-repos.zip` and the Gradle bundles).
  They are downloaded on demand if missing; they total several hundred MB and are
  not tracked in Git (see `common/.gitignore`).
- Several GB of free disk space per image

## Building

```bash
# build all versions
./build.sh

# build a single version (prefix filter on the version)
./build.sh 2.
```

Currently available images:

| Image             | Defects4J | Java   |
|-------------------|-----------|--------|
| `defects4j:0.1.0` | 0.1.0     | Java 7 |
| `defects4j:1.4.0` | 1.4.0     | Java 7 |
| `defects4j:2.0.0` | 2.0.0     | Java 8 |

More versions can be added by extending the `BUILDS` array in `build.sh` and
providing a matching `version-X.x.x/` build context.

A build takes well over an hour per version (full checkout and compile of every
bug) and produces multi-GB images.

## Usage

```bash
# start a container — drops you into /work
docker run --rm -it defects4j:2.0.0

# work with a bug
cd /work/Lang/1
defects4j compile
defects4j test
```

Every bug lives under `/work/<Project>/<BugID>`, e.g. `/work/Math/5`,
`/work/Closure/42`. From there you can run any `defects4j` command
(`defects4j test`, `defects4j compile`, …) or point your own tooling at the
checkout.

Included are all projects with active bugs: Chart, Math, Lang, Time, Closure,
Cli, Codec, Collections, Compress, Csv, Gson, JacksonCore, JacksonDatabind,
JacksonXml, Jsoup, JxPath, Mockito.

## Notes

- The timezone `TZ=America/Los_Angeles` is set for reproducible test results and
  should not be changed.

## License

Defects4J is distributed under its own license; see the
[upstream repository](https://github.com/rjust/defects4j). This repo only provides
the container build and packaging layer around it.
