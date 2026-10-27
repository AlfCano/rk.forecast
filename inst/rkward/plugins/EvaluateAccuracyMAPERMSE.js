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

    var model = getValue('eval_model');
    var theme = getValue('eval_theme');

    // Capturamos los títulos de la UI
    var main_tit = cleanStr(getValue('eval_plot_main'));
    var x_tit = cleanStr(getValue('eval_plot_xlab'));
    var y_tit = cleanStr(getValue('eval_plot_ylab'));

    var title_str = (main_tit !== '') ? main_tit : 'Forecast Evaluation';

    // Construcción limpia del objeto ggplot 'p'
    echo('p <- ggplot2::autoplot(' + model + ') + \n');
    echo('     ggplot2::theme_' + theme + '() + \n');

    echo('     ggplot2::labs(title = "' + title_str + '"');
    if (x_tit !== '') echo(', x = "' + x_tit + '"');
    if (y_tit !== '') echo(', y = "' + y_tit + '"');
    echo(') + \n');

    echo('     ggplot2::theme(legend.position = "bottom")\n\n');

    // Métricas
    echo('acc_full <- as.data.frame(forecast::accuracy(' + model + '))\n');
    echo('acc_kpi <- acc_full[, intersect(colnames(acc_full), c("RMSE", "MAE", "MAPE")), drop = FALSE]\n');
  
}

function printout(is_preview){
	// read in variables from dialog


	// printout the results
	if(!is_preview) {
		new Header(i18n("Evaluate Accuracy (MAPE, RMSE) results")).print();	
	}
    var w = getValue('eval_plot_w');
    var h = getValue('eval_plot_h');
    var res = getValue('eval_plot_res'); // <-- Resolución

    if (typeof is_preview !== 'undefined' && is_preview) {
        echo('print(p)\n');
    }

    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header("Forecast Evaluation & Business KPIs")\n');

        // Pasamos la resolución a rk.graph.on
        echo('rk.graph.on(width = ' + w + ', height = ' + h + ', res = ' + res + ')\n');
        echo('print(p)\n');

        if (getValue('eval_plot_save.active')) {
            echo('  eval_plot <- p\n');
        }
        echo('rk.graph.off()\n\n');

        echo('rk.header("Key Performance Indicators (Accuracy)", level = 3)\n');
        echo('rk.print(acc_kpi)\n');

        if (getValue('eval_plot_save.active')) {
            echo('rk.print("<hr>")\n');
            echo('rk.print(paste0("<b>Plot object (ggplot) saved as: </b><code>", "' + getValue('eval_plot_save') + '", "</code>"))\n');
        }
    }
  
	if(!is_preview) {
		//// save result object
		// read in saveobject variables
		var evalPlotSave = getValue("eval_plot_save");
		var evalPlotSaveActive = getValue("eval_plot_save.active");
		var evalPlotSaveParent = getValue("eval_plot_save.parent");
		// assign object to chosen environment
		if(evalPlotSaveActive) {
			echo(".GlobalEnv$" + evalPlotSave + " <- eval_plot\n");
		}	
	}

}

