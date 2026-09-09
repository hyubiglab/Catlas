# Catlas

Source code and application data for the Catlas Shiny web service.

## Files

- `v2/`: Shiny application, launcher, and deployment instructions.
- `data/`: RDS file parts managed with Git LFS and SHA-256 checksums.
- `restore_data.sh`: Verifies and reconstructs the original RDS file.

## Download and restore

Git, Git LFS, and access to this private repository are required.

```sh
git clone https://github.com/hyubiglab/Catlas.git
cd Catlas
git lfs install --local
git lfs pull
bash restore_data.sh
```

The restored file is `crc_shiny_app_seurat.rds` in the repository root.

## Run the application

See `v2/README.md` for required packages and deployment details.
From the repository root, run:

```sh
CATLAS_PROJECT_DIR="$PWD" bash v2/start_catlas_v2.sh
```

If needed, set `CATLAS_R_BIN` to the absolute path of the R executable
in the environment containing the required packages.
