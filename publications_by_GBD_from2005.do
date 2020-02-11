/*
publications_by_GBD.do

*/

cap log close
clear all
pause on

local plot 1
	local ex_cancer 1 // run plots excluding cancer (and cardiovascular diseases, for papers only)
	local log_plot 1 // plot on log-log axes
	local lags = 0 // set to 0 for no lag on GBD, 2 for 2-year lag on GBD, etc.
	local leads = 0 // set to 0 for no lag on Publications, 2 for 2-year lag on Publications, etc.
	local deltas = 0 // set to 0 for levels, 2 for 2-year change, etc.
local combine 1

global repo "C:\Users\lmostrom\Documents\GitHub\healthcare_trends\"

cap cd "C:\Users\lmostrom\Dropbox\Amitabh\"

if 	`plot' == 1 {
*================================================================================
foreach pub_ct in "" "CT_" {
*================================================================================
	if "`pub_ct'" == "" local QA ""
	if "`pub_ct'" == "CT_" local QA "_notQA"

	import delimited "PubMed_Search_Results_`pub_ct'GBDlev2`QA'_from2005.csv", varn(1) clear

	split query_name, gen(disease_area) p("_")
		keep if inlist(disease_area2, "NIH", "Priv")
		gen nih = (disease_area2 == "NIH")
			drop disease_area2
		drop query_name
		ren pub_count pubs_nih
		ren disease_area1 cause_abbr
			replace cause_abbr = lower(cause_abbr)
		reshape wide pubs_nih, i(year cause_abbr) j(nih)

	tempfile pubmed
	save `pubmed', replace
	*================================================================================
	import delimited "IHME_GBD_highlowSDI_lev2\IHME-GBD_2017_DATA-7b7a6e96-1.csv", ///
		varn(1) clear

	save "IHME_GBD_2017_level2.dta", replace
	*================================================================================
	keep if age_name == "All Ages"

	gen cause_abbr = "cardio" if cause_name == "Cardiovascular diseases"
		replace cause_abbr = "chronicresp" if cause_name == "Chronic respiratory diseases"
		replace cause_abbr = "kidney" if cause_name == "Diabetes and kidney diseases"
		replace cause_abbr = "digestive" if cause_name == "Digestive diseases"
		replace cause_abbr = "enteritis" if cause_name == "Enteric infections"
		replace cause_abbr = "stis" if cause_name == "HIV/AIDS and sexually transmitted infections"
		replace cause_abbr = "pregnancy" if cause_name == "Maternal and neonatal disorders"
		replace cause_abbr = "mental" if cause_name == "Mental disorders"
		replace cause_abbr = "muscle" if cause_name == "Musculoskeletal disorders"
		replace cause_abbr = "tropic" if cause_name == "Neglected tropical diseases and malaria"
		replace cause_abbr = "neoplasms" if cause_name == "Neoplasms"
		replace cause_abbr = "neurologic" if cause_name == "Neurological disorders"
		replace cause_abbr = "nutrition" if cause_name == "Nutritional deficiencies"
		replace cause_abbr = "othinfectious" if cause_name == "Other infectious diseases"
		replace cause_abbr = "respinf" if cause_name == "Respiratory infections and tuberculosis"
		replace cause_abbr = "senses" if cause_name == "Sense organ diseases"
		replace cause_abbr = "skin" if cause_name == "Skin and subcutaneous diseases"
		replace cause_abbr = "substance" if cause_name == "Substance use disorders"

	merge m:1 cause_abbr year using `pubmed', keep(1 3)
		drop if cause_abbr == ""

	cap mkdir "GBD_Plots_from2005"
	if "`pub_ct'" == "" local yvar "Non-Trial Publications"
	else local yvar "Clinical Trial (II & III) Publications"

	egen cause_cat = group(cause_abbr measure_id location_id sex_id metric_id)
	xtset cause_cat year

	if `log_plot' == 1 { // ---------------------------------------------------------
		gen ln_pubs_nih0 = log10(pubs_nih0)
		gen ln_pubs_nih1 = log10(pubs_nih1)
		gen ln_val = log10(val)
		local mid_folder "loglog"
	} // ----------------------------------------------------------------------------

	if `lags' > 0 { // --------------------------------------------------------------
		gen L`lags'_val = l`lags'.val
		local mid_folder "L`lags'"
	} // ----------------------------------------------------------------------------

	if `leads' > 0 { // --------------------------------------------------------------
		gen L`leads'_pubs_nih0 = l`leads'.pubs_nih0
		gen L`leads'_pubs_nih1 = l`leads'.pubs_nih1
		local mid_folder "L`lags'"
	} // ----------------------------------------------------------------------------

	if `deltas' > 0 { // ------------------------------------------------------------
		gen d`deltas'_pubs_nih0 = pubs_nih0 - l`deltas'.pubs_nih0
		gen d`deltas'_pubs_nih1 = pubs_nih1 - l`deltas'.pubs_nih1
		gen d`deltas'_val = val - l`deltas'.val
		local mid_folder "d`deltas'"
	} // ----------------------------------------------------------------------------

	if `lags' + `leads' + `deltas' + `log_plot' == 0 local mid_folder ""

	gen val_MM = val/1000000

	foreach measure in "YLLs (Years of Life Lost)" "DALYs (Disability-Adjusted Life Years)" {
			local measure_sub = substr("`measure'", 1, 5)
		foreach loc in "United States" "High SDI" "Low SDI" {
			foreach sex in "Both" "Female" "Male" {
				foreach metric in "Number" /*"Percent" "Rate"*/ {
				forval yr = 2007(5)2017 {
					cap mkdir "GBD_Plots_from2005/`yr'/"
						cap mkdir "GBD_Plots_from2005/`yr'/`mid_folder'/"
						if `ex_cancer' == 1 { // ----------------------------------------------------
							if "`pub_ct'" == "" local excl_folder "excl_Neoplasms_and_Cardiovasc/"
							if "`pub_ct'" == "CT_" local excl_folder "excl_Neoplasms/"
						} // ------------------------------------------------------------------------

						if `log_plot' == 1 { // -----------------------------------------------------
							if "`pub_ct'" == "" {
								if `ex_cancer' == 1 local yticks "100(200)500"
								if `ex_cancer' == 0 local yticks "100(600)700"
							}
							if "`pub_ct'" == "CT_" {
								if `ex_cancer' == 1 local yticks "50(200)250"
								if `ex_cancer' == 0 local yticks "100(900)1000"
							}
							if substr("`measure'", 1, 3) == "YLL" & "`loc'" == "Low SDI" ///
								local xticks "20(60)80"
							else local xticks ""
						} // ------------------------------------------------------------------------
						else { // -------------------------------------------------------------------
							local yticks "#4"
							local xticks ""
						} // ------------------------------------------------------------------------

						cap mkdir "GBD_Plots_from2005/`yr'/`mid_folder'/`excl_folder'"
						cap mkdir "GBD_Plots_from2005/`yr'/`mid_folder'/`excl_folder'/gphs"
						
					/*forval nih01 = 0/1 {
						if `nih01' == 0 {
							local c1 "eltblue"
							local c2 "blue"
							local c3 "navy"
							local yt "Not NIH-Funded"
						}
						if `nih01' == 1 {
							local c1 "erose"
							local c2 "red"
							local c3 "cranberry"
							local yt "NIH-Funded"
						}*/

						#delimit ;

						preserve;
							keep if metric_name == "`metric'"
													& sex_name == "`sex'"
													& location_name == "`loc'"
													& measure_name == "`measure'"
													& year == `yr';
							replace pubs_nih1 = . if `log_plot' == 1 & "`pub_ct'" == "CT_" & pubs_nih1 == 0;
							replace pubs_nih0 = . if `log_plot' == 1 & "`pub_ct'" == "CT_" & pubs_nih0 == 0;

						if `ex_cancer' == 1 {; // ------------------------------------------------;
							if "`pub_ct'" == "" local if_st if !inlist(cause_abbr, "neoplasms", "cardio");
							if "`pub_ct'" == "CT_" local if_st if !inlist(cause_abbr, "neoplasms");
						}; // --------------------------------------------------------------------;

							if `log_plot' == 1 {; // -------------------------------------------------;
								reg ln_pubs_nih0 ln_val `if_st';
									predict reg_nih0 `if_st';
									gen pred_nih0 = 10^reg_nih0;
								reg ln_pubs_nih1 ln_val `if_st';
									predict reg_nih1 `if_st';
									gen pred_nih1 = 10^reg_nih1;

								local pubs "pubs";
								local xvar "val_MM";
								local xti_ext "";
								local yti_ext "";
								local log_axes "xscale(log) yscale(log)";
							}; // --------------------------------------------------------------------;

							if `lags' > 0 {; // ------------------------------------------------------;
								reg pubs_nih0 L`lags'_val `if_st';
									predict pred_nih0 `if_st';
								reg pubs_nih1 L`lags'_val `if_st';
									predict pred_nih1 `if_st';

								local pubs "pubs";
								local xvar "L`lags'_val";
								local xti_ext "Lagged `lags' Years";
								local yti_ext "";
								local log_axes "";
							}; // --------------------------------------------------------------------;

							if `leads' > 0 {; // -----------------------------------------------------;
								reg L`leads'_pubs_nih0 val `if_st';
									predict pred_nih0 `if_st';
								reg L`leads'_pubs_nih1 val `if_st';
									predict pred_nih1 `if_st';

								local pubs "L`leads'_pubs";
								local xvar "val";
								local xti_ext "";
								local yti_ext "Lagged `leads' Years";
								local log_axes "";
							}; // --------------------------------------------------------------------;

							if `deltas' > 0 {; // ----------------------------------------------------;
								reg d`deltas'_pubs_nih0 d`deltas'_val `if_st';
									predict pred_nih0 `if_st';
								reg d`deltas'_pubs_nih1 d`deltas'_val `if_st';
									predict pred_nih1 `if_st';

								local pubs "d`deltas'_pubs";
								local xvar "d`deltas'_val";
								local xti_ext "`deltas'-Year Change";
								local yti_ext "`deltas'-Year Change";
								local log_axes "";
							}; // --------------------------------------------------------------------;

							if `lags' + `leads' + `deltas' + `log_plot' == 0 {; // -------------------;
								reg pubs_nih0 val `if_st';
									predict pred_nih0 `if_st';
								reg pubs_nih1 val `if_st';
									predict pred_nih1 `if_st';

								local pubs "pubs";
								local xvar "val_MM";
								local xti_ext "";
								local yti_ext "";
								local log_axes "";
							}; // --------------------------------------------------------------------;

						*pause;
						sort val;
						tw  /*(scatter pubs_nih0 val if metric_name == "`metric'"
													& sex_name == "`sex'"
													& location_name == "`loc'"
													& measure_name == "`measure'"
													& year == 1997, mc(eltblue) mfc(none) yaxis(1))*/
							(scatter `pubs'_nih0 `xvar' `if_st',
								mc(green) mfc(none) `log_axes' /*yaxis(1)*/)
							/*(scatter pubs_nih0 val if metric_name == "`metric'"
													& sex_name == "`sex'"
													& location_name == "`loc'"
													& measure_name == "`measure'"
													& year == 2017, mc(navy) mfc(none) yaxis(1))*/
						    /*(scatter pubs_nih1 val if metric_name == "`metric'"
													& sex_name == "`sex'"
													& location_name == "`loc'"
													& measure_name == "`measure'"
													& year == 1997, mc(erose) mfc(none) yaxis(2))*/
							(scatter `pubs'_nih1 `xvar' `if_st',
								mc(red) mfc(none) `log_axes' /*yaxis(2)*/)
							/*(scatter pubs_nih1 val if metric_name == "`metric'"
													& sex_name == "`sex'"
													& location_name == "`loc'"
													& measure_name == "`measure'"
													& year == 2017, mc(cranberry) mfc(none) yaxis(2))*/
							(line pred_nih0 `xvar' `if_st',
								lc(green) `log_axes' /*yaxis(1)*/)
							(line pred_nih1 `xvar' `if_st',
								lc(red) `log_axes' /*yaxis(2)*/),
						  legend(order(2 "NIH Presence" 1 "No Public Presence" /*3 "Non-NIH, 2017"
						  			   4 "NIH, 1997" 5 "NIH, 2007" 6 "NIH, 2017"*/) r(1) colfirst)
						  xti("`measure_sub'" "(in Millions)" "`xti_ext'") xlab(`xticks', labs(small) /* angle(45) format(%9.0e)*/) title("`yvar'")
						  yti("`yvar'" "`yti_ext' ", axis(1)) ylab(`yticks', angle(45) labs(small))
						  		/*yti("NIH `yvar'", axis(2))*/
						  subtitle("Country: `loc'" /*"Sex: `sex'"*/ "`yr'");
						graph save "GBD_Plots_from2005/`yr'/`mid_folder'/`excl_folder'/gphs/scatter_`pub_ct'`metric'-`sex'-`loc'-`measure'.gph", replace;

						graph export "GBD_Plots_from2005/`yr'/`mid_folder'/`excl_folder'/scatter_`pub_ct'`metric'-`sex'-`loc'-`measure'.png",
								as(png) replace wid(1200) hei(700);

						restore;
						#delimit cr

					/*}*/
				} // year loop
				} // metric loop
			} // sex loop
		} // location loop


	} // measure loop
*================================================================================
} // loop over publications / clinical trials
*================================================================================
}


	if `combine' == 1 { // -----------------------------------------------------------------------------------
		cd GBD_Plots_from2005

		if `ex_cancer' == 1 {
			local excl_fld1 "excl_Neoplasms"
			local excl_fld2 "excl_Neoplasms_and_Cardiovasc"
		}
		if `log_plot' == 1 local mid_folder "loglog"

		forval yr = 2007(5)2017 {
		foreach measure in "YLLs (Years of Life Lost)" "DALYs (Disability-Adjusted Life Years)" {

			#delimit ;
			grc1leg /*"`yr'/`mid_folder'/`excl_fld1'/gphs/scatter_CT_Number-Both-High SDI-`measure'.gph" */
					"`yr'/`mid_folder'/`excl_fld1'/gphs/scatter_CT_Number-Both-Low SDI-`measure'.gph"
					"`yr'/`mid_folder'/`excl_fld1'/gphs/scatter_CT_Number-Both-United States-`measure'.gph"
					/*"`yr'/`mid_folder'/`excl_fld2'/gphs/scatter_Number-Both-High SDI-`measure'.gph"*/
					"`yr'/`mid_folder'/`excl_fld2'/gphs/scatter_Number-Both-Low SDI-`measure'.gph"
					"`yr'/`mid_folder'/`excl_fld2'/gphs/scatter_Number-Both-United States-`measure'.gph", r(2)
				legendfrom("`yr'/`mid_folder'/`excl_fld1'/gphs/scatter_CT_Number-Both-Low SDI-`measure'.gph");
			graph export "combined_`yr'_`measure'_`mid_folder'_`excl_fld1'.png", replace as(png) wid(1200) hei(700);
			#delimit cr

		} // measure loop
		} // year loop
	}