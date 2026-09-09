# Catlas

Catlas is an interactive Shiny web application for exploring colorectal cancer single-cell RNA sequencing data.

**[Open the Catlas web application](http://big2.hanyang.ac.kr/catlas/)**

This repository contains the application source code, the prepared Seurat dataset, and instructions for restoring the data and running the application.

## Features

- **UMAP:** Explore cells by tissue, patient, sample, and cell type.
- **Gene UMAP:** Visualize the expression of a selected gene on the UMAP embedding.
- **Violin plots:** Compare gene expression across selected groups.
- **Cell composition:** View cell-type proportions within the filtered data.
- **Metadata:** Browse cell annotations and quality-control metrics.

Tissue and cell-type filters allow users to focus on subsets of the atlas.

## Application data

The application loads `crc_shiny_app_seurat.rds`, a prepared Seurat object.

The recorded dataset checks report:

- **98,428 cells**
- **60,660 features in the RNA assay**
- **Approximately 2.53 GB for the RDS file**

Gene expression plots use the `RNA/data` layer. The recorded normalization method is Seurat `LogNormalize` with a scale factor of 10,000:

```text
ln(1 + raw UMI count / total UMI count in the cell * 10,000)
```

See [the validation record](v2/RUN_SUMMARY.md) for details about the checks performed.

## Repository contents

| Path | Description |
| --- | --- |
| `v2/app.R` | Shiny application |
| `v2/start_catlas_v2.sh` | Application launcher |
| `v2/README.md` | Server configuration and maintenance instructions |
| `v2/catlas-shiny.service.override.conf.example` | Example configuration for an existing systemd service |
| `data/` | RDS file parts stored with Git LFS, together with SHA-256 checksums |
| `restore_data.sh` | Data verification and restoration script |

## Requirements

The commands below target a Linux environment with:

- Git and Git LFS
- Bash and GNU core utilities
- R with these packages installed: `shiny`, `Seurat`, `Matrix`, `ggplot2`, `dplyr`, `DT`, and `ggrepel`
- Sufficient disk space for the Git LFS cache, downloaded file parts, and restored RDS file
- Sufficient memory to load and work with the Seurat object

R and package versions are not currently pinned in this repository.

## Download and restore the data

Repository access is required while this repository is private.

```bash
git clone https://github.com/hyubiglab/Catlas.git
cd Catlas
git lfs install --local
git lfs pull
bash restore_data.sh
```

The restoration script verifies the file parts and reconstructed RDS using SHA-256 checksums.

The restored file is placed at:

```text
Catlas/crc_shiny_app_seurat.rds
```

## Run the application

Activate the R environment containing the required packages. Confirm that the intended R executable is available:

```bash
command -v R
```

From the repository root, start the application:

```bash
CATLAS_PROJECT_DIR="$PWD" \
CATLAS_R_BIN="$(command -v R)" \
bash v2/start_catlas_v2.sh
```

Alternatively, set `CATLAS_R_BIN` to the absolute path of the R executable in the required environment.

By default, the application listens on `127.0.0.1:3838` on the machine where it is started.

The launcher sets the temporary-directory environment variables before starting R. This places R session files under `tmp_for_catlas` in the project directory.

## Server deployment

See [the server deployment instructions](v2/README.md) for systemd configuration and maintenance procedures.

Those instructions describe the original server environment and assume an existing `catlas-shiny.service`. Adapt the paths, service account, and port when deploying on another server. Configure the web server or reverse proxy to forward requests to the Shiny application.
