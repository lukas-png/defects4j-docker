# Defects4J container images
Container images for running [Defects4J](https://github.com/rjust/defects4j) in reproducible environments.

## Usage
Quick start:
```bash
docker run --rm -it ghcr.io/lukas-png/defects4j-docker:2.0.0
# Inside the container: check out and compile a bug in /work
d4j-checkout Lang-1
cd /work/Lang/1
defects4j test
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

| Image tag | Defects4J | JDK version    | #Projects | #Bugs   |
|-----------|-----------|----------------|-----------|---------|
| `0.1.0`   | 0.1.0     | Zulu OpenJDK 7 |         5 |     357 |
| `0.2.0`   | 0.2.0     | Zulu OpenJDK 7 |         5 |     357 |
| `1.0.0`   | 1.0.0     | Zulu OpenJDK 7 |         5 |     357 |
| `1.0.1`   | 1.0.1     | Zulu OpenJDK 7 |         5 |     357 |
| `1.1.0`   | 1.1.0     | Zulu OpenJDK 7 |     **6** | **395** |
| `1.2.0`   | 1.2.0     | Zulu OpenJDK 7 |         6 |     395 |
| `1.3.0`   | 1.3.0     | Zulu OpenJDK 7 |         6 |     395 |
| `1.3.1`   | 1.3.1     | Zulu OpenJDK 7 |         6 |     395 |
| `1.4.0`   | 1.4.0     | Zulu OpenJDK 7 |         6 |     395 |
| `1.5.0`   | 1.5.0     | Zulu OpenJDK 7 |         6 | **438** |
| `2.0.0`   | 2.0.0     |  **OpenJDK 8** |    **17** | **835** |
| `2.0.1`   | 2.0.1     |      OpenJDK 8 |        17 |     835 |
| `2.1.0`   | 2.1.0     |      OpenJDK 8 |        17 |     835 |
| `3.0.0`   | 3.0.0     | **OpenJDK 11** |        17 | **854** |
| `3.0.1`   | 3.0.1     |     OpenJDK 11 |        17 |     854 |

## Building locally
```bash
# build all versions
./build.sh

# build a single version
./build.sh 2.0.0

# embed all bugs at build time (slow: >1 h per version, multi-GB images)
./build.sh --checkout-all
```

`build.sh` uses `podman` if available, otherwise `docker`. Set `ENGINE=docker` to override.

Some archives under `common/` are downloaded automatically on first build (several hundred MB total, not tracked in Git).

## Differences to historical/original setup
- The original [defects4j-repos.zip](http://people.cs.umass.edu/~rjust/defects4j/download/defects4j-repos.zip) used by Defects4J before 2.0.0 is no longer available.
  We use the one from Defects4J 2.0.0 ([defects4j-repos.zip](https://defects4j.org/downloads/defects4j-repos.zip)) for versions 0.* and 1.* as well.
  As only additional bugs are added for Defects4J 2.0.0, the "old" bugs used by the versions 1.* and 0.* remained stable in this archive.
- The included Major version, which bundles the Ant tool used by Defects4J, differs for versions 1.0.0 through 1.2.0.
- The test generation tools EvoSuite and Randoop that are usually installed via `init.sh` are not included.
  They are not required for base functionality of Defects4J (`checkout`, `compile`, and `test`).
  This reduces the external dependencies to download for the image creation.

## License
Defects4J is distributed under its own license; see the [upstream repository](https://github.com/rjust/defects4j).
This repo only provides the container build and packaging layer.
