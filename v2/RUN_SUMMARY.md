# Run Summary - 20260909

## Changes

- Left `CRC_shiny_running.R`, `temp_shiny_obj_preprocessing.R`, and
  `crc_shiny_app_seurat.rds` unchanged.
- Added `v2/app.R` as the Shiny entry point.
- Added `v2/start_catlas_v2.sh` to set `TMPDIR`, `TMP`, and `TEMP` before R
  starts.
- Created `tmp_for_catlas` with owner `minwook:minwook` and mode `0700`.
- Set the Gene UMAP legend to `Log-normalized expression`.
- Added a startup check for non-ASCII user-visible data.

## Expression check

- Seurat object version: 5.0.1
- RNA assay dimensions: 60,660 features by 98,428 cells
- Layer used by the app: `RNA/data`
- Stored command: `NormalizeData.RNA`
- Normalization method: `LogNormalize`
- Scale factor: `10000`
- Formula: `ln(1 + raw UMI / cell total UMI * 10,000)`
- A direct recalculation of 1,455,840 values across 24 sampled cells matched
  the stored `RNA/data` values with a maximum absolute difference of zero.

## Validation

- R syntax check for `app.R`: passed
- Bash syntax check for `start_catlas_v2.sh`: passed
- Required R packages: passed
- Session temp-directory creation and write test: passed
- User-visible ASCII data check: passed
- Full RDS load and Shiny initialization: passed
- The validation host does not permit opening a local TCP socket, so the HTTP
  listener was not tested there.
- Temporary files remaining after the test: none
