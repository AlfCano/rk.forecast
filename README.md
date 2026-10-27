# rk.forecast: Business Forecasting and Time Series for RKWard

![Version](https://img.shields.io/badge/Version-0.0.2-blue.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
![RKWard](https://img.shields.io/badge/Platform-RKWard-green)
[![R Linter](https://github.com/AlfCano/rk.forecast/actions/workflows/lintr.yml/badge.svg)](https://github.com/AlfCano/rk.forecast/actions/workflows/lintr.yml)
![AI Gemini](https://img.shields.io/badge/AI-Gemini-4285F4?logo=googlegemini&logoColor=white)

**A Zero-Code GUI Wrapper for the `forecast` Package Bringing Business Analytics to RKWard**

`rk.forecast` bridges the gap between advanced econometric tools and practical Business Analytics. Designed with modern forecasting workflows in mind (aligning with leading business analytics textbooks), this plugin provides a seamless, point-and-click interface to generate time series predictions, evaluate business KPIs (like MAPE and RMSE), and plot publication-ready graphics using `ggplot2`—all without writing a single line of R code.

---

## 🌟 Key Features

*   **Zero-Code Time Series:** Instantly convert standard data frames into time series (`ts`) objects by simply declaring the frequency (Monthly, Quarterly, etc.) and start dates through the GUI.
*   **Industry-Standard Algorithms:** Fully implements the `forecast` package engine. Auto-detect the best Error-Trend-Seasonality (ETS) models, or manually specify Holt-Winters (Additive/Multiplicative) methods.
*   **Baseline Benchmarking:** Easily generate Naive, Seasonal Naive, Mean, and Random Walk (with drift) forecasts to serve as a baseline for your advanced models.
*   **Business KPIs at a Glance:** Automatically extract highly interpretable accuracy metrics like **MAPE** (Mean Absolute Percentage Error), **RMSE**, and **MAE** to evaluate your models just like a data scientist.
*   **Beautiful `ggplot2` Output:** Generates predictive plots with confidence intervals (80% and 95%). Customize themes, titles, and axis labels directly from the menu.
*   **Advanced Export Control:** Save your interactive models or `ggplot` objects back to the R workspace, or export plots to disk (PNG, JPEG, PDF, SVG) with precise pixel dimensions and DPI resolution.
*   **Multilingual Ready:** Fully prepared for translation into English, Spanish, French, German, and Portuguese (Brazil).

---

## What's New in Version 0.0.2

*   **Fixed menu entry** Fixed duplicated menu.

## What's New in Version 0.0.1

*   **Initial Release:** Introduces 3 foundational tools perfectly grouped under RKWard's `Analysis > Time Series` menu.
*   **Holt-Winters Engine:** A robust interface for Exponential Smoothing, handling everything from flat data to complex seasonal trends.
*   **Native GUI Integration:** Implements real-time HTML previews of `ggplot2` objects and safe saving mechanisms using RKWard's core graphical devices.

---

## ⚙️ Prerequisites

You must have [RKWard](https://rkward.kde.org/) installed along with the following R packages. The plugin will automatically attempt to load them when required:

```R
install.packages(c("forecast", "ggplot2"))
```

---

## 🚀 Installation

You can install this plugin directly from GitHub using `remotes` or `devtools` inside your RKWard console:

```R
# Install the plugin
library("remotes")
install_github("AlfCano/rk.forecast")
```

Once installed, restart RKWard to ensure the new menu entries and translations appear correctly.

---

## 🛠️ Usage Workflow

This plugin adds three essential components under the **Analysis > Time Series** menu in RKWard:

### 1. Exponential Smoothing (Holt-Winters)
*The core tool for predicting data with trends and seasonality.*
*   **Data & Structure:** Select your raw data and define its seasonality (e.g., Monthly starting in 2020).
*   **Model Selection:** Let the `ets()` function auto-detect the best parameters, or force specific Holt-Winters additive/multiplicative models. Set your forecast horizon (h).
*   **Plot Options & Output:** Customize the look of your `ggplot2` chart. Export the graphic in high-resolution, and save both the forecast object and the plot to your Global Environment.

### 2. Baseline Models (Naive & Mean)
*Create benchmark models to prove your advanced algorithms are working.*
*   Instantly run Naive, Seasonal Naive, Mean, or Random Walk forecasts. 
*   Includes the same robust plotting and output customization as the main component.

### 3. Evaluate Accuracy (MAPE, RMSE)
*Extract business KPIs from any forecast object in your workspace.*
*   Pass any existing model to this tool to instantly generate a clean table containing In-Sample (or Out-of-Sample) accuracy metrics.
*   Tweak and re-export `ggplot2` visualizations of the evaluated model.

---

## 📊 Real-World Case Study: Beating the Baseline

To see the true power of `rk.forecast` in a Business Analytics context (such as the methodologies taught in Jaggia's *Business Analytics* textbook), let's predict airline ticket demand and prove our model's worth.

### Step 1: Prepare the Data
Open the **R Console** (bottom panel in RKWard) and paste this code to create a standard data frame mimicking a spreadsheet import:
```R
demand_data <- data.frame(ticket_sales = as.numeric(AirPassengers))
```

### Step 2: Fit an Advanced Model (Holt-Winters)
Go to **Analysis > Time Series > Exponential Smoothing (Holt-Winters)**.
1. **Data & Structure:** Select `demand_data` as the Data Frame and `ticket_sales` as the Target. Set Frequency to `Monthly (12)`, Start Year to `1949`, and Start Period to `1`.
2. **Model Selection:** Leave "Auto-detect best model (ETS)" checked, and set periods to forecast (h) to `24` (two years).
3. Click **Submit**.

**What to look for in the HTML Output:**
*   **The Plot:** The blue forecast line perfectly captures the upward trend and summer peaks, surrounded by 80% and 95% confidence intervals (your best/worst-case business scenarios).
*   **Model Summary:** The engine auto-detected an `ETS(M,A,M)` model (Multiplicative error, Additive trend, Multiplicative seasonality).
*   **Accuracy Metrics:** Look at the **MAPE** (Mean Absolute Percentage Error). It's approximately `2.77%`. This means your predictions are off by less than 3% on average!

### Step 3: Establish a Business Benchmark
*Can our complex model beat a simple, naive assumption?* Let's create a baseline. 
Go to **Analysis > Time Series > Baseline Models (Naive & Mean)**.
1. Input the same data structure as above.
2. In **Model Configuration**, select **Seasonal Naive**. *(Business translation: "Our forecast for next January is exactly what we sold this January").*
3. Set periods (h) to `24`, ensure "Save forecast object" is active, and hit **Submit**. 
*Notice how "blocky" and highly uncertain the baseline plot looks compared to our ETS model.*

### Step 4: The "Pitch" (Evaluate & Communicate)
Now comes the "Communicating with Numbers" phase. Let's evaluate both models professionally.
Go to **Analysis > Time Series > Evaluate Accuracy (MAPE, RMSE)**.
1. Put your benchmark (`naive_forecast`) into the **Model to Evaluate** slot, choose the "Minimal" theme, and hit **Submit**. Look at the MAPE: **~9.9%**.
2. Swap the model for your advanced one (`my_forecast`) and hit **Submit**. Look at the MAPE: **~2.77%**.

### Step 5: The Analyst's Conclusion
Using the HTML reports generated by the plugin, you can now write a data-backed business conclusion:

> *"Visual analysis confirms an excellent fit for the multiplicative trend. While our traditional baseline strategy (Seasonal Naive) yielded a Mean Absolute Percentage Error (MAPE) of 9.9%, implementing advanced exponential smoothing (ETS) **drastically reduced our error rate to just 2.77%**. Therefore, the deployment of this statistical model is highly justified, as it reduces our inventory and sales uncertainty by over 7% compared to basic planning."*


---

## 🌍 Internationalization (i18n)

The graphical interface automatically adapts to your RKWard language settings. Currently supported languages:
*   🇺🇸 English (Default)
*   🇪🇸 Spanish (Español)
*   🇫🇷 French (Français)
*   🇩🇪 German (Deutsch)
*   🇧🇷 Portuguese (Português do Brasil)

---

## 📝 License and Author

**Author:** Alfonso Cano ([@AlfCano](https://github.com/AlfCano))  
**Email:** alfonso.cano@correo.buap.mx  
*   **Assisted by:** Gemini, a large language model from Google.
*   **License:** GPL (>= 3)

This project is licensed under the **GPL (>= 3)** License.
