# CRC Atlas Shiny v3 — interactive lncRNA explorer

v3 keeps everything v2 established (read-only RDS in the project root, managed
`tmp_for_catlas`, the same startup contract) and replaces the **UI/plotting layer**
with an interactive, gene-centric explorer.

## What changed vs v2

| | v2 | v3 |
| --- | --- | --- |
| Plots | static `ggplot` PNG (`renderPlot`) | interactive **plotly** (hover / zoom / pan, WebGL) |
| Gene UMAP + Violin | separate tabs | **same screen**, one gene at a time |
| Filters | Tissue + Cell type (single-select) | Condition, Cell type, **Sub-type**, **Sample** (all multi-select) |
| Grouping | fixed per plot | one **`Split by`** toggle: Cell type / Sub-type / Sample / Condition / Patient |
| Tumor vs Normal | — | **side-by-side UMAP** + **split-violin** |
| Quantification | — | per-group **n / % positive / mean / median** + **CSV download** |

The data-access code (`GetAssayData(..., layer="data")`, `expr_mat[gene, cell_id]`,
`plot_df_base <- left_join(umap, meta)`) is unchanged from v2, so expression
values and the metadata mapping are identical:

```
Condition <- Condition           # Tumor / Normal   (compare axis)
Sample    <- Library
Major_celltype <- Cell_type_v2
Subtype        <- Cell_subtype_v2
Patient   <- Patient
```

## New dependency

v3 adds **`plotly`** on top of v2's packages. In the crc_shiny env:

```r
install.packages("plotly")
```

## Run

Same launcher as v2 — just point the app directory at `v3`:

```bash
CATLAS_PROJECT_DIR="$PWD" \
CATLAS_APP_DIR="$PWD/v3" \
CATLAS_R_BIN="$(command -v R)" \
bash v2/start_catlas_v2.sh
```

For systemd, change only `CATLAS_APP_DIR` (or `WorkingDirectory`) to `.../v3`;
port, temp dir, and service account stay the same.

## Condition categories

`Condition` may hold more than two categories (e.g. **Tumor / Normal /
Malignant / Epithelial**). With *Compare conditions side-by-side* on:

- **2 selected conditions** → back-to-back **split violin** + 2-panel UMAP
- **3+ selected conditions** → one **violin facet per condition** + N-panel UMAP

Use the sidebar **Condition** checkboxes to restrict the comparison (e.g. tick
only Tumor + Normal for the classic side-by-side view). Known categories get
stable colors (`COND_PAL` in `app.R`); adjust that vector to taste.

## Notes / roadmap

- 98k points render via `scattergl` (WebGL). If the server GPU/soft-render is
  slow, add optional downsampling for the UMAP display only (stats stay exact).
- Gene search is by symbol (feature rownames), same as v2. Alias / genomic-
  coordinate search can be added with a small lookup table if desired.
- Planned: UMAP lasso ↔ violin linked highlight; Tumor-vs-Normal Wilcoxon
  badge per group; Dockerfile + CI.
