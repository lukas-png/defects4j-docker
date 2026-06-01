# Defects4J — vorgebaute Container-Images

Docker-/Podman-Images für [Defects4J](https://github.com/rjust/defects4j), bei
denen alle aktiven Bugs schon zur Build-Zeit ausgecheckt und kompiliert sind.
Container starten mit einem fertig befüllten `/work`, also ohne Download und
ohne Compile beim Start.

## Voraussetzungen

- Docker oder Podman (`build_all.sh` nutzt standardmäßig `podman`)
- Das Repo-Bundle unter `base/defects4j-repos.zip` (mehrere hundert MB, nicht im
  Git-Repo enthalten, siehe `.gitignore`)
- Mehrere GB freier Plattenplatz pro Image

## Bauen

```bash
# alle Versionen bauen
./build.sh

# nur eine Version (Filter auf den Kontextnamen)
./build.sh 2.
```

Verfügbare Versionen:

| Image             | Defects4J | Java   |
|-------------------|-----------|--------|
| `defects4j:0.1.0` | 0.1.0     | Java 7 |
| `defects4j:1.4.0` | 1.4.0     | Java 7 |
| `defects4j:2.0.0` | 2.0.0     | Java 8 |

Ein Build dauert pro Version deutlich über eine Stunde (kompletter Checkout +
Compile aller Bugs) und erzeugt mehrere GB große Images.

## Benutzen

```bash
# Container starten — landet direkt in /work
docker run --rm -it defects4j:2.0.0

# einen Bug verwenden
cd /work/Lang_1
defects4j test
```

Jeder Bug liegt unter `/work/<Projekt>_<BugID>`, z. B. `/work/Math_5`,
`/work/Closure_42`. Enthalten sind alle Projekte mit aktiven Bugs (Chart, Math,
Lang, Time, Closure, Cli, Codec, Collections, Compress, Csv, Gson, JacksonCore,
JacksonDatabind, JacksonXml, Jsoup, JxPath, Mockito).

### Änderungen persistieren

`/work` als Volume mounten. Ein leeres Volume wird beim ersten Start aus dem
Cache (`/opt/d4j-cache`) befüllt:

```bash
docker run --rm -it -v "$PWD/work-2.0.0:/work" defects4j:2.0.0
```

### Einzelnen Bug neu auschecken

```bash
d4j-checkout Lang-1            # nach /work/Lang-1
d4j-checkout Math-5 /tmp/m5    # in ein eigenes Verzeichnis
```

## Hinweise

- Die Zeitzone `TZ=America/Los_Angeles` ist für reproduzierbare Tests gesetzt
  und sollte nicht geändert werden.
- Fehlgeschlagene Checkouts beim Build stehen in `/work/checkout_failures.log`;
  der Build bricht dadurch nicht ab.
- Die Java-Version ist pro Defects4J-Version festgelegt (siehe Tabelle) und für
  korrekte Bug-Reproduktion erforderlich.

## Lizenz

Defects4J steht unter seiner eigenen Lizenz, siehe das
[Upstream-Repository](https://github.com/rjust/defects4j). Dieses Repo liefert
nur die Container-Build- und Bereitstellungsschicht darum herum.
