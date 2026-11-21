#!/bin/bash

# Genera los manifiestos YAML a partir de values.yaml + templates/
# (solo generación, no aplica nada)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALUES_FILE="${SCRIPT_DIR}/values.yaml"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"
OUTPUT_DIR="${SCRIPT_DIR}/output"

echo "=== Generando manifiestos (frontend) ==="

if [ ! -f "$VALUES_FILE" ]; then
    echo "Error: No se encontro values.yaml"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Parsear key=value de forma literal (NO usar "source": <AWSAccountId> seria
# interpretado como redireccion) y exportar cada variable
while IFS='=' read -r key value || [ -n "$key" ]; do
    key="${key//[[:space:]]/}"
    [ -z "$key" ] && continue
    [[ "$key" == \#* ]] && continue
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    [ -z "$value" ] && continue
    export "$key=$value"
done < "$VALUES_FILE"

for template in "$TEMPLATES_DIR"/*.yaml; do
    filename=$(basename "$template")
    cp "$template" "$OUTPUT_DIR/$filename"

    # Reemplazar cada variable ${KEY} con awk
    awk '{
        line = $0
        while (match(line, /\$\{[A-Z_0-9]+\}/)) {
            var = substr(line, RSTART + 2, RLENGTH - 3)
            value = ENVIRON[var]
            if (value != "") {
                line = substr(line, 1, RSTART - 1) value substr(line, RSTART + RLENGTH)
            } else {
                break
            }
        }
        print line
    }' "$OUTPUT_DIR/$filename" > "$OUTPUT_DIR/$filename.tmp"
    mv "$OUTPUT_DIR/$filename.tmp" "$OUTPUT_DIR/$filename"

    echo "   - $filename"
done

echo ""
echo "=== Archivos generados en $OUTPUT_DIR ==="
ls -la "$OUTPUT_DIR"
