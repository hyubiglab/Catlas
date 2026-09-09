# CRC Atlas Shiny v2

This version keeps the R session directory outside `/tmp`. It prevents a
long-running Shiny process from losing its session files when the operating
system cleans `/tmp/RtmpXXXXXX`.

The source R code and RDS remain unchanged. The app reads the RDS directly from
the project root.

## Files

- `app.R`: Shiny entry point with startup checks for the data and temp paths.
- `start_catlas_v2.sh`: sets `TMPDIR`, `TMP`, and `TEMP` before starting R.
- `catlas-shiny.service.override.conf.example`: systemd drop-in for the existing
  service.
- `input_manifest.tsv`: list of source and runtime paths.
- `RUN_SUMMARY.md`: implementation and validation record.

## Gene UMAP expression

Gene UMAP reads the `data` layer of the Seurat `RNA` assay. The stored
`NormalizeData.RNA` command uses `LogNormalize` with a scale factor of 10,000:

```text
ln(1 + raw UMI count / total UMI count in the cell * 10,000)
```

The plot legend is displayed as `Log-normalized expression`.

At startup, the app checks every user-visible gene name, cell ID, and metadata
value for non-ASCII text. The app stops before serving pages if the check fails.
The source RDS is never changed by this check.

## Temp directory

R selects its session temp directory when the process starts. Changing
`TMPDIR` from inside `app.R` does not move an existing session directory. Start
the app with `start_catlas_v2.sh`, or set the same environment variables in
systemd before R starts.

The configured parent directory is:

```text
/home/minwook/Projects/BRL/SNHG16/Shiny_CRC_atlas/tmp_for_catlas
```

R creates a separate `RtmpXXXXXX` directory below it for each process.

## Check the current service

Run these commands on R440 before installing the drop-in:

```bash
systemctl cat catlas-shiny.service
systemctl show catlas-shiny.service \
  -p User -p Group -p WorkingDirectory -p ExecStart -p Environment \
  -p PrivateTmp -p ProtectHome -p ReadWritePaths
```

The supplied drop-in uses port `3838` and
`/home/minwook/anaconda3/envs/crc_shiny/bin/R`. Keep the current production
port if it differs. The service account must own `tmp_for_catlas`; its expected
mode is `0700`. If the unit restricts home-directory access, allow read access
to the project and write access to `tmp_for_catlas`.

## Install the systemd drop-in

```bash
install -d -m 0755 /etc/systemd/system/catlas-shiny.service.d
install -m 0644 \
  /home/minwook/Projects/BRL/SNHG16/Shiny_CRC_atlas/v2/catlas-shiny.service.override.conf.example \
  /etc/systemd/system/catlas-shiny.service.d/override.conf
systemctl daemon-reload
systemctl restart catlas-shiny.service
```

A restart is required because the running R process cannot change its existing
session temp directory. The restart may take time while the 2.53 GB RDS loads.

## Verify the deployment

```bash
systemctl status catlas-shiny.service --no-pager -l
journalctl -u catlas-shiny.service -n 100 --no-pager
```

The startup log should contain paths in this form:

```text
TMPDIR=/home/minwook/Projects/BRL/SNHG16/Shiny_CRC_atlas/tmp_for_catlas
tempdir: /home/minwook/Projects/BRL/SNHG16/Shiny_CRC_atlas/tmp_for_catlas/RtmpXXXXXX
```
