# CRC scRNA-seq Atlas Viewer (v2)
#
# Runtime policy:
# - The source RDS in the project root is read-only input.
# - R must be started by start_catlas_v2.sh (or with equivalent environment
#   variables) so its session tempdir is created under tmp_for_catlas.

app_dir_value <- Sys.getenv("CATLAS_APP_DIR", unset = "")
if (!nzchar(app_dir_value)) {
  app_dir_value <- getwd()
}
app_dir <- normalizePath(app_dir_value, winslash = "/", mustWork = TRUE)

project_dir_value <- Sys.getenv(
  "CATLAS_PROJECT_DIR",
  unset = file.path(app_dir, "..")
)
project_dir <- normalizePath(
  project_dir_value,
  winslash = "/",
  mustWork = TRUE
)

data_path_value <- Sys.getenv(
  "CATLAS_DATA_PATH",
  unset = file.path(project_dir, "crc_shiny_app_seurat.rds")
)
if (!file.exists(data_path_value)) {
  stop("CRC Atlas input RDS was not found: ", data_path_value)
}
data_path <- normalizePath(data_path_value, winslash = "/", mustWork = TRUE)

tmp_root_value <- Sys.getenv(
  "CATLAS_TMP_ROOT",
  unset = file.path(project_dir, "tmp_for_catlas")
)
if (!dir.exists(tmp_root_value)) {
  stop(
    "CRC Atlas temporary root does not exist: ",
    tmp_root_value,
    ". Start the app with start_catlas_v2.sh."
  )
}
tmp_root <- normalizePath(tmp_root_value, winslash = "/", mustWork = TRUE)

if (file.access(tmp_root, mode = 3L) != 0L) {
  stop("CRC Atlas temporary root is not writable/searchable: ", tmp_root)
}

runtime_tmp_dir <- normalizePath(
  tempdir(check = TRUE),
  winslash = "/",
  mustWork = TRUE
)
tmp_root_prefix <- paste0(tmp_root, .Platform$file.sep)
runtime_tmp_is_managed <- identical(runtime_tmp_dir, tmp_root) ||
  startsWith(runtime_tmp_dir, tmp_root_prefix)

if (!runtime_tmp_is_managed) {
  stop(
    "R tempdir is outside the managed CRC Atlas temporary root. ",
    "R tempdir is fixed when R starts, so launch this app with ",
    "start_catlas_v2.sh. Configured root: ", tmp_root,
    "; current tempdir: ", runtime_tmp_dir
  )
}

write_probe <- tempfile(pattern = "catlas_startup_", tmpdir = runtime_tmp_dir)
if (!isTRUE(file.create(write_probe))) {
  stop("Unable to create a file in the R session tempdir: ", runtime_tmp_dir)
}
unlink(write_probe)

message("CRC Atlas v2 startup configuration")
message("  app_dir: ", app_dir)
message("  data_path: ", data_path)
message("  TMPDIR: ", Sys.getenv("TMPDIR", unset = "<unset>"))
message("  tempdir: ", runtime_tmp_dir)

required_packages <- c(
  "shiny",
  "Seurat",
  "Matrix",
  "ggplot2",
  "dplyr",
  "DT",
  "ggrepel"
)
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1L), quietly = TRUE)
]
if (length(missing_packages) > 0L) {
  stop(
    "Missing required R package(s): ",
    paste(missing_packages, collapse = ", ")
  )
}

suppressPackageStartupMessages({
  library(shiny)
  library(Seurat)
  library(Matrix)
  library(ggplot2)
  library(dplyr)
  library(DT)
  library(ggrepel)
})

assert_ascii_text <- function(values, label) {
  values <- unique(as.character(values))
  values <- values[!is.na(values)]
  has_non_ascii <- grepl(
    "[^\\x20-\\x7E]",
    values,
    perl = TRUE,
    useBytes = TRUE
  )

  if (any(has_non_ascii)) {
    stop("Non-ASCII text found in user-visible ", label, ".")
  }

  invisible(TRUE)
}

obj <- readRDS(data_path)

DefaultAssay(obj) <- "RNA"

expr_mat <- tryCatch(
  GetAssayData(obj, assay = "RNA", layer = "data"),
  error = function(e) GetAssayData(obj, assay = "RNA", slot = "data")
)

umap_df <- as.data.frame(Embeddings(obj, "umap"))
umap_df$cell_id <- rownames(umap_df)

meta_df <- obj@meta.data

meta_df$Tissue <- as.character(meta_df$Condition)
meta_df$Sample <- as.character(meta_df$Library)
meta_df$Major_celltype <- as.character(meta_df$Cell_type_v2)
meta_df$Subtype <- as.character(meta_df$Cell_subtype_v2)

meta_df$Patient <- as.character(meta_df$Patient)
meta_df$Class <- as.character(meta_df$Class)
meta_df$Condition <- as.character(meta_df$Condition)
meta_df$Cell_type <- as.character(meta_df$Cell_type)
meta_df$Cell_subtype <- as.character(meta_df$Cell_subtype)

meta_df$cell_id <- rownames(meta_df)

plot_df_base <- left_join(umap_df, meta_df, by = "cell_id")

plot_df_base$label_celltype <- as.character(plot_df_base$Major_celltype)

stopifnot("Major_celltype" %in% colnames(plot_df_base))
stopifnot("label_celltype" %in% colnames(plot_df_base))

available_genes <- rownames(expr_mat)
display_metadata_columns <- c(
  "cell_id",
  "Patient",
  "Sample",
  "Tissue",
  "Major_celltype",
  "Subtype",
  "Class",
  "Condition"
)

assert_ascii_text(available_genes, "gene names")
for (column_name in display_metadata_columns) {
  assert_ascii_text(plot_df_base[[column_name]], column_name)
}

gene_expression_legend <- "Log-normalized expression"

ui <- fluidPage(
  titlePanel("CRC scRNA-seq Atlas Viewer"),

  sidebarLayout(
    sidebarPanel(
      selectInput(
        inputId = "reduction_color",
        label = "Color UMAP by",
        choices = c(
          "Tissue",
          "Major_celltype",
          "Subtype",
          "Patient",
          "Sample",
          "Class",
          "Condition"
        ),
        selected = "Major_celltype"
      ),

      selectInput(
        inputId = "tissue_filter",
        label = "Tissue filter",
        choices = c("All", sort(unique(plot_df_base$Tissue))),
        selected = "All"
      ),

      selectInput(
        inputId = "celltype_filter",
        label = "Cell type filter",
        choices = c("All", sort(unique(plot_df_base$Major_celltype))),
        selected = "All"
      ),

      selectizeInput(
        inputId = "gene",
        label = "Gene search",
        choices = NULL,
        selected = NULL,
        multiple = FALSE,
        options = list(
          placeholder = "Enter gene name, e.g. SNHG16",
          maxOptions = 100
        )
      ),

      selectInput(
        inputId = "vln_group",
        label = "Violin plot group",
        choices = c("Tissue", "Major_celltype", "Subtype", "Patient", "Sample"),
        selected = "Major_celltype"
      )
    ),

    mainPanel(
      tabsetPanel(
        tabPanel("UMAP", plotOutput("umap_plot", height = "700px")),
        tabPanel("Gene UMAP", plotOutput("gene_umap_plot", height = "700px")),
        tabPanel("Violin Plot", plotOutput("vln_plot", height = "650px")),
        tabPanel("Composition", plotOutput("composition_plot", height = "650px")),
        tabPanel("Metadata", DTOutput("metadata_table"))
      )
    )
  )
)

server <- function(input, output, session) {
  updateSelectizeInput(
    session,
    "gene",
    choices = available_genes,
    server = TRUE
  )

  filtered_df <- reactive({
    df <- plot_df_base

    if (input$tissue_filter != "All") {
      df <- df %>% filter(Tissue == input$tissue_filter)
    }

    if (input$celltype_filter != "All") {
      df <- df %>% filter(Major_celltype == input$celltype_filter)
    }

    df
  })

  output$umap_plot <- renderPlot({
    df <- filtered_df()

    validate(
      need(
        input$reduction_color %in% colnames(df),
        paste0("Column not found: ", input$reduction_color)
      )
    )

    df$label_celltype <- as.character(df$Major_celltype)

    label_df <- df %>%
      filter(!is.na(label_celltype)) %>%
      group_by(label_celltype) %>%
      summarise(
        UMAP_1 = median(UMAP_1, na.rm = TRUE),
        UMAP_2 = median(UMAP_2, na.rm = TRUE),
        .groups = "drop"
      )

    ggplot() +
      geom_point(
        data = df,
        aes(x = UMAP_1, y = UMAP_2, color = .data[[input$reduction_color]]),
        size = 0.25,
        alpha = 0.8
      ) +
      ggrepel::geom_label_repel(
        data = label_df,
        aes(x = UMAP_1, y = UMAP_2, label = label_celltype),
        inherit.aes = FALSE,
        size = 4,
        label.size = 0.2,
        fill = "white",
        alpha = 0.85,
        color = "black",
        max.overlaps = Inf,
        show.legend = FALSE
      ) +
      guides(
        color = guide_legend(
          override.aes = list(size = 5, alpha = 1)
        )
      ) +
      theme_classic() +
      coord_equal() +
      labs(color = input$reduction_color)
  })

  output$gene_umap_plot <- renderPlot({
    req(input$gene)
    validate(need(input$gene %in% available_genes, "Gene not found."))

    df <- filtered_df()

    expr_vec <- as.numeric(expr_mat[input$gene, df$cell_id])
    df$expression <- expr_vec

    df <- df %>% arrange(expression)
    df$label_celltype <- as.character(df$Major_celltype)

    label_df <- df %>%
      filter(!is.na(label_celltype)) %>%
      group_by(label_celltype) %>%
      summarise(
        UMAP_1 = median(UMAP_1, na.rm = TRUE),
        UMAP_2 = median(UMAP_2, na.rm = TRUE),
        .groups = "drop"
      )

    ggplot() +
      geom_point(
        data = df,
        aes(x = UMAP_1, y = UMAP_2, color = expression),
        size = 0.25,
        alpha = 0.8
      ) +
      scale_color_gradient(
        low = "lightgrey",
        high = "red",
        guide = guide_colorbar(
          barheight = grid::unit(5, "cm"),
          barwidth = grid::unit(0.5, "cm")
        )
      ) +
      ggrepel::geom_label_repel(
        data = label_df,
        aes(x = UMAP_1, y = UMAP_2, label = label_celltype),
        inherit.aes = FALSE,
        size = 4,
        label.size = 0.2,
        fill = "white",
        alpha = 0.85,
        color = "black",
        max.overlaps = Inf,
        show.legend = FALSE
      ) +
      theme_classic() +
      coord_equal() +
      labs(
        title = paste0(input$gene, " expression"),
        color = gene_expression_legend
      )
  })

  output$vln_plot <- renderPlot({
    req(input$gene)
    validate(need(input$gene %in% available_genes, "Gene not found."))

    df <- filtered_df()
    df$expression <- as.numeric(expr_mat[input$gene, df$cell_id])

    ggplot(
      df,
      aes(
        x = .data[[input$vln_group]],
        y = expression,
        fill = .data[[input$vln_group]]
      )
    ) +
      geom_violin(scale = "width", trim = TRUE) +
      geom_boxplot(width = 0.12, outlier.size = 0.2) +
      theme_classic() +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none"
      ) +
      labs(
        x = input$vln_group,
        y = "Expression",
        title = paste0(input$gene, " expression by ", input$vln_group)
      )
  })

  output$composition_plot <- renderPlot({
    df <- filtered_df()

    comp_df <- df %>%
      count(Tissue, Major_celltype) %>%
      group_by(Tissue) %>%
      mutate(freq = n / sum(n)) %>%
      ungroup()

    ggplot(comp_df, aes(x = Tissue, y = freq, fill = Major_celltype)) +
      geom_bar(stat = "identity", position = "fill") +
      theme_classic() +
      labs(
        x = "Tissue",
        y = "Cell fraction",
        fill = "Cell type"
      )
  })

  output$metadata_table <- renderDT({
    datatable(
      filtered_df() %>%
        select(
          cell_id,
          Patient,
          Sample,
          Tissue,
          Major_celltype,
          Subtype,
          nCount_RNA,
          nFeature_RNA,
          percent.mt
        ),
      options = list(pageLength = 20)
    )
  })
}

shinyApp(ui, server)
