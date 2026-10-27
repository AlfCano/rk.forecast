// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!

// define variables globally
    function cleanStr(val) {
        if(!val) return '';
        return val.replace(/'/g, "\\'").replace(/"/g, '\\"');
    }

    function parseVar(fullPath) {
        if (!fullPath) return '';
        var raw_col = '';
        if (fullPath.indexOf('[[') > -1) {
            var parts = fullPath.split('[[');
            var inner = parts[1].replace(']]', '');
            raw_col = inner.replace(/["']/g, '');
        } else if (fullPath.indexOf('$') > -1) {
            raw_col = fullPath.split('$')[1];
        } else {
            raw_col = fullPath;
        }
        return raw_col;
    }
  

function preview(){
	preprocess(true);
	calculate(true);
	printout(true);
}

function preprocess(is_preview){
	// add requirements etc. here
	if(is_preview) {
		echo("if(!base::require(forecast)){stop(" + i18n("Preview not available, because package forecast is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(forecast)\n");
	}	if(is_preview) {
		echo("if(!base::require(ggplot2)){stop(" + i18n("Preview not available, because package ggplot2 is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(ggplot2)\n");
	}
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

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

    echo('raw_vector <- ' + data + '[["' + target + '"]]\n');
    echo('raw_vector <- na.omit(raw_vector)\n\n');
    echo('ts_data <- ts(raw_vector, frequency = ' + freq + ', start = c(' + yr + ', ' + pd + '))\n\n');

    if (model === 'auto') {
        echo('ts_model <- forecast::ets(ts_data)\n');
    } else {
        echo('ts_model <- forecast::ets(ts_data, model = "' + model + '")\n');
    }

    // Aquí nos aseguramos de llamarlo 'my_forecast' (Regla #3)
    echo('my_forecast <- forecast::forecast(ts_model, h = ' + h + ')\n\n');

    // Construcción del objeto ggplot 'p'
    var title_str = (main_tit !== '') ? main_tit : 'Forecast for ' + target;
    echo('p <- ggplot2::autoplot(my_forecast) + \n');
    echo('     ggplot2::theme_' + theme + '() + \n');

    echo('     ggplot2::labs(title = "' + title_str + '"');
    if (x_tit !== '') echo(', x = "' + x_tit + '"');
    if (y_tit !== '') echo(', y = "' + y_tit + '"');
    echo(') + \n');
    echo('     ggplot2::theme(legend.position = "bottom")\n\n');
  
}

function printout(is_preview){
	// read in variables from dialog


	// printout the results
	if(!is_preview) {
		new Header(i18n("Exponential Smoothing (Holt-Winters) results")).print();	
	}
    var w = getValue('plot_w');
    var h = getValue('plot_h');
    var res = getValue('plot_res'); // <-- Obtenemos la resolución

    if (typeof is_preview !== 'undefined' && is_preview) {
        echo('print(p)\n');
    }

    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header("Business Forecasting: Exponential Smoothing")\n');

        // rk.graph.on() ahora con resolución (DPI)
        echo('rk.graph.on(width = ' + w + ', height = ' + h + ', res = ' + res + ')\n');
        echo('print(p)\n');

        if (getValue('plot_save.active')) {
            echo('  my_plot <- p\n');
        }
        echo('rk.graph.off()\n\n');

        echo('rk.header("Model Summary", level = 3)\n');
        echo('rk.print(summary(ts_model))\n');

        echo('rk.header("Accuracy Metrics (In-Sample)", level = 3)\n');
        echo('acc_table <- as.data.frame(forecast::accuracy(ts_model))\n');
        echo('rk.print(acc_table)\n');

        echo('rk.header("Forecasted Values", level = 3)\n');
        echo('rk.print(as.data.frame(my_forecast))\n');

        if (getValue('ts_save.active') || getValue('plot_save.active')) { echo('rk.print("<hr>")\n'); }
        if (getValue('ts_save.active')) { echo('rk.print(paste0("<b>Forecast object saved as: </b><code>", "' + getValue('ts_save') + '", "</code><br>"))\n'); }
        if (getValue('plot_save.active')) { echo('rk.print(paste0("<b>Plot object (ggplot) saved as: </b><code>", "' + getValue('plot_save') + '", "</code>"))\n'); }
    }
  
	if(!is_preview) {
		//// save result object
		// read in saveobject variables
		var tsSave = getValue("ts_save");
		var tsSaveActive = getValue("ts_save.active");
		var tsSaveParent = getValue("ts_save.parent");		var plotSave = getValue("plot_save");
		var plotSaveActive = getValue("plot_save.active");
		var plotSaveParent = getValue("plot_save.parent");
		// assign object to chosen environment
		if(tsSaveActive) {
			echo(".GlobalEnv$" + tsSave + " <- my_forecast\n");
		}
		if(plotSaveActive) {
			echo(".GlobalEnv$" + plotSave + " <- my_plot\n");
		}	
	}

}

