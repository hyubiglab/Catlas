# CATLAS v4

CATLAS v4 is an interactive R Shiny application for exploring colorectal cancer single-cell RNA sequencing data, with a focus on lncRNA expression. Users can search for any feature available in the supplied Seurat object.

This version improves UMAP and violin plot displays and makes the positive-expression threshold visible in both plots. The v4 implementation preserves the existing v3 files and uses the original RDS as read-only input.

## Features

- Explore gene expression on interactive UMAP and violin plots.
- Compare Normal and Tumor conditions side by side.
- Filter cells by condition, cell type, subtype, and sample.
- Group results by cell type, subtype, sample, condition, or patient.
- View per-group expression summaries, cell composition, and metadata.
- Download the current per-group summary as a CSV file.

## Changes from v3

| Issue | Behavior in v3 | Improvement in v4 |
| --- | --- | --- |
| Overlapping expression colorbars | Each condition panel created a separate colorbar at the same default position, and expression color limits were determined separately. | Condition panels share one expression color scale and a single colorbar when cells above the threshold are present. |
| Missing Normal panel title | Individual `layout(title=...)` settings were combined into a single figure title by `subplot()`. | Normal and Tumor titles are placed separately above their respective panels. |
| No gap between split violin halves | Both condition halves used the same category center. | The halves are shifted slightly left and right to create a small gap, while group labels remain centered. |
| Small cell-type legend markers | Both UMAP points and legend markers used size 3. | UMAP points retain size 3, while legend markers use size 6. Each group has one legend entry, and clicking it toggles that group across both condition panels. |
| Threshold changes were not visible in the plots | The threshold affected positivity notes and summaries but was not passed to the UMAP or violin functions. | Changing the threshold immediately updates gray UMAP cells and the dashed threshold line on the violin plot. |

## Positive-expression threshold

A cell is positive when **`expression > threshold`**. Cells with **`expression <= threshold`**, including cells exactly at the threshold, appear gray on the UMAP.

This rule applies to both UMAP color modes:

- **Expression:** Cells above the threshold use the shared continuous expression scale.
- **Group:** Cells above the threshold use their group color.

The violin plot shows the current threshold as a horizontal dashed line. Changing the threshold does not remove cells from the selected population, so the violin distributions, total cell counts, and the cells used to calculate means and medians remain unchanged.

The summary table and CSV contain the selected grouping column and these fields:

| Field | Description |
| --- | --- |
| `n_cells` | Total number of selected cells in the group. |
| `n_positive` | Number of cells with expression strictly greater than the threshold. |
| `pct_pos` | `100 * n_positive / n_cells`, rounded to one decimal place. |
| `threshold` | The threshold used for the summary. |
| `mean` | Mean expression across all selected cells in the group, rounded to three decimal places. |
| `median` | Median expression across all selected cells in the group, rounded to three decimal places. |

The slider maximum follows the selected gene's maximum expression, rounded upward to the next 0.1 increment, with a minimum upper limit of 3. When a different gene is selected, the current threshold is retained if it remains within the new range; otherwise, it is reduced to the new maximum.

Clearing all Condition or Cell type selections produces a message that no cells match the filters. Leaving the optional Sub-type or Sample selections empty applies no filter for that field.

## Files and data

| File | Purpose |
| --- | --- |
| [app.R](app.R) | Shiny interface, data loading, filters, summaries, and downloads. |
| [R/umap.R](R/umap.R) | UMAP panels, shared expression color scale, group legends, and threshold coloring. |
| [R/violin.R](R/violin.R) | Violin plots, condition spacing, and threshold overlays. |
| [start_catlas_v4.sh](start_catlas_v4.sh) | Launcher that configures paths, temporary directories, host, and port before starting R. |
| [tests/run_checks.R](tests/run_checks.R) | Synthetic regression checks for plot construction and Shiny reactive behavior. |

The original server layout uses:

- Application: `/home/minwook/Shiny_CRC_atlas/Catlas/v4/app.R`
- Read-only input data: `/home/minwook/Shiny_CRC_atlas/crc_shiny_app_seurat.rds`
- R executable: `/home/minwook/miniconda3/envs/crc_shiny/bin/R`

The application reads expression values from the RNA assay's `data` layer, with a fallback to the `data` slot for compatible Seurat versions.

## Requirements

Use a Linux environment with Bash and an R environment containing `shiny`, `Seurat`, `Matrix`, `ggplot2`, `dplyr`, `DT`, and `plotly`. The plotting code also uses `htmltools`, and the regression checks use `jsonlite`.

The launcher requires read access to the RDS file and write access to its temporary-directory parent. By default, temporary files are created under `v4/tmp_for_catlas`, with directory permissions set to `0700`.

## Preview on the original server

The launcher defaults to `127.0.0.1:4510`. At the time v4 was prepared, the documented production service used v3 on port 4510. Confirm the current service configuration and use a separate available port for a v4 preview.

```bash
CATLAS_PORT=4511 bash /home/minwook/Shiny_CRC_atlas/Catlas/v4/start_catlas_v4.sh
```

The preview is accessible at `http://127.0.0.1:4511` on the server. This loopback address refers to the machine running the application. Keep the preview port distinct from the port used by an existing service.

The v4 implementation did not change the production systemd entry point or Apache configuration. Publishing code to the `v4` branch does not switch the running web service to v4.

For another server layout, set `CATLAS_PROJECT_DIR`, `CATLAS_APP_DIR`, `CATLAS_DATA_PATH`, and `CATLAS_R_BIN` to the appropriate locations. `CATLAS_TMP_ROOT`, `CATLAS_HOST`, and `CATLAS_PORT` can also be overridden through environment variables.

## Validation

Run the synthetic regression checks with the configured R environment:

```bash
/home/minwook/miniconda3/envs/crc_shiny/bin/Rscript /home/minwook/Shiny_CRC_atlas/Catlas/v4/tests/run_checks.R
```

The recorded v4 validation passed **54 synthetic regression checks**. These checks do not load the atlas RDS or start a web server. They cover:

- Condition panel titles and a shared expression color scale.
- UMAP point sizes, legend marker sizes, and linked legend groups.
- Gray-cell counts at different thresholds, including equality at the threshold.
- Split violin spacing, centered labels, and threshold lines.
- Reactive threshold and summary updates in the actual Shiny server function.
- Single-positive-cell cases, ensuring expression colors remain JSON arrays and retain the shared colorbar.

A separate recorded validation loaded the real RDS and initialized the application with **98,428 cells**.

The recorded Firefox review checked both panel titles, the single colorbar including single-positive-cell cases, size-6 legend markers and linked group toggles, violin spacing, and threshold lines. The headless test browser did not support WebGL, so the visual check of UMAP point colors used SVG rendering in a diagnostic view only. The application itself continues to use Plotly `scattergl` for UMAP cell points.
