#!/usr/bin/env bash
# Ersetzt die Platzhalter in einem frisch aus dem Template erzeugten Repo.
# Danach löscht sich das Skript zusammen mit TEMPLATE.md.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

ask() { # ask VARIABLE "Frage" "Vorgabe"
  local var=$1 prompt=$2 default=${3:-} reply
  read -r -p "${prompt}${default:+ [$default]}: " reply
  printf -v "$var" '%s' "${reply:-$default}"
}

default_owner=""
if origin=$(git remote get-url origin 2>/dev/null); then
  default_owner=$(sed -E 's#.*[:/]([^/]+)/[^/]+$#\1#' <<<"${origin%.git}")
fi

ask PROJECT_NAME "Projektname (= Crate- und Repo-Name)" "$(basename "$PWD")"
ask GITHUB_OWNER "GitHub-Benutzer oder -Organisation" "$default_owner"
ask AUTHOR "Name für die LICENSE" "$(git config user.name || true)"
ask CONTACT_EMAIL "Kontakt-E-Mail (SECURITY.md, CODE_OF_CONDUCT.md)" "$(git config user.email || true)"
ask DESCRIPTION "Kurzbeschreibung" ""
YEAR=$(date +%Y)

if [[ ! $PROJECT_NAME =~ ^[a-z][a-z0-9_-]*$ ]]; then
  echo "Ungültiger Projektname '$PROJECT_NAME' (erlaubt: Kleinbuchstaben, Ziffern, - und _)" >&2
  exit 1
fi

# Sonderzeichen für sed (Trenner |, &, \) entschärfen
# shellcheck disable=SC2001
esc() { sed -e 's/[\\&|]/\\&/g' <<<"$1"; }

while IFS= read -r file; do
  [[ -f $file ]] || continue
  grep -qE '__(PROJECT_NAME|GITHUB_OWNER|AUTHOR|YEAR|CONTACT_EMAIL|DESCRIPTION)__' "$file" || continue
  sed -i \
    -e "s|__PROJECT_NAME__|$(esc "$PROJECT_NAME")|g" \
    -e "s|__GITHUB_OWNER__|$(esc "$GITHUB_OWNER")|g" \
    -e "s|__AUTHOR__|$(esc "$AUTHOR")|g" \
    -e "s|__YEAR__|$YEAR|g" \
    -e "s|__CONTACT_EMAIL__|$(esc "$CONTACT_EMAIL")|g" \
    -e "s|__DESCRIPTION__|$(esc "$DESCRIPTION")|g" \
    "$file"
  echo "aktualisiert: $file"
done < <(git ls-files | grep -vE '^(scripts/init\.sh|TEMPLATE\.md)$')

# Template-Hinweis aus der README entfernen
sed -i '/<!-- template:start -->/,/<!-- template:end -->/d' README.md
sed -i '1{/^$/d}' README.md

if grep -rq 'DEIN-GITHUB-NAME' .github; then
  echo "WARNUNG: In .github/workflows steht noch DEIN-GITHUB-NAME. Bitte im Template ersetzen." >&2
fi

if command -v cargo >/dev/null 2>&1; then
  cargo generate-lockfile
  echo "Cargo.lock erzeugt (bitte mit einchecken, die CI baut mit --locked)."
else
  echo "cargo nicht gefunden: bitte 'cargo generate-lockfile' selbst ausführen und die Cargo.lock einchecken." >&2
fi

rm -f TEMPLATE.md scripts/init.sh

cat <<MSG

Fertig. Nächste Schritte:
  git add -A && git commit -m "chore: initialize from template" && git push
  ./scripts/github-setup.sh      # erst NACH dem ersten Push
MSG
