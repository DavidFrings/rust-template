# Anleitung für dieses Template

## Neues Projekt anlegen

1. Auf GitHub **Use this template → Create a new repository**. Der Repo-Name wird zum Crate-Namen.
2. Klonen und im Repo-Ordner `./scripts/init.sh` ausführen. Das Skript ersetzt die Platzhalter
   (Name, Autor, Jahr, Kontakt, Beschreibung), erzeugt die `Cargo.lock` und löscht diese Anleitung.
3. Committen und nach `main` pushen:
   ```sh
   git add -A && git commit -m "chore: initialize from template" && git push
   ```
4. Mit `gh auth login` angemeldet `./scripts/github-setup.sh` ausführen. Das Skript richtet Merge-Einstellungen,
   Labels, Security-Features und das Ruleset für `main` ein. Es muss **nach** dem ersten Push laufen,
   weil das Ruleset direkte Pushes auf `main` verbietet.
5. Den ersten Pull Request öffnen und unter **Checks** prüfen, dass es den Check `rust / result` gibt.
   Heißt er anders, `REQUIRED_CHECK` oben in `scripts/github-setup.sh` anpassen und das Skript erneut ausführen.

## Was enthalten ist

| Datei | Zweck |
|---|---|
| `Cargo.toml` | Edition 2024, `rust-version` und die `[lints]`-Tabellen (gleiche Lints in RustRover und CI) |
| `deny.toml` | Regeln für cargo-deny: erlaubte Lizenzen, Registries, Wildcards |
| `.github/workflows/ci.yml` | Ruft den Workflow `rust.yml` aus `rust-ci` auf |
| `.github/workflows/security.yml` | Ruft `rust-security.yml` auf, bei Änderungen an Dependencies und wöchentlich |
| `.github/workflows/pr-labels.yml` | Macht aus angehakten PR-Kästchen Labels |
| `.github/dependabot.yml` | Wöchentliche Updates für Cargo und Actions, gruppiert, mit einer Woche Cooldown |
| `.github/ISSUE_TEMPLATE/` | Formulare für Bugs und Feature-Wünsche mit Labels, keine leeren Issues |
| `.github/pull_request_template.md` | Art der Änderung (wird zu Labels) und Review-Checkliste |
| `.github/release.yml` | Kategorien für automatisch erzeugte Release Notes |
| `scripts/github-setup.sh` | Repo-Einstellungen, Labels, Security-Features und Ruleset per `gh` |
| `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `LICENSE` | Community- und Lizenzdateien (MIT, Contributor Covenant 2.1) |
| `.editorconfig`, `.gitattributes`, `.gitignore` | Einheitliche Formatierung, Zeilenenden und Ignore-Regeln |

## Platzhalter

`__PROJECT_NAME__`, `__GITHUB_OWNER__`, `__AUTHOR__`, `__YEAR__`, `__CONTACT_EMAIL__` und `__DESCRIPTION__`
werden von `scripts/init.sh` ersetzt.

## Gut zu wissen

- Rulesets sind bei **privaten** Repos nur mit bezahltem GitHub-Plan verfügbar. Auch Secret Scanning gibt es bei
  privaten Repos nicht kostenlos. `github-setup.sh` meldet solche Fälle als Hinweis und läuft weiter.
- Das Ruleset verlangt einen Pull Request, aber **keine** Freigabe durch eine zweite Person, sonst könntest du als
  Einzelentwickler nie mergen. Es verbietet Force-Pushes und Löschen von `main` und verlangt grüne CI.
- Die Lints in der `Cargo.toml` sind ein Vorschlag. Alles Auskommentierte lässt sich bei Bedarf aktivieren.
