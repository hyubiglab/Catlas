# Violin builders are kept independent of the Seurat object so their geometry
# and threshold overlays can be checked with small, synthetic data frames.
build_violin_plot <- function(df, group_var, compare, threshold) {
  stopifnot(is.data.frame(df), nrow(df) > 0L,
            all(c(group_var, "Condition", ".expr") %in% names(df)),
            length(threshold) == 1L, is.finite(threshold))

  df$.group_label <- as.character(df[[group_var]])
  df$.group_label[is.na(df$.group_label)] <- "(Missing)"
  df$.condition_label <- as.character(df$Condition)
  df$.condition_label[is.na(df$.condition_label)] <- "(Missing)"
  groups <- sort(unique(df$.group_label))
  conds <- sort(unique(df$.condition_label))
  df$.group_center <- match(df$.group_label, groups)

  # The threshold changes only this overlay. Every cell's original expression
  # remains in the violin, including zero and below-threshold expression.
  extent <- range(c(0, df$.expr[is.finite(df$.expr)], threshold))
  padding <- max(diff(extent) * 0.08, 0.1)
  y_range <- extent + c(-padding, padding)
  x_axis <- list(title = "", type = "linear", tickmode = "array",
                 tickvals = seq_along(groups), ticktext = groups,
                 range = c(0.4, length(groups) + 0.6),
                 zeroline = FALSE, automargin = TRUE)
  y_axis <- list(title = "log-norm expression", range = y_range,
                 zeroline = FALSE, automargin = TRUE)

  group_colors <- if (group_var == "Condition") cond_color(groups) else pal_for(groups)
  grouped_violin <- function(d) {
    p <- plotly::plot_ly()
    for (gg in groups[groups %in% d$.group_label]) {
      dg <- d[d$.group_label == gg, , drop = FALSE]
      p <- plotly::add_trace(
        p, type = "violin", x = dg$.group_center, y = dg$.expr,
        name = gg, legendgroup = gg, showlegend = FALSE,
        line = list(color = group_colors[[gg]]),
        fillcolor = group_colors[[gg]], opacity = 0.6,
        width = 0.8, points = FALSE, spanmode = "hard",
        box = list(visible = TRUE), meanline = list(visible = TRUE),
        hovertemplate = paste0(gg, "<br>Expression: %{y:.3f}<extra></extra>")
      )
    }
    plotly::layout(p, xaxis = x_axis, yaxis = y_axis)
  }

  panel_count <- 1L
  panel_titles <- character()
  split_conditions <- isTRUE(compare) && group_var != "Condition"
  if (split_conditions && length(conds) == 2L) {
    colors <- cond_color(conds)
    p <- plotly::plot_ly()
    for (ii in seq_along(conds)) {
      dc <- df[df$.condition_label == conds[ii], , drop = FALSE]
      # A category axis assigns both halves the exact same center. Numeric
      # centers leave a 0.12-unit gap while preserving one tick per cell group.
      # Fixed widths avoid automatic narrowing when one condition is absent
      # from a group. Plotly's default violin mode is overlay; with explicit
      # widths its violinmode setting has no effect (and R 4.11 warns on it).
      offset <- if (ii == 1L) -0.06 else 0.06
      p <- plotly::add_trace(
        p, type = "violin", x = dc$.group_center + offset, y = dc$.expr,
        name = conds[ii], legendgroup = conds[ii], legendrank = ii,
        showlegend = TRUE,
        side = if (ii == 1L) "negative" else "positive",
        line = list(color = colors[[conds[ii]]]),
        fillcolor = colors[[conds[ii]]], opacity = 0.6,
        width = 0.8, scalegroup = "conditions", scalemode = "width",
        points = FALSE, spanmode = "hard", meanline = list(visible = TRUE),
        customdata = dc$.group_label,
        hovertemplate = paste0("%{customdata}<br>", conds[ii],
                               "<br>Expression: %{y:.3f}<extra></extra>")
      )
    }
    p <- plotly::layout(p, xaxis = x_axis, yaxis = y_axis,
                        legend = list(traceorder = "normal"))
  } else if (split_conditions && length(conds) > 2L) {
    panels <- lapply(conds, function(cc) {
      grouped_violin(df[df$.condition_label == cc, , drop = FALSE])
    })
    p <- plotly::subplot(panels, nrows = 1, shareY = TRUE,
                         titleY = TRUE, margin = 0.02)
    panel_count <- length(conds)
    panel_titles <- conds
  } else {
    p <- grouped_violin(df)
  }

  # Add shapes and titles after subplot composition: layout(title=...) on
  # individual panels is a figure title and gets replaced during composition.
  axis_refs <- c("x", if (panel_count > 1L) paste0("x", 2:panel_count))
  shapes <- lapply(axis_refs, function(ref) {
    list(type = "line", xref = paste(ref, "domain"), yref = "y",
         x0 = 0, x1 = 1, y0 = threshold, y1 = threshold,
         layer = "above", line = list(color = "#595959", width = 1.5, dash = "dash"))
  })
  annotations <- lapply(seq_along(panel_titles), function(ii) {
    list(text = panel_titles[ii], x = 0.5, y = 1.07,
         xref = paste(axis_refs[ii], "domain"), yref = "paper",
         xanchor = "center", yanchor = "bottom", showarrow = FALSE,
         font = list(size = 12))
  })
  annotations[[length(annotations) + 1L]] <- list(
    text = paste0("Threshold = ", format(threshold, trim = TRUE, scientific = FALSE)),
    x = 1, y = threshold, xref = paste(tail(axis_refs, 1), "domain"), yref = "y",
    xanchor = "right", yanchor = "bottom", yshift = 3, showarrow = FALSE,
    bgcolor = "rgba(255,255,255,0.85)", font = list(size = 11, color = "#595959")
  )
  # subplot() leaves an empty shape list. R's recursive layout merge cannot
  # replace that unnamed list, so write the final shapes directly to layout.
  p$x$layout$shapes <- shapes
  plotly::layout(p, annotations = annotations,
                 margin = list(t = if (panel_count > 1L) 50 else 25,
                               r = 90, b = 75, l = 65))
}
