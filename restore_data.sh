#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

rds_file="crc_shiny_app_seurat.rds"

if [[ -e "$rds_file" ]]; then
  sha256sum -c data/RDS.sha256
  echo "The existing RDS file is valid."
  exit 0
fi

sha256sum -c data/PARTS.sha256

tmp_file=$(mktemp "./.catlas-restore.XXXXXX")
trap 'rm -f -- "$tmp_file"' EXIT

cat data/crc_shiny_app_seurat.rds.part-00 \
    data/crc_shiny_app_seurat.rds.part-01 > "$tmp_file"

expected_hash=$(awk 'NR == 1 {print $1; exit}' data/RDS.sha256)
printf '%s  %s\n' "$expected_hash" "$tmp_file" | sha256sum -c -

mv -n -- "$tmp_file" "$rds_file"
sha256sum -c data/RDS.sha256
echo "RDS_RESTORE_OK"
