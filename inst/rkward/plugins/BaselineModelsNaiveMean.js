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

    echo('ts_data <- ts(na.omit(' + data + '[["' + target + '"]]), frequency = ' + freq + ', start = c(' + yr + ', ' + pd + '))\n\n');

    if (method === 'naive') echo('naive_forecast <- forecast::naive(ts_data, h = ' + h + ')\n');
    else if (method === 'snaive') echo('naive_forecast <- forecast::snaive(ts_data, h = ' + h + ')\n');
    else if (method === 'meanf') echo('naive_forecast <- forecast::meanf(ts_data, h = ' + h + ')\n');
    else if (method === 'rwf') echo('naive_forecast <- forecast::rwf(ts_data, h = ' + h + ', drift = TRUE)\n');

    echo('\n');
    var title_str = (main_tit !== '') ? main_tit : 'Baseline Forecast for ' + target;
    echo('p <- ggplot2::autoplot(naive_forecast) + \n');
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
		new Header(i18n("Baseline Models (Naive & Mean) results")).print();	
	}
    var w = getValue('naive_plot_w');
    var h = getValue('naive_plot_h');
    var res = getValue('naive_plot_res'); // <-- Resolución

    if (typeof is_preview !== 'undefined' && is_preview) {
        echo('print(p)\n');
    }

    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header("Baseline Forecast")\n');

        // Pasamos la resolución a rk.graph.on
        echo('rk.graph.on(width = ' + w + ', height = ' + h + ', res = ' + res + ')\n');
        echo('print(p)\n');

        if (getValue('naive_plot_save.active')) {
            echo('  naive_plot <- p\n');
        }
        echo('rk.graph.off()\n\n');

        echo('rk.header("Forecasted Values", level = 3)\n');
        echo('rk.print(as.data.frame(naive_forecast))\n');

        if (getValue('naive_save.active') || getValue('naive_plot_save.active')) { echo('rk.print("<hr>")\n'); }
        if (getValue('naive_save.active')) { echo('rk.print(paste0("<b>Forecast object saved as: </b><code>", "' + getValue('naive_save') + '", "</code><br>"))\n'); }
        if (getValue('naive_plot_save.active')) { echo('rk.print(paste0("<b>Plot object (ggplot) saved as: </b><code>", "' + getValue('naive_plot_save') + '", "</code>"))\n'); }
    }
  
	if(!is_preview) {
		//// save result object
		// read in saveobject variables
		var naiveSave = getValue("naive_save");
		var naiveSaveActive = getValue("naive_save.active");
		var naiveSaveParent = getValue("naive_save.parent");		var naivePlotSave = getValue("naive_plot_save");
		var naivePlotSaveActive = getValue("naive_plot_save.active");
		var naivePlotSaveParent = getValue("naive_plot_save.parent");
		// assign object to chosen environment
		if(naiveSaveActive) {
			echo(".GlobalEnv$" + naiveSave + " <- naive_forecast\n");
		}
		if(naivePlotSaveActive) {
			echo(".GlobalEnv$" + naivePlotSave + " <- naive_plot\n");
		}	
	}

}

