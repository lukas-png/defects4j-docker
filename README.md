# Defects4J — prebuilt container images

Docker/Podman images for [Defects4J](https://github.com/rjust/defects4j).

## Quick start

```bash
# Pull and start a container
docker run --rm -it ghcr.io/lukas-png/defects4j-docker:2.0.0

# Inside the container: check out and compile a bug
d4j-checkout Lang-1
cd /work/Lang/1
defects4j test
```

`d4j-checkout <Project>-<BugID> [workdir]` checks out the buggy version and compiles it. 

## Available images

| Image tag | Defects4J | Java   |
|-----------|-----------|--------|
| `0.1.0`   | 0.1.0     | Java 7 |
| `1.4.0`   | 1.4.0     | Java 7 |
| `2.0.0`   | 2.0.0     | Java 8 |

More versions can be added by extending the `BUILDS` array in `build.sh` and
providing a matching `version-X.x.x/` build context.

Every checkout lands at `/work/<Project>/<BugID>` (e.g. `/work/Math/5`).

## Building locally

```bash
# build all versions
./build.sh

# build a single version (prefix filter)
./build.sh 2.

# embed all bugs at build time (slow: >1 h per version, multi-GB images)
./build.sh --checkout-all
```

`build.sh` uses `podman` if available, otherwise `docker`. Set `ENGINE=docker` to override.

The base archives under `common/` are downloaded automatically on first build (several hundred MB total, not tracked in Git).

## Notes

- The timezone `TZ=America/Los_Angeles` is set inside containers for reproducible test results.

## License

Defects4J is distributed under its own license; see the
[upstream repository](https://github.com/rjust/defects4j). This repo only provides
the container build and packaging layer.
