local({
  # =========================================================================================
  # 1. Setup and Metadata
  # =========================================================================================
  require(rkwarddev)

  plugin_name <- "rk.forecast"

  about_info <- rk.XML.about(
    name = plugin_name,
    author = person(
      given = "Alfonso",
      family = "Cano",
      email = "alfonso.cano@correo.buap.mx",
      role = c("aut", "cre")
    ),
    about = list(
      desc = "Business Forecasting: Exponential Smoothing, Holt-Winters, and Accuracy Metrics",
      version = "0.0.1",
      url = "https://github.com/AlfCano/rk.forecast",
      license = "GPL (>= 3)"
    )
  )

  dependencies_node <- rk.XML.dependencies(
    dependencies = list(R.min = "4.0.0"),
    package = list(c(name = "forecast"))
  )

  # Menu hierarchy: Analysis -> Time Series
  h_forecast <- list("analysis", "Time Series")

  # Global JavaScript Helper Functions
  js_helpers <- "
    function cleanStr(val) {
        if(!val) return '';
        return val.replace(/'/g, \"\\\\'\").replace(/\"/g, '\\\\\"');
    }

    function parseVar(fullPath) {
        if (!fullPath) return '';
        var raw_col = '';
        if (fullPath.indexOf('[[') > -1) {
            var parts = fullPath.split('[[');
            var inner = parts[1].replace(']]', '');
            raw_col = inner.replace(/[\"']/g, '');
        } else if (fullPath.indexOf('$') > -1) {
            raw_col = fullPath.split('$')[1];
        } else {
            raw_col = fullPath;
        }
        return raw_col;
    }
  "

  # =========================================================================================
  # 2. MAIN UI: Exponential Smoothing (ETS & Holt-Winters)
  # =========================================================================================

  # --- UI Elements ---

  # 2.1 Variables and Data Source
  ts_vs <- rk.XML.varselector(id.name = "ts_vs")
  ts_data <- rk.XML.varslot("Data Frame", source = "ts_vs", classes = "data.frame", required = TRUE, id.name = "ts_data")
  ts_target <- rk.XML.varslot("Target Variable to Forecast (Numeric)", source = "ts_vs", classes = c("numeric", "integer"), required = TRUE, id.name = "ts_target")

  # 2.2 Time Series Structure
  ts_freq <- rk.XML.dropdown("Data Frequency (Seasonality)", options = list(
    "Monthly (12)" = list(val = "12", chk = TRUE),
    "Quarterly (4)" = list(val = "4"),
    "Yearly (1)" = list(val = "1"),
    "Weekly (52)" = list(val = "52")
  ), id.name = "ts_freq")

  ts_start_yr <- rk.XML.spinbox("Start Year (e.g., 2018)", min = 1900, max = 2100, initial = 2020, real = FALSE, id.name = "ts_start_yr")
  ts_start_pd <- rk.XML.spinbox("Start Period (e.g., 1 for Jan/Q1)", min = 1, max = 52, initial = 1, real = FALSE, id.name = "ts_start_pd")

  frm_structure <- rk.XML.frame(ts_freq, rk.XML.row(ts_start_yr, ts_start_pd), label = "Time Series Structure", id.name = "frm_structure")

  # 2.3 Model Configuration
  ts_model <- rk.XML.radio("Smoothing Method", options = list(
    "Auto-detect best model (ETS)" = list(val = "auto", chk = TRUE),
    "Simple Exponential Smoothing (No Trend, No Seasonality)" = list(val = "ANN"),
    "Holt's Linear Trend (Trend, No Seasonality)" = list(val = "AAN"),
    "Holt-Winters Additive (Trend & Seasonality)" = list(val = "AAA"),
    "Holt-Winters Multiplicative (Trend & Seasonality)" = list(val = "MAM")
  ), id.name = "ts_model")

  ts_horizon <- rk.XML.spinbox("Periods to forecast (h)", min = 1, max = 120, initial = 12, real = FALSE, id.name = "ts_horizon")

  frm_model <- rk.XML.frame(ts_model, ts_horizon, label = "Model & Horizon", id.name = "frm_model")

  # 2.4 Output Options
  ts_save <- rk.XML.saveobj("Save forecast object as", initial = "my_forecast", chk = FALSE, id.name = "ts_save")

  # 2.5 Plot Customization
  ts_theme <- rk.XML.dropdown("Plot Theme (ggplot2)", options = list(
    "Minimal (Clean business look)" = list(val = "minimal", chk = TRUE),
    "Classic (Scientific)" = list(val = "classic"),
    "Black & White (Grid)" = list(val = "bw")
  ), id.name = "ts_theme")

  plot_main <- rk.XML.input("Main Title (Leave empty for default)", id.name = "plot_main")
  plot_xlab <- rk.XML.input("X-Axis Label (e.g., Time or Years)", id.name = "plot_xlab")
  plot_ylab <- rk.XML.input("Y-Axis Label", id.name = "plot_ylab")

  frm_plot <- rk.XML.frame(ts_theme, plot_main, plot_xlab, plot_ylab, label = "Plot Customization", id.name = "frm_plot")

  # 2.6 Output Options (Plot & Forecast)
  plot_w <- rk.XML.spinbox("HTML Plot Width (pixels)", min = 100, max = 5000, initial = 800, real = FALSE, id.name = "plot_w")
  plot_h <- rk.XML.spinbox("HTML Plot Height (pixels)", min = 100, max = 5000, initial = 600, real = FALSE, id.name = "plot_h")
  plot_res <- rk.XML.spinbox("Resolution (DPI)", min = 72, max = 600, initial = 120, real = FALSE, id.name = "plot_res")

  # Añadimos plot_res a la misma fila (row)
  frm_graph_size <- rk.XML.frame(rk.XML.row(plot_w, plot_h, plot_res), label = "HTML Graphics Size & Resolution", id.name = "frm_graph_size")

  plot_save_obj <- rk.XML.saveobj("Save Plot as R Object (Workspace)", initial = "my_plot", chk = FALSE, id.name = "plot_save")
  frm_save_plot <- rk.XML.frame(plot_save_obj, label = "Save Plot Object", id.name = "frm_save_plot")

  # --- Layout ---
  tab_ts <- rk.XML.tabbook(tabs = list(
    "Data & Structure" = rk.XML.col(ts_data, ts_target, frm_structure, rk.XML.stretch()),
    "Model Selection" = rk.XML.col(frm_model, rk.XML.stretch()),
    "Plot Options" = rk.XML.col(frm_plot, rk.XML.stretch()),
    "Output" = rk.XML.col(
      rk.XML.frame(ts_save, label = "Save Forecast to Workspace"),
      frm_graph_size,    # <-- Recuadro de tamaño en píxeles
      frm_save_plot,
      rk.XML.stretch()
    )
  ))

  # --- Preview ---

  ts_preview <- rk.XML.preview(label = "Preview Forecast Plot")

  # --- Logic for UI ---
  logic_ts <- rk.XML.logic(
    rk.XML.connect(governor = ts_data, get = "available", client = ts_vs, set = "root")
  )

  dialog_ts <- rk.XML.dialog(
    rk.XML.row(
      ts_vs,
      rk.XML.col(tab_ts, ts_preview)
    ),
    label = "Exponential Smoothing (Holt-Winters)"
  )

  # =========================================================================================
  # 3. JAVASCRIPT LOGIC
  # =========================================================================================

  js_calc_ts <- "
    var data = getValue('ts_data');
    var target = parseVar(getValue('ts_target'));
    var freq = getValue('ts_freq');
    var yr = getValue('ts_start_yr');
    var pd = getValue('ts_start_pd');
    var model = getValue('ts_model');
    var h = getValue('ts_horizon');
    var theme = getValue('ts_theme');

    var main_tit = cleanStr(getValue('plot_main'));
    var x_tit = cleanStr(getValue('plot_xlab'));
    var y_tit = cleanStr(getValue('plot_ylab'));

    echo('raw_vector <- ' + data + '[[\"' + target + '\"]]\\n');
    echo('raw_vector <- na.omit(raw_vector)\\n\\n');
    echo('ts_data <- ts(raw_vector, frequency = ' + freq + ', start = c(' + yr + ', ' + pd + '))\\n\\n');

    if (model === 'auto') {
        echo('ts_model <- forecast::ets(ts_data)\\n');
    } else {
        echo('ts_model <- forecast::ets(ts_data, model = \"' + model + '\")\\n');
    }

    // Aquí nos aseguramos de llamarlo 'my_forecast' (Regla #3)
    echo('my_forecast <- forecast::forecast(ts_model, h = ' + h + ')\\n\\n');

    // Construcción del objeto ggplot 'p'
    var title_str = (main_tit !== '') ? main_tit : 'Forecast for ' + target;
    echo('p <- ggplot2::autoplot(my_forecast) + \\n');
    echo('     ggplot2::theme_' + theme + '() + \\n');

    echo('     ggplot2::labs(title = \"' + title_str + '\"');
    if (x_tit !== '') echo(', x = \"' + x_tit + '\"');
    if (y_tit !== '') echo(', y = \"' + y_tit + '\"');
    echo(') + \\n');
    echo('     ggplot2::theme(legend.position = \"bottom\")\\n\\n');
  "

  js_print_ts <- "
    var w = getValue('plot_w');
    var h = getValue('plot_h');
    var res = getValue('plot_res'); // <-- Obtenemos la resolución

    if (typeof is_preview !== 'undefined' && is_preview) {
        echo('print(p)\\n');
    }

    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header(\"Business Forecasting: Exponential Smoothing\")\\n');

        // rk.graph.on() ahora con resolución (DPI)
        echo('rk.graph.on(width = ' + w + ', height = ' + h + ', res = ' + res + ')\\n');
        echo('print(p)\\n');

        if (getValue('plot_save.active')) {
            echo('  my_plot <- p\\n');
        }
        echo('rk.graph.off()\\n\\n');

        echo('rk.header(\"Model Summary\", level = 3)\\n');
        echo('rk.print(summary(ts_model))\\n');

        echo('rk.header(\"Accuracy Metrics (In-Sample)\", level = 3)\\n');
        echo('acc_table <- as.data.frame(forecast::accuracy(ts_model))\\n');
        echo('rk.print(acc_table)\\n');

        echo('rk.header(\"Forecasted Values\", level = 3)\\n');
        echo('rk.print(as.data.frame(my_forecast))\\n');

        if (getValue('ts_save.active') || getValue('plot_save.active')) { echo('rk.print(\"<hr>\")\\n'); }
        if (getValue('ts_save.active')) { echo('rk.print(paste0(\"<b>Forecast object saved as: </b><code>\", \"' + getValue('ts_save') + '\", \"</code><br>\"))\\n'); }
        if (getValue('plot_save.active')) { echo('rk.print(paste0(\"<b>Plot object (ggplot) saved as: </b><code>\", \"' + getValue('plot_save') + '\", \"</code>\"))\\n'); }
    }
  "


  # =========================================================================================
  # COMPONENT B: Naive & Baselines (Promedios Móviles y Naive)
  # =========================================================================================

  naive_vs <- rk.XML.varselector(id.name = "naive_vs")
  naive_data <- rk.XML.varslot("Data Frame", source = "naive_vs", classes = "data.frame", required = TRUE, id.name = "naive_data")
  naive_target <- rk.XML.varslot("Target Variable to Forecast (Numeric)", source = "naive_vs", classes = c("numeric", "integer"), required = TRUE, id.name = "naive_target")

  naive_freq <- rk.XML.dropdown("Data Frequency", options = list("Monthly (12)" = list(val = "12", chk = TRUE), "Quarterly (4)" = list(val = "4"), "Yearly (1)" = list(val = "1")), id.name = "naive_freq")
  naive_start_yr <- rk.XML.spinbox("Start Year", min = 1900, max = 2100, initial = 2020, real = FALSE, id.name = "naive_start_yr")
  naive_start_pd <- rk.XML.spinbox("Start Period", min = 1, max = 12, initial = 1, real = FALSE, id.name = "naive_start_pd")
  frm_naive_str <- rk.XML.frame(naive_freq, rk.XML.row(naive_start_yr, naive_start_pd), label = "Time Series Structure")

  naive_method <- rk.XML.radio("Baseline Method", options = list(
    "Naive (Last observation carries forward)" = list(val = "naive", chk = TRUE),
    "Seasonal Naive (Last season carries forward)" = list(val = "snaive"),
    "Mean Forecast (Average of all history)" = list(val = "meanf"),
    "Random Walk with Drift (Trend based on first/last)" = list(val = "rwf")
  ), id.name = "naive_method")
  naive_h <- rk.XML.spinbox("Periods to forecast (h)", min = 1, max = 120, initial = 12, real = FALSE, id.name = "naive_h")
  frm_naive_mod <- rk.XML.frame(naive_method, naive_h, label = "Model Configuration")

  # --- NUEVO: Plot Customization ---
  naive_theme <- rk.XML.dropdown("Plot Theme (ggplot2)", options = list(
    "Minimal (Clean business look)" = list(val = "minimal", chk = TRUE),
    "Classic (Scientific)" = list(val = "classic"),
    "Black & White (Grid)" = list(val = "bw")
  ), id.name = "naive_theme")

  naive_plot_main <- rk.XML.input("Main Title (Leave empty for default)", id.name = "naive_plot_main")
  naive_plot_xlab <- rk.XML.input("X-Axis Label (e.g., Time or Years)", id.name = "naive_plot_xlab")
  naive_plot_ylab <- rk.XML.input("Y-Axis Label", id.name = "naive_plot_ylab")

  # Marco único y correcto (incluye naive_theme)
  frm_naive_plot <- rk.XML.frame(naive_theme, naive_plot_main, naive_plot_xlab, naive_plot_ylab, label = "Plot Customization", id.name = "frm_naive_plot")


  # --- Output Options (Plot & Forecast) ---
  naive_plot_w <- rk.XML.spinbox("HTML Plot Width (pixels)", min = 100, max = 5000, initial = 800, real = FALSE, id.name = "naive_plot_w")
  naive_plot_h <- rk.XML.spinbox("HTML Plot Height (pixels)", min = 100, max = 5000, initial = 600, real = FALSE, id.name = "naive_plot_h")
  naive_plot_res <- rk.XML.spinbox("Resolution (DPI)", min = 72, max = 600, initial = 120, real = FALSE, id.name = "naive_plot_res")

  frm_naive_graph_size <- rk.XML.frame(rk.XML.row(naive_plot_w, naive_plot_h, naive_plot_res), label = "HTML Graphics Size & Resolution", id.name = "frm_naive_graph_size")

  naive_plot_save_obj <- rk.XML.saveobj("Save Plot as R Object (Workspace)", initial = "naive_plot", chk = FALSE, id.name = "naive_plot_save")
  frm_naive_save_plot <- rk.XML.frame(naive_plot_save_obj, label = "Save Plot Object", id.name = "frm_naive_save_plot")

  naive_save <- rk.XML.saveobj("Save forecast object as", initial = "naive_forecast", chk = FALSE, id.name = "naive_save")

  naive_preview <- rk.XML.preview(label = "Preview Forecast Plot")

  logic_naive <- rk.XML.logic(rk.XML.connect(governor = naive_data, get = "available", client = naive_vs, set = "root"))

  tab_naive <- rk.XML.tabbook(tabs = list(
    "Data & Structure" = rk.XML.col(naive_data, naive_target, frm_naive_str, rk.XML.stretch()),
    "Model Configuration" = rk.XML.col(frm_naive_mod, rk.XML.stretch()),
    "Plot Options" = rk.XML.col(frm_naive_plot, rk.XML.stretch()),
    "Output" = rk.XML.col(
      rk.XML.frame(naive_save, label = "Save Forecast to Workspace"),
      frm_naive_graph_size,  # <-- Se agrega aquí el tamaño
      frm_naive_save_plot,
      naive_preview,
      rk.XML.stretch()
    )
  ))

  dialog_naive <- rk.XML.dialog(
    rk.XML.row(
      naive_vs,
      rk.XML.col(tab_naive)
    ),
    label = "Baseline Models (Naive & Mean)"
  )



 js_calc_naive <- "
    var data = getValue('naive_data');
    var target = parseVar(getValue('naive_target'));
    var freq = getValue('naive_freq');
    var yr = getValue('naive_start_yr');
    var pd = getValue('naive_start_pd');
    var method = getValue('naive_method');
    var h = getValue('naive_h');
    var theme = getValue('naive_theme');

    var main_tit = cleanStr(getValue('naive_plot_main'));
    var x_tit = cleanStr(getValue('naive_plot_xlab'));
    var y_tit = cleanStr(getValue('naive_plot_ylab'));

    echo('ts_data <- ts(na.omit(' + data + '[[\"' + target + '\"]]), frequency = ' + freq + ', start = c(' + yr + ', ' + pd + '))\\n\\n');

    if (method === 'naive') echo('naive_forecast <- forecast::naive(ts_data, h = ' + h + ')\\n');
    else if (method === 'snaive') echo('naive_forecast <- forecast::snaive(ts_data, h = ' + h + ')\\n');
    else if (method === 'meanf') echo('naive_forecast <- forecast::meanf(ts_data, h = ' + h + ')\\n');
    else if (method === 'rwf') echo('naive_forecast <- forecast::rwf(ts_data, h = ' + h + ', drift = TRUE)\\n');

    echo('\\n');
    var title_str = (main_tit !== '') ? main_tit : 'Baseline Forecast for ' + target;
    echo('p <- ggplot2::autoplot(naive_forecast) + \\n');
    echo('     ggplot2::theme_' + theme + '() + \\n');

    echo('     ggplot2::labs(title = \"' + title_str + '\"');
    if (x_tit !== '') echo(', x = \"' + x_tit + '\"');
    if (y_tit !== '') echo(', y = \"' + y_tit + '\"');
    echo(') + \\n');
    echo('     ggplot2::theme(legend.position = \"bottom\")\\n\\n');
  "

  js_print_naive <- "
    var w = getValue('naive_plot_w');
    var h = getValue('naive_plot_h');
    var res = getValue('naive_plot_res'); // <-- Resolución

    if (typeof is_preview !== 'undefined' && is_preview) {
        echo('print(p)\\n');
    }

    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header(\"Baseline Forecast\")\\n');

        // Pasamos la resolución a rk.graph.on
        echo('rk.graph.on(width = ' + w + ', height = ' + h + ', res = ' + res + ')\\n');
        echo('print(p)\\n');

        if (getValue('naive_plot_save.active')) {
            echo('  naive_plot <- p\\n');
        }
        echo('rk.graph.off()\\n\\n');

        echo('rk.header(\"Forecasted Values\", level = 3)\\n');
        echo('rk.print(as.data.frame(naive_forecast))\\n');

        if (getValue('naive_save.active') || getValue('naive_plot_save.active')) { echo('rk.print(\"<hr>\")\\n'); }
        if (getValue('naive_save.active')) { echo('rk.print(paste0(\"<b>Forecast object saved as: </b><code>\", \"' + getValue('naive_save') + '\", \"</code><br>\"))\\n'); }
        if (getValue('naive_plot_save.active')) { echo('rk.print(paste0(\"<b>Plot object (ggplot) saved as: </b><code>\", \"' + getValue('naive_plot_save') + '\", \"</code>\"))\\n'); }
    }
  "

  comp_naive <- rk.plugin.component("Baseline Models (Naive & Mean)", xml = list(dialog = dialog_naive, logic = logic_naive), js = list(require = c("forecast", "ggplot2"), globals = js_helpers, calculate = js_calc_naive, printout = js_print_naive), hierarchy = h_forecast)

 # =========================================================================================
  # COMPONENT C: Error Metrics & Evaluation (MAPE, RMSE & ggplot2)
  # =========================================================================================

  eval_vs <- rk.XML.varselector(id.name = "eval_vs")
  eval_model <- rk.XML.varslot("Select a Forecast Object from Workspace", source = "eval_vs", classes = "forecast", required = TRUE, id.name = "eval_model")

  eval_theme <- rk.XML.dropdown("Plot Theme (ggplot2)", options = list(
    "Minimal (Clean business look)" = list(val = "minimal", chk = TRUE),
    "Classic (Scientific)" = list(val = "classic"),
    "Black & White (Grid)" = list(val = "bw")
  ), id.name = "eval_theme")

  # --- NUEVO: Plot Customization ---
  eval_plot_main <- rk.XML.input("Main Title (Leave empty for default)", id.name = "eval_plot_main")
  eval_plot_xlab <- rk.XML.input("X-Axis Label (Leave empty for default)", id.name = "eval_plot_xlab")
  eval_plot_ylab <- rk.XML.input("Y-Axis Label (Leave empty for default)", id.name = "eval_plot_ylab")

  frm_eval_plot <- rk.XML.frame(eval_plot_main, eval_plot_xlab, eval_plot_ylab, label = "Plot Customization", id.name = "frm_eval_plot")

  # --- NUEVO: Export Options (Plot) ---
  # --- Output Options ---
  eval_plot_w <- rk.XML.spinbox("HTML Plot Width (pixels)", min = 100, max = 5000, initial = 800, real = FALSE, id.name = "eval_plot_w")
  eval_plot_h <- rk.XML.spinbox("HTML Plot Height (pixels)", min = 100, max = 5000, initial = 600, real = FALSE, id.name = "eval_plot_h")
  eval_plot_res <- rk.XML.spinbox("Resolution (DPI)", min = 72, max = 600, initial = 120, real = FALSE, id.name = "eval_plot_res")

  frm_eval_graph_size <- rk.XML.frame(rk.XML.row(eval_plot_w, eval_plot_h, eval_plot_res), label = "HTML Graphics Size & Resolution", id.name = "frm_eval_graph_size")

  eval_plot_save_obj <- rk.XML.saveobj("Save ggplot Object as", initial = "eval_plot", chk = FALSE, id.name = "eval_plot_save")
  frm_eval_save_plot <- rk.XML.frame(eval_plot_save_obj, label = "Save Plot Object", id.name = "frm_eval_save_plot")

  eval_preview <- rk.XML.preview(label = "Preview Evaluation Plot")

  # --- Layout (Pestañas) ---
  tab_eval <- rk.XML.tabbook(tabs = list(
    "Model & Theme" = rk.XML.col(
      rk.XML.frame(eval_model, label = "Model to Evaluate"),
      rk.XML.frame(eval_theme, label = "Visualization Settings"),
      rk.XML.stretch()
    ),
    "Plot Options" = rk.XML.col(
      frm_eval_plot,
      rk.XML.stretch()
    ),
    "Output" = rk.XML.col(
      frm_eval_graph_size,   # <-- Se agrega aquí el tamaño
      frm_eval_save_plot,
      eval_preview,
      rk.XML.stretch()
    )
  ))



  dialog_eval <- rk.XML.dialog(
    rk.XML.row(
      eval_vs,
      rk.XML.col(tab_eval)
    ),
    label = "Evaluate Accuracy (MAPE, RMSE)"
  )

  # --- Javascript ---
  js_calc_eval <- "
    var model = getValue('eval_model');
    var theme = getValue('eval_theme');

    // Capturamos los títulos de la UI
    var main_tit = cleanStr(getValue('eval_plot_main'));
    var x_tit = cleanStr(getValue('eval_plot_xlab'));
    var y_tit = cleanStr(getValue('eval_plot_ylab'));

    var title_str = (main_tit !== '') ? main_tit : 'Forecast Evaluation';

    // Construcción limpia del objeto ggplot 'p'
    echo('p <- ggplot2::autoplot(' + model + ') + \\n');
    echo('     ggplot2::theme_' + theme + '() + \\n');

    echo('     ggplot2::labs(title = \"' + title_str + '\"');
    if (x_tit !== '') echo(', x = \"' + x_tit + '\"');
    if (y_tit !== '') echo(', y = \"' + y_tit + '\"');
    echo(') + \\n');

    echo('     ggplot2::theme(legend.position = \"bottom\")\\n\\n');

    // Métricas
    echo('acc_full <- as.data.frame(forecast::accuracy(' + model + '))\\n');
    echo('acc_kpi <- acc_full[, intersect(colnames(acc_full), c(\"RMSE\", \"MAE\", \"MAPE\")), drop = FALSE]\\n');
  "

  js_print_eval <- "
    var w = getValue('eval_plot_w');
    var h = getValue('eval_plot_h');
    var res = getValue('eval_plot_res'); // <-- Resolución

    if (typeof is_preview !== 'undefined' && is_preview) {
        echo('print(p)\\n');
    }

    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header(\"Forecast Evaluation & Business KPIs\")\\n');

        // Pasamos la resolución a rk.graph.on
        echo('rk.graph.on(width = ' + w + ', height = ' + h + ', res = ' + res + ')\\n');
        echo('print(p)\\n');

        if (getValue('eval_plot_save.active')) {
            echo('  eval_plot <- p\\n');
        }
        echo('rk.graph.off()\\n\\n');

        echo('rk.header(\"Key Performance Indicators (Accuracy)\", level = 3)\\n');
        echo('rk.print(acc_kpi)\\n');

        if (getValue('eval_plot_save.active')) {
            echo('rk.print(\"<hr>\")\\n');
            echo('rk.print(paste0(\"<b>Plot object (ggplot) saved as: </b><code>\", \"' + getValue('eval_plot_save') + '\", \"</code>\"))\\n');
        }
    }
  "

  comp_eval <- rk.plugin.component("Evaluate Accuracy (MAPE, RMSE)", xml = list(dialog = dialog_eval), js = list(require = c("forecast", "ggplot2"), globals = js_helpers, calculate = js_calc_eval, printout = js_print_eval), hierarchy = h_forecast)

  # =========================================================================================
  # 4. BUILD SKELETON
  # =========================================================================================

  unlink("rk.forecast", recursive = TRUE)

  rk.plugin.skeleton(
    about = about_info,
    path = ".",
    xml = list(dialog = dialog_ts, logic = logic_ts),
    js = list(require = c("forecast", "ggplot2"), globals = js_helpers, calculate = js_calc_ts, printout = js_print_ts),
    # AGREGAMOS AQUÍ LOS DOS NUEVOS COMPONENTES:
    components = list(comp_naive, comp_eval),
    pluginmap = list(name = "Exponential Smoothing (Holt-Winters)", hierarchy = h_forecast),
    dependencies = dependencies_node,
    create = c("pmap", "xml", "js", "desc", "rkh"),
    overwrite = TRUE,
    load = TRUE
  )

  cat("\nPhase 1: 'rk.forecast' generated successfully.\n")
})
