/*
publications_by_GBD.do


*/

cap log close
clear all
pause on

local plot 1
local combine 0

global repo "C:\Users\lmostrom\Documents\GitHub\healthcare_trends\"

cap cd "C:\Users\lmostrom\Documents\Amitabh\"

if 	`plot' == 1 {
*================================================================================
foreach pub_ct in /*""*/ "CT_" {
*================================================================================
	import delimited "PubMed_Search_Results_`pub_ct'GBDlev2_from1980.csv", varn(1) clear

	split query_name, gen(disease_area) p("_")
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
	import delimited "IHME_GBD_highSDI_lev2\IHME-GBD_2017_DATA-b793d0ef-2.csv", ///
		varn(1) clear
	tempfile pg2
	save `pg2', replace

	import delimited "IHME_GBD_highSDI_lev2\IHME-GBD_2017_DATA-b793d0ef-1.csv", ///
		varn(1) clear

	append using `pg2'

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

	merge m:1 cause_abbr year using `pubmed'


	cap mkdir "GBD_Plots"
	if "`pub_ct'" == "" local yvar "Publications"
	else local yvar "Clinical Trials"

	foreach measure in "YLLs (Years of Life Lost)" "DALYs (Disability-Adjusted Life Years)" {
		foreach loc in "United States" "High SDI" {
			foreach sex in "Both" "Female" "Male" {
				foreach metric in "Number" "Percent" "Rate" {
				forval yr = 1997(10)2017 {
					cap mkdir "GBD_Plots/`yr'/"
					if "`pub_ct'" == "" local excl_folder "excl_Neoplasms_and_Cardiovasc/"
					*if "`pub_ct'" == "CT_" local excl_folder "excl_Neoplasms/"
					cap mkdir "GBD_Plots/`yr'/`excl_folder'"
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

							if "`pub_ct'" == "" local if_st if !inlist(cause_abbr, "neoplasms", "cardio");
							*if "`pub_ct'" == "CT_" local if_st if !inlist(cause_abbr, "neoplasms");

							reg pubs_nih0 val `if_st';
								predict reg_nih0 `if_st';
							reg pubs_nih1 val `if_st';
								predict reg_nih1 `if_st';
						*pause;
						tw  /*(scatter pubs_nih0 val if metric_name == "`metric'"
													& sex_name == "`sex'"
													& location_name == "`loc'"
													& measure_name == "`measure'"
													& year == 1997, mc(eltblue) mfc(none) yaxis(1))*/
							(scatter pubs_nih0 val `if_st', mc(blue) mfc(none) /*yaxis(1)*/)
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
							(scatter pubs_nih1 val `if_st', mc(red) mfc(none) /*yaxis(2)*/)
							/*(scatter pubs_nih1 val if metric_name == "`metric'"
													& sex_name == "`sex'"
													& location_name == "`loc'"
													& measure_name == "`measure'"
													& year == 2017, mc(cranberry) mfc(none) yaxis(2))*/
							(line reg_nih0 val `if_st', lc(blue) /*yaxis(1)*/)
							(line reg_nih1 val `if_st', lc(red) /*yaxis(2)*/),
						  legend(order(1 "Non-NIH" 2 "NIH" /*3 "Non-NIH, 2017"
						  			   4 "NIH, 1997" 5 "NIH, 2007" 6 "NIH, 2017"*/) r(1) colfirst)
						  xti("`measure', `metric'") title("PubMed `yvar'")
						  yti("`yvar'", axis(1)) /*yti("NIH `yvar'", axis(2))*/
						  subtitle("Country: `loc'" "Sex: `sex'" "`yr'");
						graph export "GBD_Plots/`yr'/`excl_folder'/scatter_`pub_ct'`metric'-`sex'-`loc'-`measure'.png",
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

if `combine' == 1 {
	cd GBD_Plots
	forval yr = 1997(10)2017 {

		#delimit;
		grc1leg "`yr'/scatter_CT_Number-Both-High SDI-DALYs (Disability-Adjusted Life Years).png"
				"`yr'/scatter_CT_Number-Both-United States-DALYs (Disability-Adjusted Life Years).png"
				"`yr'/scatter_Number-Both-High SDI-DALYs (Disability-Adjusted Life Years).png"
				"`yr'/scatter_Number-Both-United States-DALYs (Disability-Adjusted Life Years).png",
			legendfrom("`yr'/scatter_CT_Number-Both-High SDI-DALYs (Disability-Adjusted Life Years).png")

	}


}
