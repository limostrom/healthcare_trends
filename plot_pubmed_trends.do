/*

plot_pubmed_trends.do

*/

cap log close
clear all
set more off
pause on

local diseases_1980 0
local diseases_2005 0
local diseases_hhi 0
local BVPW_1980 0
local BVPW_2005 0
local BVPW_hhi 0
local topGBDs_1980 0
local topGBDs_2005 0
local topGBDs_hhi 0
local econ_1980 0
local econ_2005 0
local health_econ_1980 0
local all_1980 0
local all_2005 0
local pies 0
local pies_bydisease 0
local ts_bydisease 0
local pies_bydisease_sub 0
local nih_vs_priv 0
local drugs_and_devices 0
local ba_tr_cl 0
local ba_tr_cl_bydisease 0
local basic_msas 0
local alz 1


global repo "C:/Users/lmostrom/Documents/GitHub/healthcare_trends/"

if inlist(1, `drugs_and_devices', `ba_tr_cl', `ba_tr_cl_bydisease') ///
		include $repo/merge_drugs_devices_QA_list.do
*=======================================================================
*					DISEASE CATEGORIES (BODY SYSTEMS)
*=======================================================================
*-------------------------
if `diseases_1980' == 1 {
*-------------------------
cap cd "C:\Users\lmostrom\Documents\Amitabh\"
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~
foreach all_ct in "" "_CT" {
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~
import delimited "PubMed_Search_Results`all_ct'_byDisease_from1980.csv", varn(1) clear

if "`all_ct'" == "" local x = 2
if "`all_ct'" == "_CT" local x = 3

split query_name, gen(disease_area) p("_")
	gen nih = (disease_area`x' == "NIH")
	drop query_name
	ren pub_count count

cap replace count = "0" if count == "NA"
	cap destring count, replace

preserve
	ren count total
	keep if disease_area1 == "Total"
	*br
	*pause
	save "pubmed_results`all_ct'_byyear_total_1980.dta", replace
restore
preserve
	ren count totaldisease
	keep if disease_area1 == "TotalDisease"
	*br
	*pause
	save "pubmed_results`all_ct'_byyear_totaldisease_1980.dta", replace
restore

ren disease_area1 disease_area
keep if !inlist(disease_area, "Total", "TotalDisease")
replace disease_area = lower(disease_area)
drop disease_area`x'


save "pubmed_results`all_ct'_byyear_bydisease_1980.dta", replace

*-------------------------------------------------------------
if "`all_ct'" == "" local yvar "Publications"
if "`all_ct'" == "_CT" local yvar "Clinical Trials"
*-------------------------------------------------------------

bys nih year: egen sum_cats = total(count)
gen sh_of_total = count/sum_cats*100

merge m:1 year nih using "pubmed_results`all_ct'_byyear_total_1980.dta", nogen keep(1 3) keepus(total)
merge m:1 year nih using "pubmed_results`all_ct'_byyear_totaldisease_1980.dta", nogen keep(1 3) keepus(totaldisease)

if "`all_ct'" == "" keep if inrange(year, 1980, 2018)
else keep if inrange(year, 1992, 2018)

*** Plot Comparison of Sum of Articles by Disease Area vs. Total Articles on PubMed
	preserve
		egen tag_nih_yr = tag(year nih)
		keep if tag_nih_yr
		gen frac_disease = totaldisease/total
		gen frac_cat_coverage = sum_cats/totaldisease
		gen frac_cat_oftot = sum_cats/total

		#delimit ;
		tw (line frac_disease year if nih == 0, lc(blue))
		   (line frac_disease year if nih == 1, lc(red)),
		 legend(order(1 "Not NIH" 2 "NIH"))
		 /*yline(1, lc(gs8)) xline(1980, lp(-) lc(gs8))*/
		 yti("Fraction of `yvar' About Disease");
		graph export "disease_category_share_of_pubmed`all_ct'_1980-2018.png", replace as(png) wid(1200) hei(700);

		tw (line frac_cat_oftot year if nih == 0, lc(blue))
		   (line frac_cat_oftot year if nih == 1, lc(red)),
		 legend(order(1 "Not NIH" 2 "NIH"))
		 /*yline(1, lc(gs8)) xline(1980, lp(-) lc(gs8))*/
		 yti("Fraction of `yvar' from Body System Disease Categories");
		graph export "disease_body_systems_share_of_pubmed`all_ct'_1980-2018.png", replace as(png) wid(1200) hei(700);

		tw (line frac_cat_coverage year if nih == 0, lc(blue))
		   (line frac_cat_coverage year if nih == 1, lc(red)),
		 legend(order(1 "Not NIH" 2 "NIH"))
		 /*yline(1, lc(gs8)) xline(1980, lp(-) lc(gs8))*/
		 yti("Ratio of Sum of Category `yvar' to Total Disease `yvar'" "(Overcounting Ratio)");
		graph export "sum_of_disease_cats_div_by_disease_pubs`all_ct'_1980-2018.png", replace as(png) wid(1200) hei(700);
		#delimit cr

	restore

*** Plot Shares of All Research by Disease Area
	preserve
		collapse (sum) count, by(year disease_area)
		bys year: egen sum_cats = total(count)
		gen sh_of_total = count/sum_cats*100

		#delimit ;
		tw (line sh_of_total year if disease_area == "cardio", lc(cranberry) lp(-)) /* 1 */
		   (line sh_of_total year if disease_area == "cheminduced", lc(sienna) lp(_))
		   (line sh_of_total year if disease_area == "digestive", lc(erose) lp(--.))
		   (line sh_of_total year if disease_area == "endocrine", lc(dkorange) lp(l))
		   (line sh_of_total year if disease_area == "ent", lc(midgreen) lp(-.))
		   (line sh_of_total year if disease_area == "eye", lc(gs12) lp(_.)) /* 6 */
		   (line sh_of_total year if disease_area == "female", lc(pink) lp(__.))
		   (line sh_of_total year if disease_area == "hemic", lc(eltblue) lp(--.))
		   (line sh_of_total year if disease_area == "immune", lc(gs7) lp(.))
		   (line sh_of_total year if disease_area == "male", lc(blue) lp(_))
		   (line sh_of_total year if disease_area == "muscle", lc(gold) lp(-)) /* 11 */
		   (line sh_of_total year if disease_area == "neoplasms", lc(orange) lp(.))
		   (line sh_of_total year if disease_area == "nervous", lc(lavender) lp(_))
		   (line sh_of_total year if disease_area == "psych", lc(purple) lp(-))
		   (line sh_of_total year if disease_area == "respiratory", lc(navy) lp(_))
		   (line sh_of_total year if disease_area == "skin", lc(magenta) lp(_..)) /* 16 */
		   (line sh_of_total year if disease_area == "infectiousdiseases", lc(red) lp(.)),
		 legend(order(14 "Psychiatry & Psychology"
					  1  "Cardiovascular"
		 			  12 "Cancer"
		 			  13 "Nervous System & Cognition"
		 			  15 "Respiratory"
		 			  9  "Immune System"
		 			  7  "Female Urogential & Pregnancy"
		 			  11 "Musculoskeletal"
		 			  3  "Digestive"
		 			  16 "Skin & Connective Tissue"
		 			  10 "Male Urogenital"
		 			  8  "Hemic & Lymphomatic"
		 			  4  "Endocrine"
		 			  5  "ENT & Mouth"
		 			  6  "Eye"
					  /*2  "Chemically-Induced" - Silenced because no longer included in the queries*/
					  17 "Infectious Diseases") c(1) pos(3))
		 yti("Share of `yvar' (%)") title("All Funding Types");

		 graph export "pubmed_results_all`all_ct'_notwtd_1980-2018.png", replace as(png) wid(1600) hei(700);
		 #delimit cr

	restore

*** Plot Shares of Non-NIH-Funded Research by Disease Area
	#delimit ;
	tw (line sh_of_total year if nih == 0 & disease_area == "cardio", lc(cranberry) lp(-)) /* 1 */
	   (line sh_of_total year if nih == 0 & disease_area == "cheminduced", lc(sienna) lp(_))
	   (line sh_of_total year if nih == 0 & disease_area == "digestive", lc(erose) lp(--.))
	   (line sh_of_total year if nih == 0 & disease_area == "endocrine", lc(dkorange) lp(l))
	   (line sh_of_total year if nih == 0 & disease_area == "ent", lc(midgreen) lp(-.))
	   (line sh_of_total year if nih == 0 & disease_area == "eye", lc(gs12) lp(_.)) /* 6 */
	   (line sh_of_total year if nih == 0 & disease_area == "female", lc(pink) lp(__.))
	   (line sh_of_total year if nih == 0 & disease_area == "hemic", lc(eltblue) lp(--.))
	   (line sh_of_total year if nih == 0 & disease_area == "immune", lc(gs7) lp(.))
	   (line sh_of_total year if nih == 0 & disease_area == "male", lc(blue) lp(_))
	   (line sh_of_total year if nih == 0 & disease_area == "muscle", lc(gold) lp(-)) /* 11 */
	   (line sh_of_total year if nih == 0 & disease_area == "neoplasms", lc(orange) lp(.))
	   (line sh_of_total year if nih == 0 & disease_area == "nervous", lc(lavender) lp(_))
	   (line sh_of_total year if nih == 0 & disease_area == "psych", lc(purple) lp(-))
	   (line sh_of_total year if nih == 0 & disease_area == "respiratory", lc(navy) lp(_))
	   (line sh_of_total year if nih == 0 & disease_area == "skin", lc(magenta) lp(_..)) /* 16 */
	   (line sh_of_total year if nih == 0 & disease_area == "infectiousdiseases", lc(red) lp(.)),
	 legend(order(14 "Psychiatry & Psychology"
				  12 "Cancer"
	 			  13 "Nervous System & Cognition"
	 			  1  "Cardiovascular"
	 			  15 "Respiratory"
	 			  9  "Immune System"
				  17 "Infectious Diseases"
	 			  3  "Digestive"
	 			  4  "Endocrine"
	 			  7  "Female Urogential & Pregnancy"
	 			  11 "Musculoskeletal"
	 			  16 "Skin & Connective Tissue"
	 			  10 "Male Urogenital"
	 			  8  "Hemic & Lymphomatic"
				  /*2  "Chemically-Induced" - Silenced because no longer included in the queries*/
	 			  6  "Eye"
	 			  5  "ENT & Mouth") c(1) pos(3))
	 yti("Share of `yvar' (%)") title("Not NIH-Funded");

	 graph export "pubmed_results_notnih_notwtd`all_ct'_1980-2018.png", replace as(png) wid(1600) hei(700);
	 #delimit cr

*** Plot Shares of NIH-Funded Research by Disease Area
	#delimit ;
	tw (line sh_of_total year if nih == 1 & disease_area == "cardio", lc(cranberry) lp(-)) /* 1 */
	   (line sh_of_total year if nih == 1 & disease_area == "cheminduced", lc(sienna) lp(_))
	   (line sh_of_total year if nih == 1 & disease_area == "digestive", lc(erose) lp(--.))
	   (line sh_of_total year if nih == 1 & disease_area == "endocrine", lc(dkorange) lp(l))
	   (line sh_of_total year if nih == 1 & disease_area == "ent", lc(midgreen) lp(-.))
	   (line sh_of_total year if nih == 1 & disease_area == "eye", lc(gs12) lp(_.)) /* 6 */
	   (line sh_of_total year if nih == 1 & disease_area == "female", lc(pink) lp(__.))
	   (line sh_of_total year if nih == 1 & disease_area == "hemic", lc(eltblue) lp(--.))
	   (line sh_of_total year if nih == 1 & disease_area == "immune", lc(gs7) lp(.))
	   (line sh_of_total year if nih == 1 & disease_area == "male", lc(blue) lp(_))
	   (line sh_of_total year if nih == 1 & disease_area == "muscle", lc(gold) lp(-)) /* 11 */
	   (line sh_of_total year if nih == 1 & disease_area == "neoplasms", lc(orange) lp(.))
	   (line sh_of_total year if nih == 1 & disease_area == "psych", lc(purple) lp(-))
	   (line sh_of_total year if nih == 1 & disease_area == "respiratory", lc(navy) lp(_))
	   (line sh_of_total year if nih == 1 & disease_area == "skin", lc(magenta) lp(_..)) /* 16 */
	   (line sh_of_total year if nih == 1 & disease_area == "infectiousdiseases", lc(red) lp(.)),
	 legend(order(14 "Psychiatry & Psychology"
				  12 "Cancer"
	 			  13 "Nervous System & Cognition"
	 			  1  "Cardiovascular"
	 			  9  "Immune System"
	 			  15 "Respiratory"
	 			  7  "Female Urogential & Pregnancy"
	 			  3  "Digestive"
	 			  4  "Endocrine"
	 			  16 "Skin & Connective Tissue"
	 			  11 "Musculoskeletal"
	 			  10 "Male Urogenital"
	 			  8  "Hemic & Lymphomatic"
	 			  6  "Eye"
				  5  "ENT & Mouth"
	 			  /*2  "Chemically-Induced" - Silenced because no longer included in the queries*/
	 			  17 "Infectious Diseases") c(1) pos(3))
	 yti("Share of `yvar' (%)") title("NIH-Funded");

	 graph export "pubmed_results_nih_notwtd`all_ct'_1980-2018.png", replace as(png) wid(1600) hei(700);
	 #delimit cr
} // end Publications / Clinical Trials loop
*-------------------
}
*-------------------

*-----------------------------------------------------------
if `diseases_2005' == 1 {
*-------------------	
cap cd "C:\Users\lmostrom\Documents\Amitabh\"
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~
foreach all_ct in /*""*/ "_CT" {
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~
import delimited "PubMed_Search_Results`all_ct'_byDisease_from2005.csv", varn(1) clear

if "`all_ct'" == "" local x = 2
if "`all_ct'" == "_CT" local x = 3

lab def res_groups 1 "NIH" 2 "Gov't Non-NIH" 3 "Private"

split query_name, gen(disease_area) p("_")
	gen funding = 1 if (disease_area`x' == "NIH")
		replace funding = 2 if (disease_area`x' == "Pub")
		replace funding = 3 if (disease_area`x' == "Priv")
		lab val funding res_groups
	drop query_name
	ren pub_count count

cap replace count = "0" if count == "NA"
	cap destring count, replace

preserve
	ren count total
	keep if disease_area1 == "Total"
	*br
	*pause
	save "pubmed_results`all_ct'_byyear_total_2005.dta", replace
restore
preserve
	ren count totaldisease
	keep if disease_area1 == "TotalDisease"
	*br
	*pause
	save "pubmed_results`all_ct'_byyear_totaldisease_2005.dta", replace
restore

ren disease_area1 disease_area
keep if !inlist(disease_area, "Total", "TotalDisease")
replace disease_area = lower(disease_area)
drop disease_area`x'

save "pubmed_results`all_ct'_byyear_bydisease_2005.dta", replace

*-------------------------------------------------------------

bys funding year: egen sum_cats = total(count)
gen sh_of_total = count/sum_cats*100

merge m:1 year funding using "pubmed_results`all_ct'_byyear_total_2005.dta", nogen keep(1 3) keepus(total)
merge m:1 year funding using "pubmed_results`all_ct'_byyear_totaldisease_2005.dta", nogen keep(1 3) keepus(totaldisease)

keep if inrange(year, 2005, 2018)

*** Plot Comparison of Sum of Articles by Disease Area vs. Total Articles on PubMed
	preserve
		egen tag_fund_yr = tag(year funding)
		keep if tag_fund_yr
		gen frac_disease = totaldisease/total
		gen frac_cat_coverage = sum_cats/totaldisease

		#delimit ;
		tw (line frac_disease year if funding == 1, lc(red))
		   (line frac_disease year if funding == 2, lc(blue))
		   (line frac_disease year if funding == 3, lc(green)),
		 legend(order(1 "NIH" 2 "Gov't Non-NIH" 3 "Private"))
		 yti("Fraction of Publications About Disease");
		graph export "disease_share_of_pubmed`all_ct'_2005-2018.png", replace as(png) wid(1200) hei(700);

		tw (line frac_cat_coverage year if funding == 1, lc(red))
		   (line frac_cat_coverage year if funding == 2, lc(blue))
		   (line frac_cat_coverage year if funding == 3, lc(green)),
		 legend(order(1 "NIH" 2 "Gov't Non-NIH" 3 "Private"))
		 yti("Fraction of Publications About Disease");
		graph export "sum_of_disease_cats_div_by_disease_pubs`all_ct'_2005-2018.png", replace as(png) wid(1200) hei(700);
		#delimit cr

	restore

*** Plot Shares of All Research by Disease Area
	preserve
		collapse (sum) count, by(year disease_area)
		bys year: egen sum_cats = total(count)
		gen sh_of_total = count/sum_cats*100

		#delimit ;
		tw (line sh_of_total year if disease_area == "cardio", lc(cranberry) lp(-)) /* 1 */
		   (line sh_of_total year if disease_area == "cheminduced", lc(sienna) lp(_))
		   (line sh_of_total year if disease_area == "digestive", lc(erose) lp(--.))
		   (line sh_of_total year if disease_area == "endocrine", lc(dkorange) lp(l))
		   (line sh_of_total year if disease_area == "ent", lc(midgreen) lp(-.))
		   (line sh_of_total year if disease_area == "eye", lc(gs12) lp(_.)) /* 6 */
		   (line sh_of_total year if disease_area == "female", lc(pink) lp(__.))
		   (line sh_of_total year if disease_area == "hemic", lc(eltblue) lp(--.))
		   (line sh_of_total year if disease_area == "immune", lc(gs7) lp(.))
		   (line sh_of_total year if disease_area == "male", lc(blue) lp(_))
		   (line sh_of_total year if disease_area == "muscle", lc(gold) lp(-)) /* 11 */
		   (line sh_of_total year if disease_area == "neoplasms", lc(orange) lp(.))
		   (line sh_of_total year if disease_area == "nervous", lc(lavender) lp(_))
		   (line sh_of_total year if disease_area == "psych", lc(purple) lp(-))
		   (line sh_of_total year if disease_area == "respiratory", lc(navy) lp(_))
		   (line sh_of_total year if disease_area == "skin", lc(magenta) lp(_..)) /* 16 */
		   (line sh_of_total year if disease_area == "infectiousdiseases", lc(red) lp(.)),
		 legend(order(14 "Psychiatry & Psychology"
					  1  "Cardiovascular"
		 			  12 "Cancer"
		 			  13 "Nervous System & Cognition"
		 			  15 "Respiratory"
		 			  9  "Immune System"
		 			  7  "Female Urogential & Pregnancy"
		 			  11 "Musculoskeletal"
		 			  3  "Digestive"
		 			  16 "Skin & Connective Tissue"
		 			  10 "Male Urogenital"
		 			  8  "Hemic & Lymphomatic"
		 			  4  "Endocrine"
		 			  5  "ENT & Mouth"
		 			  6  "Eye"
					  /*2  "Chemically-Induced" - Silenced because no longer included in the queries*/
					  17 "Infectious Diseases") c(1) pos(3))
		 yti("Share of Publications (%)") title("All Funding Types");

		 graph export "pubmed_results_all_notwtd`all_ct'_2005-2018.png", replace as(png) wid(1600) hei(700);
		 #delimit cr

	restore

*** Plot Shares of NIH-Funded Research by Disease Area
	#delimit ;
	tw (line sh_of_total year if funding == 1 & disease_area == "cardio", lc(cranberry) lp(-)) /* 1 */
	   (line sh_of_total year if funding == 1 & disease_area == "cheminduced", lc(sienna) lp(_))
	   (line sh_of_total year if funding == 1 & disease_area == "digestive", lc(erose) lp(--.))
	   (line sh_of_total year if funding == 1 & disease_area == "endocrine", lc(dkorange) lp(l))
	   (line sh_of_total year if funding == 1 & disease_area == "ent", lc(midgreen) lp(-.))
	   (line sh_of_total year if funding == 1 & disease_area == "eye", lc(gs12) lp(_.)) /* 6 */
	   (line sh_of_total year if funding == 1 & disease_area == "female", lc(pink) lp(__.))
	   (line sh_of_total year if funding == 1 & disease_area == "hemic", lc(eltblue) lp(--.))
	   (line sh_of_total year if funding == 1 & disease_area == "immune", lc(gs7) lp(.))
	   (line sh_of_total year if funding == 1 & disease_area == "male", lc(blue) lp(_))
	   (line sh_of_total year if funding == 1 & disease_area == "muscle", lc(gold) lp(-)) /* 11 */
	   (line sh_of_total year if funding == 1 & disease_area == "neoplasms", lc(orange) lp(.))
	   (line sh_of_total year if funding == 1 & disease_area == "nervous", lc(lavender) lp(_))
	   (line sh_of_total year if funding == 1 & disease_area == "psych", lc(purple) lp(-))
	   (line sh_of_total year if funding == 1 & disease_area == "respiratory", lc(navy) lp(_)) 
	   (line sh_of_total year if funding == 1 & disease_area == "skin", lc(magenta) lp(_..)) /* 16 */
	   (line sh_of_total year if funding == 1 & disease_area == "infectiousdiseases", lc(red) lp(.)),
	 legend(order(14 "Psychiatry & Psychology"
				  1  "Cardiovascular"
	 			  12 "Cancer"
	 			  13 "Nervous System & Cognition"
	 			  15 "Respiratory"
	 			  9  "Immune System"
	 			  7  "Female Urogential & Pregnancy"
	 			  11 "Musculoskeletal"
	 			  3  "Digestive"
	 			  16 "Skin & Connective Tissue"
	 			  10 "Male Urogenital"
	 			  8  "Hemic & Lymphomatic"
	 			  4  "Endocrine"
	 			  5  "ENT & Mouth"
	 			  6  "Eye"
				  /*2  "Chemically-Induced" - Silenced because no longer included in the queries*/
				  17 "Infectious Diseases") c(1) pos(3))
	 yti("Share of Publications (%)") title("NIH Funded");

	 graph export "pubmed_results_nih_notwtd`all_ct'_2005-2018.png", replace as(png) wid(1600) hei(700);
	 #delimit cr

*** Plot Shares of Gov't Non-NIH-Funded Research by Disease Area
	#delimit ;
	tw (line sh_of_total year if funding == 2 & disease_area == "cardio", lc(cranberry) lp(-)) /* 1 */
	   (line sh_of_total year if funding == 2 & disease_area == "cheminduced", lc(sienna) lp(_))
	   (line sh_of_total year if funding == 2 & disease_area == "digestive", lc(erose) lp(--.))
	   (line sh_of_total year if funding == 2 & disease_area == "endocrine", lc(dkorange) lp(l))
	   (line sh_of_total year if funding == 2 & disease_area == "ent", lc(midgreen) lp(-.))
	   (line sh_of_total year if funding == 2 & disease_area == "eye", lc(gs12) lp(_.)) /* 6 */
	   (line sh_of_total year if funding == 2 & disease_area == "female", lc(pink) lp(__.))
	   (line sh_of_total year if funding == 2 & disease_area == "hemic", lc(eltblue) lp(--.))
	   (line sh_of_total year if funding == 2 & disease_area == "immune", lc(gs7) lp(.))
	   (line sh_of_total year if funding == 2 & disease_area == "male", lc(blue) lp(_))
	   (line sh_of_total year if funding == 2 & disease_area == "muscle", lc(gold) lp(-)) /* 11 */
	   (line sh_of_total year if funding == 2 & disease_area == "neoplasms", lc(orange) lp(.))
	   (line sh_of_total year if funding == 2 & disease_area == "nervous", lc(lavender) lp(_))
	   (line sh_of_total year if funding == 2 & disease_area == "psych", lc(purple) lp(-))
	   (line sh_of_total year if funding == 2 & disease_area == "respiratory", lc(navy) lp(_))
	   (line sh_of_total year if funding == 2 & disease_area == "skin", lc(magenta) lp(_..)) /* 16 */
	   (line sh_of_total year if funding == 2 & disease_area == "infectiousdiseases", lc(red) lp(.)),
	 legend(order(14 "Psychiatry & Psychology"
				  12 "Cancer"
	 			  13 "Nervous System & Cognition"
	 			  1  "Cardiovascular"
	 			  9  "Immune System"
	 			  15 "Respiratory"
	 			  7  "Female Urogential & Pregnancy"
	 			  3  "Digestive"
	 			  4  "Endocrine"
	 			  16 "Skin & Connective Tissue"
	 			  11 "Musculoskeletal"
	 			  10 "Male Urogenital"
	 			  8  "Hemic & Lymphomatic"
	 			  6  "Eye"
				  5  "ENT & Mouth"
	 			  /*2  "Chemically-Induced" - Silenced because no longer included in the queries*/
	 			  17 "Infectious Diseases") c(1) pos(3))
	 yti("Share of Publications (%)") title("Gov't Non-NIH Funded");

	 graph export "pubmed_results_public_notwtd`all_ct'_2005-2018.png", replace as(png) wid(1600) hei(700);
	 #delimit cr

*** Plot Shares of Privately Funded Research by Disease Area
	#delimit ;
	tw (line sh_of_total year if funding == 3 & disease_area == "cardio", lc(cranberry) lp(-)) /* 1 */
	   (line sh_of_total year if funding == 3 & disease_area == "cheminduced", lc(sienna) lp(_))
	   (line sh_of_total year if funding == 3 & disease_area == "digestive", lc(erose) lp(--.))
	   (line sh_of_total year if funding == 3 & disease_area == "endocrine", lc(dkorange) lp(l))
	   (line sh_of_total year if funding == 3 & disease_area == "ent", lc(midgreen) lp(-.))
	   (line sh_of_total year if funding == 3 & disease_area == "eye", lc(gs12) lp(_.)) /* 6 */
	   (line sh_of_total year if funding == 3 & disease_area == "female", lc(pink) lp(__.))
	   (line sh_of_total year if funding == 3 & disease_area == "hemic", lc(eltblue) lp(--.))
	   (line sh_of_total year if funding == 3 & disease_area == "immune", lc(gs7) lp(.))
	   (line sh_of_total year if funding == 3 & disease_area == "male", lc(blue) lp(_))
	   (line sh_of_total year if funding == 3 & disease_area == "muscle", lc(gold) lp(-)) /* 11 */
	   (line sh_of_total year if funding == 3 & disease_area == "neoplasms", lc(orange) lp(.))
	   (line sh_of_total year if funding == 3 & disease_area == "nervous", lc(lavender) lp(_))
	   (line sh_of_total year if funding == 3 & disease_area == "psych", lc(purple) lp(-))
	   (line sh_of_total year if funding == 3 & disease_area == "respiratory", lc(navy) lp(_)) 
	   (line sh_of_total year if funding == 3 & disease_area == "skin", lc(magenta) lp(_..)) /* 16 */
	   (line sh_of_total year if funding == 3 & disease_area == "infectiousdiseases", lc(red) lp(.)),
	 legend(order(14 "Psychiatry & Psychology"
				  12 "Cancer"
	 			  13 "Nervous System & Cognition"
	 			  1  "Cardiovascular"
	 			  9  "Immune System"
	 			  15 "Respiratory"
	 			  7  "Female Urogential & Pregnancy"
	 			  3  "Digestive"
	 			  4  "Endocrine"
	 			  16 "Skin & Connective Tissue"
	 			  11 "Musculoskeletal"
	 			  10 "Male Urogenital"
	 			  8  "Hemic & Lymphomatic"
	 			  6  "Eye"
				  5  "ENT & Mouth"
	 			  /*2  "Chemically-Induced" - Silenced because no longer included in the queries*/
	 			  17 "Infectious Diseases") c(1) pos(3))
	 yti("Share of Publications (%)") title("Privately Funded");

	 graph export "pubmed_results_private_notwtd`all_ct'_2005-2018.png", replace as(png) wid(1600) hei(700);
	 #delimit cr

*** Plot HHI over time of disease area concentration for NIH vs. Industry
gen sh_of_total_sq = sh_of_total^2
collapse (sum) hhi = sh_of_total_sq, by(year funding)

#delimit ;
tw (line hhi year if funding == 1, lc(red))
   (line hhi year if funding == 3, lc(green)),
 legend(order(1 "NIH-Funded" 2 "Industry-Funded") r(1))
 yti("HHI");
graph export "disease_areas_hhi_nih_private_notwtd`all_ct'_2005-2018.png", replace as(png) wid(1600) hei(700);
#delimit cr
}
*-------------------
}
*-------------------

*-----------------------------------------------------------
if `diseases_hhi' == 1 {
*-------------------
cap cd "C:\Users\lmostrom\Documents\Amitabh\"
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~
foreach all_ct in /*""*/ "_CT" {
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use "pubmed_results`all_ct'_byyear_bydisease_1980.dta", clear

gen funding = 1 if nih == 1
replace funding = 2.5 if nih == 0

preserve
	keep if inrange(year, 1980, 2004)
	tempfile diseases_88_04
	save `diseases_88_04', replace
restore
preserve
	keep if inrange(year, 2005, 2018)
	ren count count_1980
	tempfile diseases_05_18
	save `diseases_05_18', replace
restore
use "pubmed_results`all_ct'_byyear_bydisease_2005.dta", clear
	gen nih = funding == 1
append using `diseases_88_04'
merge m:1 year nih disease_area using `diseases_05_18', keepus(count_1980)
pause

bys funding year: egen sum_cats = total(count) if disease_area != "psych"
gen sh_of_total = count/sum_cats*100
*-------------------------------------------------------------
if "`all_ct'" == "" local ti "Research Publications"
if "`all_ct'" == "_CT" local ti "Clinical Trials"
*-------------------------------------------------------------

if "`all_ct'" == "" keep if inrange(year, 1980, 2018)
else keep if inrange(year, 1992, 2018)

*** Plot HHI over time of disease area concentration for NIH vs. Industry
gen sh_of_total_sq = sh_of_total^2
br
pause
collapse (sum) hhi = sh_of_total_sq, by(year funding)

#delimit ;
tw (line hhi year if funding == 1, lc(red))
   (line hhi year if funding == 3, lc(green))
   (line hhi year if funding == 2.5, lc(green) lp(-)),
 legend(order(1 "NIH-Funded" 2 "Industry-Funded"
 			  3 "Non-NIH-Funded (Public & Private)") c(1))
 yti("HHI") title("`ti'");
graph export "disease_areas_hhi_notwtd`all_ct'_1980-2018.png", replace as(png) wid(1600) hei(700);
#delimit cr
}
*-------------------
}
*-------------------

*=======================================================================
*					DISEASE CATEGORIES (PROCESSES)
*=======================================================================
*-------------------------
if `BVPW_1980' == 1 {
*-------------------------
cap cd "C:\Users\lmostrom\Documents\Amitabh\"
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
foreach all_ex in "" "_exDiseases" {
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
import delimited "PubMed_Search_Results_byBVPW`all_ex'_from1980.csv", varn(1) clear

split query_name, gen(disease_area) p("_")
	gen nih = (disease_area2 == "NIH")
	drop query_name
	ren pub_count count

ren disease_area1 disease_area
keep if !inlist(disease_area, "Total", "TotalDisease")
replace disease_area = lower(disease_area)
drop disease_area2

save "pubmed_results`all_ex'_byyear_byBVPW_1980.dta", replace

*-------------------------------------------------------------
local yvar "Publications"
*-------------------------------------------------------------

bys nih year: egen sum_cats = total(count)
gen sh_of_total = count/sum_cats*100

merge m:1 year nih using "pubmed_results_byyear_total_1980.dta", nogen keep(1 3) keepus(total)
merge m:1 year nih using "pubmed_results_byyear_totaldisease_1980.dta", nogen keep(1 3) keepus(totaldisease)

keep if inrange(year, 1980, 2018)

*** Plot Comparison of Sum of Articles by Disease Area vs. Total Articles on PubMed
	preserve
		egen tag_nih_yr = tag(year nih)
		keep if tag_nih_yr
		gen frac_disease = totaldisease/total
		gen frac_cat_coverage = sum_cats/totaldisease
		gen frac_cat_oftot = sum_cats/total
		
		#delimit ;
		tw (line frac_cat_oftot year if nih == 0, lc(blue))
		   (line frac_cat_oftot year if nih == 1, lc(red)),
		 legend(order(1 "Not NIH" 2 "NIH"))
		 /*yline(1, lc(gs8)) xline(1980, lp(-) lc(gs8))*/
		 yti("Fraction of `yvar' About Disease");
		graph export "BVPW`all_ex'_share_of_pubmed_1980-2018.png", replace as(png) wid(1200) hei(700);

		tw (line frac_cat_coverage year if nih == 0, lc(blue))
		   (line frac_cat_coverage year if nih == 1, lc(red)),
		 legend(order(1 "Not NIH" 2 "NIH"))
		 /*yline(1, lc(gs8)) xline(1980, lp(-) lc(gs8))*/
		 yti("Ratio of Sum of Category `yvar' to Total Disease `yvar'" "(Over/Undercounting Ratio)");
		graph export "sum_of_BVPW_div_by_disease_pubs`all_ex'_1980-2018.png", replace as(png) wid(1200) hei(700);
		#delimit cr
	restore

*** Plot Shares of All Research by Disease Area
	preserve
		collapse (sum) count, by(year disease_area)
		bys year: egen sum_cats = total(count)
		gen sh_of_total = count/sum_cats*100

		#delimit ;
		tw (line sh_of_total year if disease_area == "bact", lc(cranberry) lp(l)) /* 1 */
		   (line sh_of_total year if disease_area == "chem", lc(sienna) lp(_))
		   (line sh_of_total year if disease_area == "congenital", lc(erose) lp(-))
		   (line sh_of_total year if disease_area == "envir", lc(dkorange) lp(l))
		   (line sh_of_total year if disease_area == "nutrition", lc(midgreen) lp(-))
		   (line sh_of_total year if disease_area == "occupation", lc(gs12) lp(_)) /* 6 */
		   (line sh_of_total year if disease_area == "parasites", lc(pink) lp(l))
		   (line sh_of_total year if disease_area == "path", lc(eltblue) lp(-))
		   (line sh_of_total year if disease_area == "viral", lc(gs7) lp(_))
		   (line sh_of_total year if disease_area == "wounds", lc(blue) lp(l)),
		 legend(order(1 "Bacterial Infections & Mycoses"
		 			  2 "Chemically-Induced Disorders"
		 			  3 "Congenital, Hereditary, and Neonatal Diseases"
		 			  4 "Disorders of Environmental Origin"
		 			  5 "Nutritional and Metabolic Diseases"
		 			  6 "Occupational Diseases"
		 			  7 "Parasitic Diseases"
		 			  8 "Pathological Conditions, Signs and Symptoms"
		 			  9 "Virus Diseases"
		 			  10 "Wounds and Injuries") c(1) pos(3))
		 yti("Share of `yvar' (%)") title("All Funding Types");

		 graph export "pubmed_results_all_BVPW`all_ex'_notwtd_1980-2018.png", replace as(png) wid(1600) hei(700);
		 #delimit cr

	restore

*** Plot Shares of Non-NIH-Funded Research by Disease Area
	#delimit ;
	tw (line sh_of_total year if nih == 0 & disease_area == "bact", lc(cranberry) lp(l)) /* 1 */
	   (line sh_of_total year if nih == 0 & disease_area == "chem", lc(sienna) lp(_))
	   (line sh_of_total year if nih == 0 & disease_area == "congenital", lc(erose) lp(-))
	   (line sh_of_total year if nih == 0 & disease_area == "envir", lc(dkorange) lp(l))
	   (line sh_of_total year if nih == 0 & disease_area == "nutrition", lc(midgreen) lp(-))
	   (line sh_of_total year if nih == 0 & disease_area == "occupation", lc(gs12) lp(_)) /* 6 */
	   (line sh_of_total year if nih == 0 & disease_area == "parasites", lc(pink) lp(l))
	   (line sh_of_total year if nih == 0 & disease_area == "path", lc(eltblue) lp(-))
	   (line sh_of_total year if nih == 0 & disease_area == "viral", lc(gs7) lp(_))
	   (line sh_of_total year if nih == 0 & disease_area == "wounds", lc(blue) lp(l)),
		 legend(order(1 "Bacterial Infections & Mycoses"
		 			  2 "Chemically-Induced Disorders"
		 			  3 "Congenital, Hereditary, and Neonatal Diseases"
		 			  4 "Disorders of Environmental Origin"
		 			  5 "Nutritional and Metabolic Diseases"
		 			  6 "Occupational Diseases"
		 			  7 "Parasitic Diseases"
		 			  8 "Pathological Conditions, Signs and Symptoms"
		 			  9 "Virus Diseases"
		 			  10 "Wounds and Injuries") c(1) pos(3))
	 yti("Share of `yvar' (%)") title("Not NIH-Funded");

	 graph export "pubmed_results_notnih_BVPW`all_ex'_notwtd_1980-2018.png", replace as(png) wid(1600) hei(700);
	 #delimit cr

*** Plot Shares of NIH-Funded Research by Disease Area
	#delimit ;
	tw (line sh_of_total year if nih == 1 & disease_area == "bact", lc(cranberry) lp(l)) /* 1 */
	   (line sh_of_total year if nih == 1 & disease_area == "chem", lc(sienna) lp(_))
	   (line sh_of_total year if nih == 1 & disease_area == "congenital", lc(erose) lp(-))
	   (line sh_of_total year if nih == 1 & disease_area == "envir", lc(dkorange) lp(l))
	   (line sh_of_total year if nih == 1 & disease_area == "nutrition", lc(midgreen) lp(-))
	   (line sh_of_total year if nih == 1 & disease_area == "occupation", lc(gs12) lp(_)) /* 6 */
	   (line sh_of_total year if nih == 1 & disease_area == "parasites", lc(pink) lp(l))
	   (line sh_of_total year if nih == 1 & disease_area == "path", lc(eltblue) lp(-))
	   (line sh_of_total year if nih == 1 & disease_area == "viral", lc(gs7) lp(_))
	   (line sh_of_total year if nih == 1 & disease_area == "wounds", lc(blue) lp(l)),
		 legend(order(1 "Bacterial Infections & Mycoses"
		 			  2 "Chemically-Induced Disorders"
		 			  3 "Congenital, Hereditary, and Neonatal Diseases"
		 			  4 "Disorders of Environmental Origin"
		 			  5 "Nutritional and Metabolic Diseases"
		 			  6 "Occupational Diseases"
		 			  7 "Parasitic Diseases"
		 			  8 "Pathological Conditions, Signs and Symptoms"
		 			  9 "Virus Diseases"
		 			  10 "Wounds and Injuries") c(1) pos(3))
	 yti("Share of `yvar' (%)") title("NIH-Funded");

	 graph export "pubmed_results_nih_BVPW`all_ex'_notwtd_1980-2018.png", replace as(png) wid(1600) hei(700);
	 #delimit cr
} // end all / excluding body system disease categories loop
*-------------------
}
*-------------------

*-----------------------------------------------------------
if `BVPW_2005' == 1 {
*-------------------	
cap cd "C:\Users\lmostrom\Documents\Amitabh\"
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
foreach all_ex in "" "_exDiseases" {
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
import delimited "PubMed_Search_Results_byBVPW`all_ex'_from2005.csv", varn(1) clear

lab def res_groups 1 "NIH" 2 "Gov't Non-NIH" 3 "Private"

split query_name, gen(disease_area) p("_")
	gen funding = 1 if (disease_area2 == "NIH")
		replace funding = 2 if (disease_area2 == "Pub")
		replace funding = 3 if (disease_area2 == "Priv")
		lab val funding res_groups
	drop query_name
	ren pub_count count

cap replace count = "0" if count == "NA"
	cap destring count, replace

ren disease_area1 disease_area
replace disease_area = lower(disease_area)
drop disease_area2

save "pubmed_results`all_ex'_byyear_byBVPW_2005.dta", replace

*-------------------------------------------------------------

bys funding year: egen sum_cats = total(count)
gen sh_of_total = count/sum_cats*100

merge m:1 year funding using "pubmed_results`all_ct'_byyear_total_2005.dta", nogen keep(1 3) keepus(total)
merge m:1 year funding using "pubmed_results`all_ct'_byyear_totaldisease_2005.dta", nogen keep(1 3) keepus(totaldisease)

keep if inrange(year, 2005, 2018)

*** Plot Comparison of Sum of Articles by Disease Area vs. Total Articles on PubMed
	preserve
		egen tag_fund_yr = tag(year funding)
		keep if tag_fund_yr
		gen frac_disease = totaldisease/total
		gen frac_cat_coverage = sum_cats/totaldisease
		gen frac_cat_oftot = sum_cats/total

		#delimit ;
		tw (line frac_cat_oftot year if funding == 1, lc(red))
		   (line frac_cat_oftot year if funding == 2, lc(blue))
		   (line frac_cat_oftot year if funding == 3, lc(green)),
		 legend(order(1 "NIH" 2 "Gov't Non-NIH" 3 "Private"))
		 yti("Fraction of Publications About Disease");
		graph export "BVPW_share_of_pubmed`all_ex'_2005-2018.png", replace as(png) wid(1200) hei(700);

		tw (line frac_cat_coverage year if funding == 1, lc(red))
		   (line frac_cat_coverage year if funding == 2, lc(blue))
		   (line frac_cat_coverage year if funding == 3, lc(green)),
		 legend(order(1 "NIH" 2 "Gov't Non-NIH" 3 "Private"))
		 yti("Fraction of Publications About Disease");
		graph export "sum_of_BVPW_div_by_disease_pubs`all_ex'_2005-2018.png", replace as(png) wid(1200) hei(700);
		#delimit cr

	restore

*** Plot Shares of All Research by Disease Area
	preserve
		collapse (sum) count, by(year disease_area)
		bys year: egen sum_cats = total(count)
		gen sh_of_total = count/sum_cats*100

		#delimit ;
		tw (line sh_of_total year if disease_area == "bact", lc(cranberry) lp(l)) /* 1 */
	   	   (line sh_of_total year if disease_area == "chem", lc(sienna) lp(_))
	   	   (line sh_of_total year if disease_area == "congenital", lc(erose) lp(-))
	   	   (line sh_of_total year if disease_area == "envir", lc(dkorange) lp(l))
	   	   (line sh_of_total year if disease_area == "nutrition", lc(midgreen) lp(-))
	   	   (line sh_of_total year if disease_area == "occupation", lc(gs12) lp(_)) /* 6 */
	   	   (line sh_of_total year if disease_area == "parasites", lc(pink) lp(l))
	   	   (line sh_of_total year if disease_area == "path", lc(eltblue) lp(-))
	   	   (line sh_of_total year if disease_area == "viral", lc(gs7) lp(_))
	   	   (line sh_of_total year if disease_area == "wounds", lc(blue) lp(l)),
		 legend(order(1 "Bacterial Infections & Mycoses"
		 			  2 "Chemically-Induced Disorders"
		 			  3 "Congenital, Hereditary, and Neonatal Diseases"
		 			  4 "Disorders of Environmental Origin"
		 			  5 "Nutritional and Metabolic Diseases"
		 			  6 "Occupational Diseases"
		 			  7 "Parasitic Diseases"
		 			  8 "Pathological Conditions, Signs and Symptoms"
		 			  9 "Virus Diseases"
		 			  10 "Wounds and Injuries") c(1) pos(3))
		 yti("Share of Publications (%)") title("All Funding Types");

		 graph export "pubmed_results_all_BVPW`all_ex'_notwtd_2005-2018.png", replace as(png) wid(1600) hei(700);
		 #delimit cr

	restore

*** Plot Shares of NIH-Funded Research by Disease Area
	#delimit ;
	tw (line sh_of_total year if funding == 1 & disease_area == "bact", lc(cranberry) lp(l)) /* 1 */
	   (line sh_of_total year if funding == 1 & disease_area == "chem", lc(sienna) lp(_))
	   (line sh_of_total year if funding == 1 & disease_area == "congenital", lc(erose) lp(-))
	   (line sh_of_total year if funding == 1 & disease_area == "envir", lc(dkorange) lp(l))
	   (line sh_of_total year if funding == 1 & disease_area == "nutrition", lc(midgreen) lp(-))
	   (line sh_of_total year if funding == 1 & disease_area == "occupation", lc(gs12) lp(_)) /* 6 */
	   (line sh_of_total year if funding == 1 & disease_area == "parasites", lc(pink) lp(l))
	   (line sh_of_total year if funding == 1 & disease_area == "path", lc(eltblue) lp(-))
	   (line sh_of_total year if funding == 1 & disease_area == "viral", lc(gs7) lp(_))
	   (line sh_of_total year if funding == 1 & disease_area == "wounds", lc(blue) lp(l)),
		 legend(order(1 "Bacterial Infections & Mycoses"
		 			  2 "Chemically-Induced Disorders"
		 			  3 "Congenital, Hereditary, and Neonatal Diseases"
		 			  4 "Disorders of Environmental Origin"
		 			  5 "Nutritional and Metabolic Diseases"
		 			  6 "Occupational Diseases"
		 			  7 "Parasitic Diseases"
		 			  8 "Pathological Conditions, Signs and Symptoms"
		 			  9 "Virus Diseases"
		 			  10 "Wounds and Injuries") c(1) pos(3))
	 yti("Share of Publications (%)") title("NIH Funded");

	 graph export "pubmed_results_nih_BVPW`all_ex'_notwtd_2005-2018.png", replace as(png) wid(1600) hei(700);
	 #delimit cr

*** Plot Shares of Gov't Non-NIH-Funded Research by Disease Area
	#delimit ;
	tw (line sh_of_total year if funding == 2 & disease_area == "bact", lc(cranberry) lp(l)) /* 1 */
	   (line sh_of_total year if funding == 2 & disease_area == "chem", lc(sienna) lp(_))
	   (line sh_of_total year if funding == 2 & disease_area == "congenital", lc(erose) lp(-))
	   (line sh_of_total year if funding == 2 & disease_area == "envir", lc(dkorange) lp(l))
	   (line sh_of_total year if funding == 2 & disease_area == "nutrition", lc(midgreen) lp(-))
	   (line sh_of_total year if funding == 2 & disease_area == "occupation", lc(gs12) lp(_)) /* 6 */
	   (line sh_of_total year if funding == 2 & disease_area == "parasites", lc(pink) lp(l))
	   (line sh_of_total year if funding == 2 & disease_area == "path", lc(eltblue) lp(-))
	   (line sh_of_total year if funding == 2 & disease_area == "viral", lc(gs7) lp(_))
	   (line sh_of_total year if funding == 2 & disease_area == "wounds", lc(blue) lp(l)),
		 legend(order(1 "Bacterial Infections & Mycoses"
		 			  2 "Chemically-Induced Disorders"
		 			  3 "Congenital, Hereditary, and Neonatal Diseases"
		 			  4 "Disorders of Environmental Origin"
		 			  5 "Nutritional and Metabolic Diseases"
		 			  6 "Occupational Diseases"
		 			  7 "Parasitic Diseases"
		 			  8 "Pathological Conditions, Signs and Symptoms"
		 			  9 "Virus Diseases"
		 			  10 "Wounds and Injuries") c(1) pos(3))
	 yti("Share of Publications (%)") title("Gov't Non-NIH Funded");

	 graph export "pubmed_results_public_BVPW`all_ex'_notwtd_2005-2018.png", replace as(png) wid(1600) hei(700);
	 #delimit cr

*** Plot Shares of Privately Funded Research by Disease Area
	#delimit ;
	tw (line sh_of_total year if funding == 3 & disease_area == "bact", lc(cranberry) lp(l)) /* 1 */
	   (line sh_of_total year if funding == 3 & disease_area == "chem", lc(sienna) lp(_))
	   (line sh_of_total year if funding == 3 & disease_area == "congenital", lc(erose) lp(-))
	   (line sh_of_total year if funding == 3 & disease_area == "envir", lc(dkorange) lp(l))
	   (line sh_of_total year if funding == 3 & disease_area == "nutrition", lc(midgreen) lp(-))
	   (line sh_of_total year if funding == 3 & disease_area == "occupation", lc(gs12) lp(_)) /* 6 */
	   (line sh_of_total year if funding == 3 & disease_area == "parasites", lc(pink) lp(l))
	   (line sh_of_total year if funding == 3 & disease_area == "path", lc(eltblue) lp(-))
	   (line sh_of_total year if funding == 3 & disease_area == "viral", lc(gs7) lp(_))
	   (line sh_of_total year if funding == 3 & disease_area == "wounds", lc(blue) lp(l)),
		 legend(order(1 "Bacterial Infections & Mycoses"
		 			  2 "Chemically-Induced Disorders"
		 			  3 "Congenital, Hereditary, and Neonatal Diseases"
		 			  4 "Disorders of Environmental Origin"
		 			  5 "Nutritional and Metabolic Diseases"
		 			  6 "Occupational Diseases"
		 			  7 "Parasitic Diseases"
		 			  8 "Pathological Conditions, Signs and Symptoms"
		 			  9 "Virus Diseases"
		 			  10 "Wounds and Injuries") c(1) pos(3))
	 yti("Share of Publications (%)") title("Privately Funded");

	 graph export "pubmed_results_private_BVPW`all_ex'_notwtd_2005-2018.png", replace as(png) wid(1600) hei(700);
	 #delimit cr

*** Plot HHI over time of disease area concentration for NIH vs. Industry
gen sh_of_total_sq = sh_of_total^2
collapse (sum) hhi = sh_of_total_sq, by(year funding)

#delimit ;
tw (line hhi year if funding == 1, lc(red))
   (line hhi year if funding == 3, lc(green)),
 legend(order(1 "NIH-Funded" 2 "Industry-Funded") r(1))
 yti("HHI");
graph export "BVPW`all_ex'_hhi_nih_private_notwtd_2005-2018.png", replace as(png) wid(1600) hei(700);
#delimit cr
}
*-------------------
}
*-------------------

*-----------------------------------------------------------
if `BVPW_hhi' == 1 {
*-------------------
cap cd "C:\Users\lmostrom\Documents\Amitabh\"
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
foreach all_ex in "" "_exDiseases" {
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use "pubmed_results`all_ex'_byyear_byBVPW_1980.dta", clear

gen funding = 1 if nih == 1
replace funding = 2.5 if nih == 0

preserve
	keep if inrange(year, 1980, 2004)
	tempfile diseases_88_04
	save `diseases_88_04', replace
restore
preserve
	keep if inrange(year, 2005, 2018)
	ren count count_1980
	tempfile diseases_05_18
	save `diseases_05_18', replace
restore
use "pubmed_results`all_ex'_byyear_byBVPW_2005.dta", clear
	gen nih = funding == 1
append using `diseases_88_04'
merge m:1 year nih disease_area using `diseases_05_18', keepus(count_1980)

bys funding year: egen sum_cats = total(count) if disease_area != "psych"
gen sh_of_total = count/sum_cats*100
*-------------------------------------------------------------
local ti "Research Publications"
*-------------------------------------------------------------
keep if inrange(year, 1980, 2018)

*** Plot HHI over time of disease area concentration for NIH vs. Industry
gen sh_of_total_sq = sh_of_total^2
collapse (sum) hhi = sh_of_total_sq, by(year funding)

#delimit ;
tw (line hhi year if funding == 1, lc(red))
   (line hhi year if funding == 3, lc(green))
   (line hhi year if funding == 2.5, lc(green) lp(-)),
 legend(order(1 "NIH-Funded" 2 "Industry-Funded"
 			  3 "Non-NIH-Funded (Public & Private)") c(1))
 yti("HHI") title("`ti'");
graph export "BVPW`all_ex'_hhi_notwtd_1980-2018.png", replace as(png) wid(1600) hei(700);
#delimit cr
}
*-------------------
}
*-------------------

*=======================================================================
*					HEALTH SERVICES & ECONOMICS
*=======================================================================
*---------------------
if `econ_1980' == 1 {
*---------------------	
cap cd "C:\Users\lmostrom\Documents\Amitabh\"
import delimited "PubMed_Search_Results_MedvsEcon_from1980.csv", varn(1) clear

split query_name, gen(field) p("_")
	gen nih = (field2 == "NIH")
	drop query_name
	ren pub_count count

ren field1 field
replace field = lower(field)
drop field2

save "pubmed_results_byyear_byfield_1980.dta", replace

*-------------------------------------------------------------
bys year: egen tot_med = total(count) if field == "med"
gen sh_med_nih = count/tot_med if nih == 1 & field == "med"
	replace sh_med_nih = sh_med_nih * 100

*** Plot Comparison of Econ Papers funded by NIH vs. Not Funded by NIH
	#delimit ;
		tw (line count year if nih == 0 & field == "econ", lc(blue))
		   (line count year if nih == 1 & field == "econ", lc(red)),
		 legend(order(1 "Not NIH" 2 "NIH"))
		 xline(2008, lp(-) lc(gs8))
		 yti("Publications from Top 20 Econ Journals in PubMed");
		graph export "econ_in_pubmed_1980-2018.png", replace as(png) wid(1200) hei(700);

		tw (line sh_med_nih year if nih == 1 & field == "med", lc(red)),
		 legend(off) xline(2008, lp(-) lc(gs8))
		 yti("Share of Top Medical Journal Publications in PubMed" "Funded by NIH (%)");
		graph export "topmed_nih_in_pubmed_1980-2018.png", replace as(png) wid(1200) hei(700);
	#delimit cr
*-------------------
}
*-------------------

*-------------------------------------------------------
if `econ_2005' == 1 {
*---------------------	
cap cd "C:\Users\lmostrom\Documents\Amitabh\"
import delimited "PubMed_Search_Results_MedvsEcon_from2005.csv", varn(1) clear

lab def res_groups 1 "NIH" 2 "Gov't Non-NIH" 3 "Private"

split query_name, gen(field) p("_")
	gen funding  = 1 if (field2 == "NIH")
	replace funding = 2 if field2 == "Pub"
	replace funding = 3 if field2 == "Priv"
	lab val funding res_groups
	drop query_name
	ren pub_count count

ren field1 field
replace field = lower(field)
drop field2

gen nih = funding == 1

save "pubmed_results_byyear_byfield_2005.dta", replace
*-------------------------------------------------------------
*** Plot Comparison of Econ Papers funded by NIH vs. Not Funded by NIH
	#delimit ;
		tw (line count year if funding == 1 & field == "econ", lc(red))
		   (line count year if funding == 2 & field == "econ", lc(blue))
		   (line count year if funding == 3 & field == "econ", lc(green)),
		 legend(order(1 "NIH" 2 "Gov't, Non-NIH Funded" 3 "Privately Funded"))
		 xline(2008, lp(-) lc(gs8))
		 yti("Publications from Top 20 Econ Journals in PubMed");
		graph export "econ_in_pubmed_2005-2018.png", replace as(png) wid(1200) hei(700);
	#delimit cr
*-------------------
}
*-------------------

*-----------------------------------------------------------
if `health_econ_1980' == 1 {
*-------------------	
cap cd "C:\Users\lmostrom\Documents\Amitabh\"
import delimited "PubMed_Search_Results_HealthEconPolicy_from1980.csv", varn(1) clear

split query_name, gen(field) p("_")
	gen nih = (field2 == "NIH")
	drop query_name
	ren pub_count count

ren field1 field
replace field = lower(field)
drop field2

save "pubmed_results_byyear_HealthEconPolicy_1980.dta", replace


*** Plot Comparison of Econ Papers funded by NIH vs. Not Funded by NIH
foreach field in "hceo" "econsub" "legsub" {
	forval nihfund = 0/1 {
		if `nihfund' == 0 {
			local subti "Not NIH Funded"
			local col "blue"
		}
		if `nihfund' == 1 {
			local subti "NIH Funded"
			local col "red"
		}

		if "`field'" == "hceo" local ti "Health Care Economics and Organizations Papers"
		if "`field'" == "econsub" local ti "Papers with an Economics MeSH Subheading"
		if "`field'" == "legsub" local ti "Papers with a Legislation MeSH Subheading"
		

		#delimit ;
			tw (line count year if nih == `nihfund' & field == "`field'", lc(`col') lp(l))
			   (line count year if nih == `nihfund' & field == "`field'diseases", lc(`col') lp(-)),
			 title("`ti'") subtitle("`subti'")
			 legend(order(1 "Total Papers" 2 "Papers about Diseases"))
			 xline(2008, lp(-) lc(gs8)) yti("");
			graph export "`field'_nih`nihfund'_in_pubmed_1980-2018.png", replace as(png) wid(1200) hei(700);
		#delimit cr
	}
}


*-------------------
}
*-------------------

*-------------------------
if `all_1980' == 1 {
*-------------------------
cap cd "C:\Users\lmostrom\Documents\Amitabh\"

import delimited "PubMed_Search_Results_all_from1980.csv", varn(1) clear

split query_name, p("_")

gen QA = substr(query_name1, -2, 2) == "QA"
	drop query_name query_name1

ren pub_count pubs_
replace query_name2 = "All" if query_name2 == ""
reshape wide pubs_, i(QA year) j(query_name2) string

order QA year pubs_NIH pubs_notNIH pubs_All

foreach var of varlist pubs_NIH pubs_notNIH {
		gen sh_`var' = `var'/pubs_All
}

export delimited "all_pubs_by_funding_from1980.csv", replace

* Plots for # of pubs and share of all pubs
#delimit ;
tw (line pubs_NIH year if !QA, lc(red))
   (line pubs_notNIH year if !QA, lc(blue)),
 legend(order( 1 "Received NIH Funding" 2 "Did Not Receive NIH Funding") r(1))
 yti("Number of PubMed Publications") xti("Year")
 subti("All Journals");
graph export "all_pubs_by_funding_notQA_from1980.png", replace as(png) wid(1200) hei(700);

tw (line pubs_NIH year if QA, lc(red))
   (line pubs_notNIH year if QA, lc(blue)),
 legend(order( 1 "Received NIH Funding" 2 "Did Not Receive NIH Funding") r(1))
 yti("Number of PubMed Publications") xti("Year")
 subti("Top 13 Journals");
graph export "all_pubs_by_funding_QA_from1980.png", replace as(png) wid(1200) hei(700);

tw (line sh_pubs_NIH year if !QA, lc(red))
   (line sh_pubs_notNIH year if !QA, lc(blue)),
 legend(order( 1 "Received NIH Funding" 2 "Did Not Receive NIH Funding") r(1))
 yti("Share of all Publications (%)") xti("Year")
 subti("All Journals");
graph export "all_pubs_sh_by_funding_notQA_from1980.png", replace as(png) wid(1200) hei(700);

tw (line sh_pubs_NIH year if QA, lc(red))
   (line sh_pubs_notNIH year if QA, lc(blue)),
 legend(order( 1 "Received NIH Funding" 2 "Did Not Receive NIH Funding") r(1))
 yti("Share of all Publications (%)") xti("Year")
 subti("Top 13 Journals");
graph export "all_pubs_sh_by_funding_QA_from1980.png", replace as(png) wid(1200) hei(700);
#delimit cr
*-------------------------
}
*-------------------------

*-------------------------
if `all_2005' == 1 {
*-------------------------
cap cd "C:\Users\lmostrom\Documents\Amitabh\"

import delimited "PubMed_Search_Results_all_from2005.csv", varn(1) clear

split query_name, p("_")

gen QA = substr(query_name1, -2, 2) == "QA"
	drop query_name query_name1

ren pub_count pubs_
replace query_name2 = "All" if query_name2 == ""
reshape wide pubs_, i(QA year) j(query_name2) string

order QA year pubs_NIH pubs_Priv pubs_Pub pubs_All

foreach var of varlist pubs_NIH pubs_Priv pubs_Pub {
		gen sh_`var' = `var'/pubs_All
}

export delimited "all_pubs_by_funding_from2005.csv", replace

* Plots for # of pubs and share of all pubs
#delimit ;
tw (line pubs_NIH year if !QA, lc(red))
   (line pubs_Priv year if !QA, lc(green)),
 legend(order( 1 "Received NIH Funding" 2 "Exclusively Private Funding") r(1))
 yti("Number of PubMed Publications") xti("Year")
 subti("All Journals");
graph export "all_pubs_by_funding_notQA.png", replace as(png) wid(1200) hei(700);

tw (line pubs_NIH year if QA, lc(red))
   (line pubs_Priv year if QA, lc(green)),
 legend(order( 1 "Received NIH Funding" 2 "Exclusively Private Funding") r(1))
 yti("Number of PubMed Publications") xti("Year")
 subti("Top 13 Journals");
graph export "all_pubs_by_funding_QA.png", replace as(png) wid(1200) hei(700);

tw (line sh_pubs_NIH year if !QA, lc(red))
   (line sh_pubs_Priv year if !QA, lc(green)),
 legend(order( 1 "Received NIH Funding" 2 "Exclusively Private Funding") r(1))
 yti("Share of all Publications (%)") xti("Year")
 subti("All Journals");
graph export "all_pubs_sh_by_funding_notQA.png", replace as(png) wid(1200) hei(700);

tw (line sh_pubs_NIH year if QA, lc(red))
   (line sh_pubs_Priv year if QA, lc(green)),
 legend(order( 1 "Received NIH Funding" 2 "Exclusively Private Funding") r(1))
 yti("Share of all Publications (%)") xti("Year")
 subti("Top 13 Journals");
graph export "all_pubs_sh_by_funding_QA.png", replace as(png) wid(1200) hei(700);
#delimit cr

*-------------------------
}
*-------------------------

*-------------------------
if `pies' == 1 {
*-------------------------
cap cd "C:\Users\lmostrom\Dropbox\Amitabh\"
foreach QA in "" "_notQA" {
	import delimited "PubMed_Search_Results_forPies`QA'_from1980.csv", clear varn(1)
		split query_name, p("_") gen(fund)
		keep if fund1 == "Total"
		collapse (sum) all_pubs = pub_count, by(year)
		tempfile allpubs
		save `allpubs', replace

	import delimited "PubMed_Search_Results_forPies`QA'_from1980.csv", clear varn(1)
		split query_name, p("_") gen(group)
		collapse (sum) pub_count, by(group1 year)
		ren group1 group
			replace group = "About Diseases" if group == "Dis"
				gen grpid = 1 if group == "About Diseases"
			replace group = "Disease Mechanisms Only" if inlist(group, "Mech", "Mech1", "Mech2")
				replace grpid = 6 if group == "Disease Mechanisms Only"
			replace group = "Biological Phenomena Only" if inlist(group, "Bio", "Bio1", "Bio2")
				replace grpid = 3 if group == "Biological Phenomena Only"
			replace group = "Chemical Phenomena Only" if inlist(group, "Chem", "Chem1", "Chem2")
				replace grpid = 4 if group == "Chemical Phenomena Only"
			replace group = "Physical Phenomena Only" if inlist(group, "Phys", "Phys1", "Phys2")
				replace grpid = 5 if group == "Physical Phenomena Only"
			replace group = "Multiple Groups ex. Diseases" if ///
					inlist(group, "Mult", "MandBCP1", "MandBCP2", "MandBCP3", "MandBCP4")
				replace grpid = 2 if group == "Multiple Groups ex. Diseases"

		collapse (sum) pub_count, by(year group grpid)
			bys year: egen single_cat = total(pub_count) if inlist(grpid, 3, 4, 5, 6)
			bys year: ereplace single_cat = max(single_cat)
			replace pub_count = pub_count - single_cat if grpid == 2

	bys year: egen ingroup = total(pub_count) if group != "Total"
		bys year: ereplace ingroup = max(ingroup)
		replace group = "Other" if grpid == . & group == "Total"
			replace grpid = 7 if group == "Other"

		replace pub_count = pub_count-ingroup if group == "Other"

	gen decade = 10*int(year/10)
	collapse (sum) pub_count, by(decade group grpid)
	forval yr = 1980(10)2010 {
		if "`QA'" == "_notQA" {
			local subtitle "(All Journals)"
		}
		if "`QA'" == "" {
			local subtitle "(Top 13 Journals)"
		}

		graph pie pub_count if decade == `yr', sort(grpid) over(group) ///
					pl(1 percent, c(white) format(%9.3g)) ///
					pl(2 percent, c(white) format(%9.3g) gap(med)) ///
					pl(3 percent, c(white) format(%9.3g)) ///
					pl(4 percent, c(white) format(%9.3g)) ///
					pl(7 percent, c(white) format(%9.3g)) ///
					title("Published Paper Topics in the `yr's") subtitle("`subtitle'") legend(colfirst) ///
					pie(1, c(cranberry)) pie(2, c(purple)) pie(3, c(green)) ///
					pie(4, c(midblue)) pie(5, c(erose)) pie(6, c(dkorange)) pie(7, c(gs8))
		graph export "pie_chart_basic_science_`yr'`QA'.png", replace as(png)
	} // decade loop
} // QA / notQA loop

***** Now NIH vs. Privately Funded Research 2005-2018 *****
foreach QA in "" "_notQA" {
	import delimited "PubMed_Search_Results_forPies`QA'_from2005.csv", clear varn(1)
		split query_name, p("_") gen(group)
		gen nih = group2 == "NIH"
			drop group2
		keep if group1 == "Total"
		ren pub_count all_pubs
		keep all_pubs year nih
		tempfile totals
		save `totals', replace

	import delimited "PubMed_Search_Results_forPies`QA'_from2005.csv", clear varn(1)
		split query_name, p("_") gen(group)
		gen nih = group2 == "NIH"
			drop group2
		ren group1 group
			replace group = "About Diseases" if group == "Dis"
				gen grpid = 1 if group == "About Diseases"
			replace group = "Disease Mechanisms Only" if inlist(group, "Mech", "Mech1", "Mech2")
				replace grpid = 6 if group == "Disease Mechanisms Only"
			replace group = "Biological Phenomena Only" if inlist(group, "Bio", "Bio1", "Bio2")
				replace grpid = 3 if group == "Biological Phenomena Only"
			replace group = "Chemical Phenomena Only" if inlist(group, "Chem", "Chem1", "Chem2")
				replace grpid = 4 if group == "Chemical Phenomena Only"
			replace group = "Physical Phenomena Only" if inlist(group, "Phys", "Phys1", "Phys2")
				replace grpid = 5 if group == "Physical Phenomena Only"
			replace group = "Multiple Groups ex. Diseases" ///
					if inlist(group, "Mult", "MandBCP1", "MandBCP2", "MandBCP3", "MandBCP4")
				replace grpid = 2 if group == "Multiple Groups ex. Diseases"
				collapse (sum) pub_count, by(year group grpid nih)

		collapse (sum) pub_count, by(year nih group grpid)
			bys year nih: egen single_cat = total(pub_count) if inlist(grpid, 3, 4, 5, 6)
			bys year nih: ereplace single_cat = max(single_cat)
			replace pub_count = pub_count - single_cat if grpid == 2

	merge m:1 year nih using `totals', nogen assert(3)
		drop if group == "Total"
	append using `totals'

	bys year nih: egen ingroup = total(pub_count)
		replace group = "Other" if grpid == . & group == "Total"
			replace grpid = 7 if group == "Other"
		assert pub_count > ingroup if group == "Other"
		replace pub_count = pub_count-ingroup if group == "Other"

	collapse (sum) pub_count, by(group grpid nih)

	if "`QA'" == "" local journals "Top 13 Journals"
	else local journals "All Journals"

	forval nih = 0/1 {
		if `nih' == 0 {
			local title "Publications Receiving No Public Funding"
			local plabel7 "pl(7 percent, c(white) format(%9.3g))"
		}
		if `nih' == 1 {
			local title "Publications Receiving NIH Funding"
			if "`QA'" == "" local plabel7 ""
			else local plabel7 "pl(7 percent, c(white) format(%9.3g))"
		}

		graph pie pub_count if nih == `nih', sort(grpid) over(group) ///
					pl(1 percent, c(white) format(%9.3g)) ///
					pl(2 percent, c(white) format(%9.3g)) ///
					pl(3 percent, c(white) format(%9.3g)) ///
					pl(4 percent, c(white) format(%9.3g) gap(small)) `plabel7' ///
					title("`title'") subtitle("(`journals', 2005-2018)") legend(colfirst) ///
					pie(1, c(cranberry)) pie(2, c(purple)) pie(3, c(green)) ///
					pie(4, c(midblue)) pie(5, c(erose)) pie(6, c(dkorange)) pie(7, c(gs8))
		graph export "pie_chart_basic_science`QA'_2005-2018_nih`nih'.png", replace as(png)
	} // end NIH/not NIH loop
} // end QA/not QA loop
*-------------------------
} // end pies
*-------------------------

*-------------------------
if `pies_bydisease' == 1 {
*-------------------------
cap cd "C:\Users\lmostrom\Dropbox\Amitabh\"

foreach QA in "" "_notQA" {
foreach maj in "" /*"_notmaj"*/ {
	use "Master_dta/pmids_by`maj'2ndcat.dta", clear
		drop if pmid == . // not that many (73)
		duplicates tag pmid query_name, gen(dup)
			bys pmid query_name: egen max_year = max(year)
			drop if year < max_year // just different publication dates
			drop dup
			isid pmid query_name
		duplicates tag pmid, gen(dup)
			drop if dup > 0 & query_name == "Mult"
			drop dup
		isid pmid

		tempfile cat2
		save `cat2', replace

	use "Master_dta/pmids`QA'_bydisease.dta", clear
		drop query_name query
		bys pmid: egen max_year = max(year)
			drop if year < max_year

	merge m:1 pmid using `cat2', keep(1 3)
		drop max_year
		ren query_name cat2
		replace cat2 = "None" if _merge == 1 & cat == ""

	if "`QA'" == "" local journals "(Top 13 Journals Only)"
	if "`QA'" == "_notQA" local journals "(All Journals)"

	*gen decade = 10*int(year/10)
	collapse (count) n_pubs = pmid, by(dis_abbr cat2 nih /*decade*/)

	reshape wide n_pubs, i(dis_abbr nih /*decade*/) j(cat2) string
	reshape long n_pubs, i(dis_abbr nih /*decade*/) j(cat2) string
	replace n_pubs = 0 if n_pubs == .
		replace cat2 = "Biological Processes" if cat2 == "BioPhenom"
			gen catcode = 1 if cat2 == "Biological Processes"
		replace cat2 = "Cells & Organisms" if cat2 == "CellsOrgs"
			replace catcode = 2 if cat2 == "Cells & Organisms"
		replace cat2 = "Chemicals (excl. Pharmaceuticals)" if cat2 == "Chemicals"
			replace catcode = 3 if cat2 == "Chemicals (excl. Pharmaceuticals)"
		replace cat2 = "Environment & Public Health" if cat2 == "EnvPH"
			replace catcode = 4 if cat2 == "Environment & Public Health"
		replace cat2 = "Health Administration" if cat2 == "HealthAdmin"
			replace catcode = 5 if cat2 == "Health Administration"
		replace cat2 = "Health Econ & Organizations" if cat2 == "HealthEcon"
			replace catcode = 6 if cat2 == "Health Econ & Organizations"
		replace cat2 = "Medical Equipment & Techniques" if cat2 == "Tech"
			replace catcode = 7 if cat2 == "Medical Equipment & Techniques"
		replace cat2 = "Pharmaceuticals" if cat2 == "Pharma"
			replace catcode = 8 if cat2 == "Pharmaceuticals"
		replace cat2 = "Multiple Categories (excl. Pharma)" if cat2 == "Mult"
			replace catcode = 9 if cat2 == "Multiple Categories (excl. Pharma)"
		replace cat2 = "Other/None" if cat2 == "None"
			replace catcode = 10 if cat2 == "Other/None"

	levelsof dis_abbr, local(diseases) clean

	*Only testing subset of diseases by decade:
	*local diseases "Cardio Neoplasms Neurologic Substance Tropic OthInfectious"

	foreach abbr of local diseases {

		if "`abbr'" == "Cardio" local dis "Cardiovascular Diseases"
		if "`abbr'" == "ChronicResp" local dis "Chronic Respiratory Diseases"
		if "`abbr'" == "Kidney" local dis "Diabetes and Kidney Diseases"
		if "`abbr'" == "Digestive" local dis "Digestive Diseases"
		if "`abbr'" == "Enteritis" local dis "Enteric Infections"
		if "`abbr'" == "STIs" local dis "HIV/AIDS and other STIs"
		if "`abbr'" == "Pregnancy" local dis "Maternal and Neonatal Disorders"
		if "`abbr'" == "Mental" local dis "Mental Disorders"
		if "`abbr'" == "Muscle" local dis "Musculoskeletal Disorders"
		if "`abbr'" == "Tropic" local dis "Neglected Tropical Diseases and Malaria"
		if "`abbr'" == "Neoplasms" local dis "Neoplasms"
		if "`abbr'" == "Neurologic" local dis "Neurological Disorders"
		if "`abbr'" == "Dementia" local dis "Alzheimer's & Related Dementias"
		if "`abbr'" == "Nutrition" local dis "Nutritional Deficiencies"
		if "`abbr'" == "OthInfectious" local dis "Other Infectious Diseases"
		if "`abbr'" == "RespInf" local dis "Respiratory Infections and Tuberculosis"
		if "`abbr'" == "Senses" local dis "Sense Organ Diseases"
		if "`abbr'" == "Skin" local dis "Skin and Subcutaneous Diseases"
		if "`abbr'" == "Substance" local dis "Substance Use Disorders"

		local pielabels "pl(3 percent, c(white) format(%9.3g)) pl(9 percent, c(white) format(%9.3g)) pl(10 percent, c(white) format(%9.3g))"
		
		if !inlist("`abbr'", "Nutrition", "Mental") {
			local pielabels "`pielabels' pl(7 percent, c(white) format(%9.3g))"
		}
		if inlist("`abbr'", "Mental") {
			local pielabels "`pielabels' pl(7 percent, c(white) format(%9.3g) gap(small))"
		}
		if inlist("`abbr'", "Mental", "Pregnancy") {
			local pielabels "`pielabels' pl(1 percent, c(white) format(%9.3g))"
		}
		if inlist("`abbr'", "Muscle", "Neoplasms", "Senses") {
			local pielabels "`pielabels' pl(1 percent, c(white) format(%9.3g) gap(small))"
		}
		if inlist("`abbr'", "Skin") {
			local pielabels "`pielabels' pl(1 percent, c(white) format(%9.3g) gap(medium))"
		}
		if inlist("`abbr'", "Enteritis", "Muscle", "OthInfectious", "RespInf", ///
							"Skin", "STIs", "Tropic") {
			local pielabels "`pielabels' pl(2 percent, c(white) format(%9.3g))"
		}
		if inlist("`abbr'", "STIs", "Substance", "Mental") ///
				| ("`abbr'" == "Dementia" & "`QA'" == "_notQA") {
			local pielabels "`pielabels' pl(5 percent, c(white) format(%9.3g))"
		}
		if inlist("`abbr'", "Tropic") ///
			| ("`abbr'" == "RespInf" & "`QA'" == "") {
			local pielabels "`pielabels' pl(4 percent, c(white) format(%9.3g))"
		}
		if inlist("`abbr'", "Substance") {
			local pielabels "`pielabels' pl(8 percent, c(white) format(%9.3g) gap(small))"
		}


		forval nih01 = 0/1 {
			if `nih01' == 0 local funder = "Non-NIH-Funded"
			if `nih01' == 1 local funder = "NIH-Funded"

		/*forval dec = 1980(10)2010 {*/

			#delimit ;
			graph pie n_pubs if dis_abbr == "`abbr'" & nih == `nih01' /*& decade == `dec'*/,
						over(cat2) sort(catcode) legend(colfirst)
						title("`funder' Non-Trial Publications" "About `dis'")
						subtitle("By Additional Major Topic" "`journals'" /*"`dec's"*/)
						`pielabels'
						pie(1, c(dkgreen)) pie(2, c(erose)) pie(3, c(navy))
						pie(4, c(midgreen)) pie(5, c(dkorange)) pie(6, c(eltblue))
						pie(7, c(gs5)) pie(8, c(cranberry))
						pie(9, c(purple)) pie(10, c(gs8));
			graph export "pie_bydisease`QA'_`abbr'_nih`nih01'`maj'.png",
				replace as(png) wid(1200) hei(800);
			#delimit cr
		/*}*/ // end decade loop
		} // end NIH/non-NIH loop

	} // end diseases loop
} // end Major Topic / MeSH Term loop
} // end QA/notQA loop
*-------------------------
} // end pies_bydisease
*-------------------------

*-------------------------
if `ts_bydisease' == 1 {
*-------------------------
cap cd "C:\Users\lmostrom\Dropbox\Amitabh\"

foreach QA in "" "_notQA" {
foreach list in "by2ndcat" "medtech_subcats" "pharma_subcats" {
	use "Master_dta/pmids_`list'.dta", clear
		drop if pmid == . // not that many (73)
		duplicates tag pmid query_name, gen(dup)
			bys pmid query_name: egen max_year = max(year)
			drop if year < max_year // just different publication dates
			drop dup
			isid pmid query_name
		duplicates tag pmid, gen(dup)
			if "`list'" == "by2ndcat" drop if dup > 0 & query_name == "Mult"
			if "`list'" == "medtech_subcats" drop if dup > 0 & query_name == "AllTech"
			if "`list'" == "pharma_subcats" drop if dup > 0 & query_name == "AllPharma"
			drop dup
		isid pmid

		tempfile cat2
		save `cat2', replace

	use "Master_dta/pmids`QA'_bydisease.dta", clear
		drop query_name query
		bys pmid: egen max_year = max(year)
			drop if year < max_year

	merge m:1 pmid using `cat2', keep(1 3)
		drop max_year
		ren query_name cat2
		replace cat2 = "None" if _merge == 1 & cat == ""

	if "`QA'" == "" local journals "(Top 13 Journals Only)"
	if "`QA'" == "_notQA" local journals "(All Journals)"

	collapse (count) n_pubs = pmid, by(dis_abbr cat2 nih year)

	reshape wide n_pubs, i(dis_abbr nih year) j(cat2) string
	reshape long n_pubs, i(dis_abbr nih year) j(cat2) string
	replace n_pubs = 0 if n_pubs == .
	bys dis_abbr nih year: egen tot_pubs = total(n_pubs)
		gen sh_pubs = n_pubs/tot_pubs*100

	levelsof cat2, local(categories) clean
	levelsof dis_abbr, local(diseases) clean
*=====*
	*---* If All Secondary Categories *---*
		replace cat2 = "Biological Processes" if cat2 == "BioPhenom"
			gen catcode = 1 if cat2 == "Biological Processes"
		replace cat2 = "Cells & Organisms" if cat2 == "CellsOrgs"
			replace catcode = 2 if cat2 == "Cells & Organisms"
		replace cat2 = "Chemicals (excl. Pharmaceuticals)" if cat2 == "Chemicals"
			replace catcode = 3 if cat2 == "Chemicals (excl. Pharmaceuticals)"
		replace cat2 = "Environment & Public Health" if cat2 == "EnvPH"
			replace catcode = 4 if cat2 == "Environment & Public Health"
		replace cat2 = "Health Administration" if cat2 == "HealthAdmin"
			replace catcode = 5 if cat2 == "Health Administration"
		replace cat2 = "Health Econ & Organizations" if cat2 == "HealthEcon"
			replace catcode = 6 if cat2 == "Health Econ & Organizations"
		replace cat2 = "Medical Equipment & Techniques" if cat2 == "Tech"
			replace catcode = 7 if cat2 == "MedicalEquipment & Techniques"
		replace cat2 = "Pharmaceuticals" if cat2 == "Pharma"
			replace catcode = 8 if cat2 == "Pharmaceuticals"
		replace cat2 = "Multiple Categories (excl. Pharma)" if cat2 == "Mult"
			replace catcode = 9 if cat2 == "Multiple Categories (excl. Pharma)"
		replace cat2 = "Other/None" if cat2 == "None"
			replace catcode = 10 if cat2 == "Other/None"

	*---* If Breaking Down Medical Equipment & Techniques *---*
		replace cat2 = "Anesthesia & Analgesia Only" if cat2 == "Anesth"
			replace catcode = 1 if cat2 == "Anesthesia & Analgesia Only"
		replace cat2 = "Dentistry Only" if cat2 == "Dent"
			replace catcode = 2 if cat2 == "Dentistry Only"
		replace cat2 = "Diagnosis Only" if cat2 == "Diagnosis"
			replace catcode = 3 if cat2 == "Diagnosis Only"
		replace cat2 = "Equipment Only" if cat2 == "Equipment"
			replace catcode = 4 if cat2 == "Equipment Only"
		replace cat2 = "Investigative Techniques Only" if cat2 == "Inv"
			replace catcode = 5 if cat2 == "Investigative Techniques Only"
		replace cat2 = "Surgical Procedures Only" if cat2 == "Surg"
			replace catcode = 6 if cat2 == "Surgical Procedures Only"
		replace cat2 = "Therapeutics Only" if cat2 == "Therap"
			replace catcode = 7 if cat2 == "Therapeutics Only"
		replace cat2 = "Other Equipment & Techniques Topics" if cat2 == "AllTech"
			replace catcode = 8 if cat2 == "Other Equipment & Techniques Topics"		

	*---* If Breaking Down Pharmaceutical Preparations *---* 
		replace cat2 = "Controlled Substances" if cat2 == "ContSub"
			replace catcode = 1 if cat2 == "Controlled Substances"
		replace cat2 = "Dosage Forms" if cat2 == "Dosage"
			replace catcode = 2 if cat2 == "Dosage Forms"
		replace cat2 = "Drug Combinations" if cat2 == "Combos"
			replace catcode = 3 if cat2 == "Drug Combinations"
		replace cat2 = "Traditional/Homeopathic Remedies" if cat2 == "NatDrugs"
			replace catcode = 4 if cat2 == "Traditional/Homeopathic Remedies"
		replace cat2 = "Essential Drugs" if cat2 == "EssDrugs"
			replace catcode = 5 if cat2 == "Essential Drugs"
		replace cat2 = "Generic Drugs" if cat2 == "GenDrugs"
			replace catcode = 6 if cat2 == "Generic Drugs"
		replace cat2 = "Investigational Drugs" if cat2 == "InvDrugs"
			replace catcode = 7 if cat2 == "Investigational Drugs"
		replace cat2 = "Illegal Drugs & Marijuana" if cat2 == "IllicitDrugs"
			replace catcode = 8 if cat2 == "Illegal Drugs & Marijuana"
		replace cat2 = "Nonprescription Drugs" if cat2 == "NonpreDrugs"
			replace catcode = 9 if cat2 == "Nonprescription Drugs"
		replace cat2 = "Prescription Drugs" if cat2 == "PreDrugs"
			replace catcode = 10 if cat2 == "Prescription Drugs"
		replace cat2 = "Substandard Drugs" if cat2 == "Substandard"
			replace catcode = 11 if cat2 == "Substandard Drugs"
		replace cat2 = "Other Pharmaceutical Topics" if cat2 == "AllPharma"
			replace catcode = 12 if cat2 == "Other Pharmaceutical Topics"
*=====*
	foreach abbr of local diseases {

		if "`abbr'" == "Cardio" local dis "Cardiovascular Diseases"
		if "`abbr'" == "ChronicResp" local dis "Chronic Respiratory Diseases"
		if "`abbr'" == "Kidney" local dis "Diabetes and Kidney Diseases"
		if "`abbr'" == "Digestive" local dis "Digestive Diseases"
		if "`abbr'" == "Enteritis" local dis "Enteric Infections"
		if "`abbr'" == "STIs" local dis "HIV/AIDS and other STIs"
		if "`abbr'" == "Pregnancy" local dis "Maternal and Neonatal Disorders"
		if "`abbr'" == "Mental" local dis "Mental Disorders"
		if "`abbr'" == "Muscle" local dis "Musculoskeletal Disorders"
		if "`abbr'" == "Tropic" local dis "Neglected Tropical Diseases and Malaria"
		if "`abbr'" == "Neoplasms" local dis "Neoplasms"
		if "`abbr'" == "Neurologic" local dis "Neurological Disorders"
		if "`abbr'" == "Dementia" local dis "Alzheimer's & Related Dementias"
		if "`abbr'" == "Nutrition" local dis "Nutritional Deficiencies"
		if "`abbr'" == "OthInfectious" local dis "Other Infectious Diseases"
		if "`abbr'" == "RespInf" local dis "Respiratory Infections and Tuberculosis"
		if "`abbr'" == "Senses" local dis "Sense Organ Diseases"
		if "`abbr'" == "Skin" local dis "Skin and Subcutaneous Diseases"
		if "`abbr'" == "Substance" local dis "Substance Use Disorders"

	foreach cat_abbr of local categories {
	*=====*
		*---* If All Secondary Categories *---*
		if "`cat_abbr'" == "BioPhenom" local catname "Biological Processes" 
		if "`cat_abbr'" == "CellsOrgs" local catname "Cells & Organisms" 
		if "`cat_abbr'" == "Chemicals" local catname "Chemicals (excl. Pharmaceuticals)" 
		if "`cat_abbr'" == "EnvPH" local catname "Environment & Public Health" 
		if "`cat_abbr'" == "HealthAdmin" local catname "Health Administration" 
		if "`cat_abbr'" == "HealthEcon" local catname "Health Econ & Organizations" 
		if "`cat_abbr'" == "Tech" local catname "Medical Equipment & Techniques" 
		if "`cat_abbr'" == "Pharma" local catname "Pharmaceuticals" 
		if "`cat_abbr'" == "Mult" local catname "Multiple Categories (excl. Pharma)" 
		if "`cat_abbr'" == "None" local catname "Other/None"

		*---* If Breaking Down Medical Equipment & Techniques *---*
		if "`cat_abbr'" == "Anesth" local catname "Anesthesia & Analgesia Only"
		if "`cat_abbr'" == "Dent" local catname "Dentistry Only"
		if "`cat_abbr'" == "Diagnosis" local catname "Diagnosis Only"
		if "`cat_abbr'" == "Equipment" local catname "Equipment Only"
		if "`cat_abbr'" == "Inv" local catname "Investigative Techniques Only"
		if "`cat_abbr'" == "Surg" local catname "Surgical Procedures Only"
		if "`cat_abbr'" == "Therap" local catname "Therapeutics Only"
		if "`cat_abbr'" == "AllTech" local catname "Other Equipment & Techniques Topics"

		*---* If Breaking Down Pharmaceutical Preparations *---* 
		if "`cat_abbr'" == "ContSub" local catname "Controlled Substances"
		if "`cat_abbr'" == "Dosage" local catname "Dosage Forms"
		if "`cat_abbr'" == "Combos" local catname "Drug Combinations"
		if "`cat_abbr'" == "NatDrugs" local catname "Traditional/Homeopathic Remedies"
		if "`cat_abbr'" == "EssDrugs" local catname "Essential Drugs"
		if "`cat_abbr'" == "GenDrugs" local catname "Generic Drugs"
		if "`cat_abbr'" == "InvDrugs" local catname "Investigational Drugs"
		if "`cat_abbr'" == "IllicitDrugs" local catname "Illegal Drugs & Marijuana"
		if "`cat_abbr'" == "NonpreDrugs" local catname "Nonprescription Drugs"
		if "`cat_abbr'" == "PreDrugs" local catname "Prescription Drugs"
		if "`cat_abbr'" == "Substandard" local catname "Substandard Drugs"
		if "`cat_abbr'" == "AllPharma" local catname "Other Pharmaceutical Topics"
	*=====*

			#delimit ;
			tw (line sh_pubs year if dis_abbr == "`abbr'" & cat2 == "`catname'" 
													& nih == 1, lc(red))
			   (line sh_pubs year if dis_abbr == "`abbr'" & cat2 == "`catname'" 
			   										& nih == 0 & year <= 2004, lc(green) lp(-))
			   (line sh_pubs year if dis_abbr == "`abbr'" & cat2 == "`catname'" 
			   										& nih == 0 & year >= 2005, lc(green) lp(l)),
				legend(order(1 "NIH Presence" 2 "No NIH Presence" 3 "No Public Presence") r(1))
				yti("Share of Non-Trial Pubs Also About" "`catname' (%)" " ")
				title("`dis'") xti("") subti("`journals'");
			graph export "ts_`list'_bydisease`QA'_`abbr'_`cat_abbr'.png",
				replace as(png) wid(1200) hei(800);
			#delimit cr
	} // end cat2 loop
	} // end diseases loop

	collapse (sum) n_pubs, by(cat2 nih year)
	bys nih year: egen tot_pubs = total(n_pubs)
		gen sh_pubs = n_pubs/tot_pubs*100

	foreach cat_abbr of local categories {
	*=====*
		*---* If All Secondary Categories *---*
		if "`cat_abbr'" == "BioPhenom" local catname "Biological Processes" 
		if "`cat_abbr'" == "CellsOrgs" local catname "Cells & Organisms" 
		if "`cat_abbr'" == "Chemicals" local catname "Chemicals (excl. Pharmaceuticals)" 
		if "`cat_abbr'" == "EnvPH" local catname "Environment & Public Health" 
		if "`cat_abbr'" == "HealthAdmin" local catname "Health Administration" 
		if "`cat_abbr'" == "HealthEcon" local catname "Health Econ & Organizations" 
		if "`cat_abbr'" == "Tech" local catname "Medical Equipment & Techniques" 
		if "`cat_abbr'" == "Pharma" local catname "Pharmaceuticals" 
		if "`cat_abbr'" == "Mult" local catname "Multiple Categories (excl. Pharma)" 
		if "`cat_abbr'" == "None" local catname "Other/None"

		*---* If Breaking Down Medical Equipment & Techniques *---*
		if "`cat_abbr'" == "Anesth" local catname "Anesthesia & Analgesia Only"
		if "`cat_abbr'" == "Dent" local catname "Dentistry Only"
		if "`cat_abbr'" == "Diagnosis" local catname "Diagnosis Only"
		if "`cat_abbr'" == "Equipment" local catname "Equipment Only"
		if "`cat_abbr'" == "Inv" local catname "Investigative Techniques Only"
		if "`cat_abbr'" == "Surg" local catname "Surgical Procedures Only"
		if "`cat_abbr'" == "Therap" local catname "Therapeutics Only"
		if "`cat_abbr'" == "AllTech" local catname "Other Equipment & Techniques Topics"

		*---* If Breaking Down Pharmaceutical Preparations *---* 
		if "`cat_abbr'" == "ContSub" local catname "Controlled Substances"
		if "`cat_abbr'" == "Dosage" local catname "Dosage Forms"
		if "`cat_abbr'" == "Combos" local catname "Drug Combinations"
		if "`cat_abbr'" == "NatDrugs" local catname "Traditional/Homeopathic Remedies"
		if "`cat_abbr'" == "EssDrugs" local catname "Essential Drugs"
		if "`cat_abbr'" == "GenDrugs" local catname "Generic Drugs"
		if "`cat_abbr'" == "InvDrugs" local catname "Investigational Drugs"
		if "`cat_abbr'" == "IllicitDrugs" local catname "Illegal Drugs & Marijuana"
		if "`cat_abbr'" == "NonpreDrugs" local catname "Nonprescription Drugs"
		if "`cat_abbr'" == "PreDrugs" local catname "Prescription Drugs"
		if "`cat_abbr'" == "Substandard" local catname "Substandard Drugs"
		if "`cat_abbr'" == "AllPharma" local catname "Other Pharmaceutical Topics"
	*=====*		


			#delimit ;
			tw (line sh_pubs year if cat2 == "`catname'" & nih == 1, lc(red))
			   (line sh_pubs year if cat2 == "`catname'" 
			   										& nih == 0 & year <= 2004, lc(green) lp(-))
			   (line sh_pubs year if cat2 == "`catname'" 
			   										& nih == 0 & year >= 2005, lc(green) lp(l)),
				legend(order(1 "NIH Presence" 2 "No NIH Presence" 3 "No Public Presence") r(1))
				yti("Share of Non-Trial Pubs Also About" "`catname' (%)" " ")
				title("All Diseases") xti("") subti("`journals'");
			graph export "ts_`list'_bydisease`QA'_all_`cat_abbr'.png",
				replace as(png) wid(1200) hei(800);
			#delimit cr
	} // end cat2 loop
} // end list loop
} // end QA/notQA loop
*-------------------------
} // end ts_bydisease
*-------------------------

*-------------------------
if `pies_bydisease_sub' == 1 {
*-------------------------
cap cd "C:\Users\lmostrom\Dropbox\Amitabh\"

foreach list in "_sub" "_sub_therapy" {
foreach QA in "" "_notQA" {
	use "Master_dta/pmids_by`list'2ndcat.dta", clear
		drop if pmid == . // not that many (73)
		duplicates tag pmid query_name, gen(dup)
			bys pmid query_name: egen max_year = max(year)
			drop if year < max_year // just different publication dates
			drop dup
			isid pmid query_name
		duplicates tag pmid, gen(dup)
			if "`list'" == "_sub" ///
				drop if dup > 0 & (query_name == "mult" | query_name == "therapy_and")
			if "`list'" == "_sub_therapy" drop if dup > 0 & query_name == "alltherapy"
			drop dup
		isid pmid

		tempfile cat2
		save `cat2', replace

	use "Master_dta/pmids`QA'_bydisease.dta", clear
		drop query_name query
		bys pmid: egen max_year = max(year)
			drop if year < max_year

	merge m:1 pmid using `cat2', keep(1 3)
		drop max_year
		ren query_name cat2
		replace cat2 = "none" if _merge == 1 & cat == ""

	if "`QA'" == "" local journals "(Top 13 Journals Only)"
	if "`QA'" == "_notQA" local journals "(All Journals)"

	gen decade = 10*int(year/10)
	collapse (count) n_pubs = pmid, by(dis_abbr cat2 nih /*decade*/)

	reshape wide n_pubs, i(dis_abbr nih) j(cat2) string
	reshape long n_pubs, i(dis_abbr nih) j(cat2) string
	replace n_pubs = 0 if n_pubs == .

	*=====*
		*---* All Subheadings *---*
		replace cat2 = "Other Subheadings" ///
				if !inlist(cat2, "diagnosis", "physiology", "therapy", "therapy_and", "mult", "none") ///
					& "`list'" == "_sub"
			gen catcode = 5 if cat2 == "Other Subheadings"
		replace cat2 = "Diagnosis" if cat2 == "diagnosis"
			replace catcode = 1 if cat2 == "Diagnosis"
		replace cat2 = "Physiology" if cat2 == "physiology"
			replace catcode = 2 if cat2 == "Physiology"
		replace cat2 = "Therapy Only" if cat2 == "therapy"
			replace catcode = 3 if cat2 == "Therapy Only"
		replace cat2 = "Therapy And Others" if cat2 == "therapy_and"
			replace catcode = 4 if cat2 == "Therapy And Others"
		replace cat2 = "Multiple (exc. Therapy)" if cat2 == "mult"
			replace catcode = 6 if cat2 == "Multiple (exc. Therapy)"
		replace cat2 = "No Subheadings" if cat2 == "none" & "`list'" == "_sub"
			replace catcode = 7 if cat2 == "No Subheadings"

		*---* Therapy-Related Subheadings Only *---*
		replace cat2 = "Other Therapy Subheading" ///
				if inlist(cat2, "dosage", "poisoning", "diet", "nursing", "radio", "rehab")
			replace catcode = 5 if cat2 == "Other Therapy Subheading"
		replace cat2 = "Adverse Effects of Treatment" if cat2 == "adverse"
			replace catcode = 1 if cat2 == "Adverse Effects of Treatment"
		replace cat2 = "Drug Therapy" if cat2 == "drugs"
			replace catcode = 2 if cat2 == "Drug Therapy"
		replace cat2 = "Prevention & Control" if cat2 == "prevention"
			replace catcode = 3 if cat2 == "Prevention & Control"
		replace cat2 = "Surgery" if cat2 == "surgery"
			replace catcode = 4 if cat2 == "Surgery"
		replace cat2 = "General Therapy Subheading" if cat2 == "alltherapy"
			replace catcode = 6 if cat2 == "General Therapy Subheading"
		replace cat2 = "No Therapy Subheading" if cat2 == "none" & "`list'" == "_sub_therapy"
			replace catcode = 7 if cat2 == "No Therapy Subheading"
	*=====*

	levelsof dis_abbr, local(diseases) clean

	foreach abbr of local diseases {

		if "`abbr'" == "Cardio" local dis "Cardiovascular Diseases"
		if "`abbr'" == "ChronicResp" local dis "Chronic Respiratory Diseases"
		if "`abbr'" == "Kidney" local dis "Diabetes and Kidney Diseases"
		if "`abbr'" == "Digestive" local dis "Digestive Diseases"
		if "`abbr'" == "Enteritis" local dis "Enteric Infections"
		if "`abbr'" == "STIs" local dis "HIV/AIDS and other STIs"
		if "`abbr'" == "Pregnancy" local dis "Maternal and Neonatal Disorders"
		if "`abbr'" == "Mental" local dis "Mental Disorders"
		if "`abbr'" == "Muscle" local dis "Musculoskeletal Disorders"
		if "`abbr'" == "Tropic" local dis "Neglected Tropical Diseases and Malaria"
		if "`abbr'" == "Neoplasms" local dis "Neoplasms"
		if "`abbr'" == "Neurologic" local dis "Neurological Disorders"
		if "`abbr'" == "Dementia" local dis "Alzheimer's & Related Dementias"
		if "`abbr'" == "Nutrition" local dis "Nutritional Deficiencies"
		if "`abbr'" == "OthInfectious" local dis "Other Infectious Diseases"
		if "`abbr'" == "RespInf" local dis "Respiratory Infections and Tuberculosis"
		if "`abbr'" == "Senses" local dis "Sense Organ Diseases"
		if "`abbr'" == "Skin" local dis "Skin and Subcutaneous Diseases"
		if "`abbr'" == "Substance" local dis "Substance Use Disorders"

		forval nih01 = 0/1 {
			if `nih01' == 0 local funder = "Non-NIH-Funded"
			if `nih01' == 1 local funder = "NIH-Funded"

		/*forval dec = 1980(10)2010 {*/

		if "`list'" == "_sub" {
			local slice_colors "pie(1, c(dkorange)) pie(2, c(dkgreen)) pie(3, c(midblue)) pie(4, c(navy)) pie(5, c(gs10)) pie(6, c(purple)) pie(7, c(gs8))"

			local pielabs "pl(3 percent, c(white) format(%9.3g) gap(huge)) pl(4 percent, c(white) format(%9.3g)) pl(5 percent, c(white) format(%9.3g)) pl(6 percent, c(white) format(%9.3g))"
		}

		if "`list'" == "_sub_therapy" {
			local slice_colors "pie(1, c(sienna)) pie(2, c(cranberry)) pie(3, c(navy)) pie(4, c(green)) pie(5, c(gs10)) pie(6, c(midblue)) pie(7, c(gs8))"

			local pielabs "pl(6 percent, c(white) format(%9.3g)) pl(7 percent, c(white) format(%9.3g))"

			if !inlist("`abbr'", "Tropic", "STIs") {
				local pielabs "`pielabs' pl(1 percent, c(white) format(%9.3g) gap(huge))"
			}
			if !inlist("`abbr'", "Senses", "Substance") {
				local pielabs "`pielabs' pl(2 percent, c(white) format(%9.3g))"
			}

			if inlist("`abbr'", "RespInf", "STIs", "Substance", "Tropic", "OthInfectious") {
				local pielabs "`pielabs' pl(3 percent, c(white) format(%9.3g) gap(huge))"
			}

			if !inlist("`abbr'", "Mental", "Dementia", "RespInf", "STIs", "Substance", ///
						"OthInfectious", "Tropic", "Pregnancy") | ///
					("`abbr'" == "Pregnancy" & `nih01' == 0) {
				local pielabs "`pielabs'  pl(4 percent, c(white) format(%9.3g))"
			}
		}

			#delimit ;
			graph pie n_pubs if dis_abbr == "`abbr'" & nih == `nih01' /*& decade == `dec'*/,
						over(cat2) sort(catcode) legend(colfirst)
						title("`funder' Non-Trial Publications" "About `dis'")
						subtitle("By Subheading" "`journals'")
						`pielabs' `slice_colors'
						legend(size(small) symx(small) symy(small) forcesize);
			graph save "gphs/pies_bydisease`QA'_`abbr'_nih`nih01'`list'.gph", replace;
			graph export "pies_bydisease`QA'_`abbr'_nih`nih01'`list'.png",
				replace as(png) wid(1200) hei(800);
			#delimit cr
		/*}*/ // end decade loop
		} // end NIH/non-NIH loop

	} // end diseases loop
} // end QA/notQA loop

	foreach abbr of local diseases {

		#delimit ;
		grc1leg "gphs/pies_bydisease_`abbr'_nih1`list'.gph"
				"gphs/pies_bydisease_notQA_`abbr'_nih1`list'.gph"
				"gphs/pies_bydisease_`abbr'_nih0`list'.gph"
				"gphs/pies_bydisease_notQA_`abbr'_nih0`list'.gph",
			legendfrom("gphs/pies_bydisease_`abbr'_nih1`list'.gph")
			colfirst r(2);
		graph export "pies_combined`list'_bydisease_`abbr'.png", replace as(png) wid(1200) hei(700);
		#delimit cr

	} // end diseases loop

} // end _sub / _sub_therapy loop



*-------------------------
} // end pies_bydisease_sub
*-------------------------


*-------------------------
if `nih_vs_priv' == 1 {
*-------------------------

cap cd "C:\Users\lmostrom\Dropbox\Amitabh\"

foreach QA in /*""*/ "_notQA" {
	import delimited "PubMed_Search_Results_forPies`QA'_from2005.csv", clear varn(1)
		split query_name, p("_") gen(group)
		gen nih = group2 == "NIH"
			drop group2
		keep if group1 == "Total"
		ren pub_count all_pubs
		keep all_pubs year nih
		tempfile totals05
		save `totals05', replace

	import delimited "PubMed_Search_Results_forPies`QA'_from1980.csv", clear varn(1)
		split query_name, p("_") gen(group)
		gen nih = group2 == "NIH"
			drop group2
		keep if group1 == "Total"
		ren pub_count all_pubs
		keep all_pubs year nih
		keep if inrange(year, 1980, 2004)
		append using `totals05'
		tempfile totals
		save `totals', replace

	import delimited "PubMed_Search_Results_forPies`QA'_from1980.csv", clear varn(1)
		split query_name, p("_") gen(group)
		gen nih = group2 == "NIH"
			drop group2
		ren group1 group
		keep if inrange(year, 1980, 2004)
		tempfile pubs80
		save `pubs80', replace

	import delimited "PubMed_Search_Results_forPies`QA'_from2005.csv", clear varn(1)
		split query_name, p("_") gen(group)
		gen nih = group2 == "NIH"
			drop group2
		ren group1 group
		append using `pubs80'
			gen grpname = "Diseases" if group == "Dis"
				gen grpid = 1 if group == "Dis"
			replace group = "Mech" if inlist(group, "Mech1", "Mech2")
				replace grpname = "Disease Mechanisms Only" if group == "Mech"
				replace grpid = 6 if group == "Mech"
			replace group = "Bio" if inlist(group, "Bio1", "Bio2")
				replace grpname = "Biological Phenomena Only" if group == "Bio"
				replace grpid = 3 if group == "Bio"
			replace group = "Chem" if inlist(group, "Chem1", "Chem2")
				replace grpname = "Chemical Phenomena Only" if group == "Chem"
				replace grpid = 4 if group == "Chem"
			replace group = "Phys" if inlist(group, "Phys1", "Phys2")
				replace grpname = "Physical Phenomena Only" if group == "Phys"
				replace grpid = 5 if group == "Phys"
			replace group = "Mult" if inlist(group, "MandBCP1", "MandBCP2", "MandBCP3", "MandBCP4")
				replace grpname = "Multiple Groups ex. Diseases" if group == "Mult"
				replace grpid = 2 if group == "Mult"
			
			collapse (sum) pub_count, by(year group grpname grpid nih)

			bys year nih: egen single_cat = total(pub_count) if inlist(grpid, 3, 4, 5, 6)
			bys year nih: ereplace single_cat = max(single_cat)
			replace pub_count = pub_count - single_cat if grpid == 2

	merge m:1 year nih using `totals', nogen assert(3)
		drop if group == "Total"
	append using `totals'

	bys year nih: egen ingroup = total(pub_count)
		replace group = "Other" if pub_count == . & group == ""
			replace grpname = "Other Disciplines" if group == "Other"
			replace grpid = 7 if group == "Other"
		assert all_pubs > ingroup
		replace pub_count = all_pubs-ingroup if group == "Other"

	bys year group: egen tot_bygrp = total(pub_count)
		gen nih_sh = pub_count/tot_bygrp*100 if nih == 1

	gen pub_sh = pub_count/all_pubs*100
	gen pub_sh_sq = pub_sh^2
	bys year nih: egen hhi = total(pub_sh_sq)

	if "`QA'" == "" local journals "Top 13 Journals"
	else {
		local journals "All Journals"
		replace pub_count = pub_count/1000
			local units "(in Thousands)"
	}

	foreach grp in "Dis" "Mech" "Bio" "Chem" "Phys" "Mult" "Other" {
		if "`grp'" == "Dis" local cat "Diseases"
		if "`grp'" == "Mech" local cat "Disease Mechanisms Only"
		if "`grp'" == "Bio" local cat "Biological Phenomena Only"
		if "`grp'" == "Chem" local cat "Chemical Phenomena Only"
		if "`grp'" == "Phys" local cat "Physical Phenomena Only"
		if "`grp'" == "Mult" local cat "Multiple Groups ex. Diseases"
		if "`grp'" == "Other" local cat "Other Disciplines"

		#delimit ;
		tw (line pub_count year if group == "`grp'" & nih == 1, lc(red))
		   (line pub_count year if group == "`grp'" & nih == 0 & year <= 2004, lc(green) lp(-))
		   (line pub_count year if group == "`grp'" & nih == 0 & year >= 2005, lc(green) lp(l)),
		 legend(order(1 "NIH Presence" 2 "No NIH Presence" 3 "No Public Presence") r(1))
		 yti("Publications About `cat'" "`units'" " ") xti("")
			  /*title("Publications About `cat'") subtitle("(`journals')")*/;
		graph save "gphs/discipline_counts`QA'_NIH_vs_Priv-`grp'_from1980.gph", replace;
		graph export "discipline_counts`QA'_NIH_vs_Priv-`grp'_from1980.png",
			replace as(png) wid(1200) hei(700);

		tw (line nih_sh year if nih == 1 & group == "`grp'" & year <= 2004, lc(red) lp(-))
		   (line nih_sh year if nih == 1 & group == "`grp'" & year >= 2005, lc(red) lp(l)),
			  legend(off) ylab(0(20)100)
			  yti("Share Receiving Funding from NIH (%)") xti("")
			  /*title("Publications About `cat'") subtitle("(`journals')")*/;
		graph save "gphs/discipline_sh`QA'_NIH_vs_Priv-`grp'_from1980.gph", replace;
		graph export "discipline_sh`QA'_NIH_vs_Priv-`grp'_from1980.png",
			replace as(png) wid(1200) hei(700);
		#delimit cr

	} // end discipline loop

	#delimit ;
	tw (line hhi year if nih == 1, lc(red))
	   (line hhi year if nih == 0 & year <= 2004, lc(green) lp(-))
	   (line hhi year if nih == 0 & year >= 2005, lc(green) lp(l)),
	 legend(order(1 "NIH Presence" 2 "No NIH Presence" 3 "No Public Presence") r(1))
	 yti("HHI") xti("");
	graph export "discipline_hhi`QA'_from1980.png",
		replace as(png) wid(1200) hei(700);
	#delimit cr

	foreach pub_ct in "" "CT_" {

		if "`pub_ct'" == "" local minyr = 1980
		if "`pub_ct'" == "CT_" local minyr = 1990
		
		import delimited "PubMed_Search_Results_`pub_ct'GBDlev2`QA'_from1980", clear varn(1)
			split query_name, p("_") gen(disease)
			gen nih = disease2 == "NIH"
			keep if inrange(year, `minyr', 2004)
			tempfile dis05
			save `dis05', replace

		import delimited "PubMed_Search_Results_`pub_ct'GBDlev2`QA'_from2005", clear varn(1)
			split query_name, p("_") gen(disease)
			gen nih = disease2 == "NIH"
				drop if disease2 == "Pub"
			pause
			append using `dis05'

		gen cause = "Cardiovascular Diseases" if disease1 == "Cardio"
			replace cause = "Chronic Respiratory Diseases" if disease1 == "ChronicResp"
			replace cause = "Diabetes and Kidney Diseases" if disease1 == "Kidney"
			replace cause = "Digestive Diseases" if disease1 == "Digestive"
			replace cause = "Enteric Infections" if disease1 == "Enteritis"
			replace cause = "HIV/AIDS and other STIs" if disease1 == "STIs"
			replace cause = "Maternal and Neonatal Disorders" if disease1 == "Pregnancy"
			replace cause = "Mental Disorders" if disease1 == "Mental"
			replace cause = "Musculoskeletal Disorders" if disease1 == "Muscle"
			replace cause = "Neglected Tropical Diseases and Malaria" if disease1 == "Tropic"
			replace cause = "Neoplasms" if disease1 == "Neoplasms"
			replace cause = "Neurological Disorders" if disease1 == "Neurologic"
			replace cause = "Alzheimer's & Related Dementias"  if disease1 == "Dementia"
			replace cause = "Nutritional Deficiencies" if disease1 == "Nutrition"
			replace cause = "Other Infectious Diseases" if disease1 == "OthInfectious"
			replace cause = "Respiratory Infections and Tuberculosis" if disease1 == "RespInf"
			replace cause = "Sense Organ Diseases" if disease1 == "Senses"
			replace cause = "Skin and Subcutaneous Diseases" if disease1 == "Skin"
			replace cause = "Substance Use Disorders" if disease1 == "Substance"

		levelsof cause, local(diseases)

		bys year cause: egen tot = total(pub_count)
		gen pub_sh = pub_count/tot*100

		if "`pub_ct'" == "" {
			local yvar_c "Non-Trial Publications"
			local yvar_sh "Non-Trial Publications"
		}
		if "`pub_ct'" == "CT_" {
			local yvar_c "Clinical Trial (II & III) Publications"
			local yvar_sh "Clinical Trial Publications"
		}

		foreach dis of local diseases {

			if "`dis'" == "Cardiovascular Diseases" local abbr "Cardio"
			if "`dis'" == "Chronic Respiratory Diseases" local abbr "ChronicResp"
			if "`dis'" == "Diabetes and Kidney Diseases" local abbr "Kidney"
			if "`dis'" == "Digestive Diseases" local abbr "Digestive"
			if "`dis'" == "Enteric Infections" local abbr "Enteritis"
			if "`dis'" == "HIV/AIDS and other STIs" local abbr "STIs"
			if "`dis'" == "Maternal and Neonatal Disorders" local abbr "Pregnancy"
			if "`dis'" == "Mental Disorders" local abbr "Mental"
			if "`dis'" == "Musculoskeletal Disorders" local abbr "Muscle"
			if "`dis'" == "Neglected Tropical Diseases and Malaria" local abbr "Tropic"
			if "`dis'" == "Neoplasms" local abbr "Neoplasms"
			if "`dis'" == "Neurological Disorders" local abbr "Neurologic"
			if "`dis'" == "Alzheimer's & Related Dementias" local abbr "Dementia"
			if "`dis'" == "Nutritional Deficiencies" local abbr "Nutrition"
			if "`dis'" == "Other Infectious Diseases" local abbr "OthInfectious"
			if "`dis'" == "Respiratory Infections and Tuberculosis" local abbr "RespInf"
			if "`dis'" == "Sense Organ Diseases" local abbr "Senses"
			if "`dis'" == "Skin and Subcutaneous Diseases" local abbr "Skin"
			if "`dis'" == "Substance Use Disorders" local abbr "Substance"

			#delimit ;
			tw (line pub_count year if nih == 1 & cause == "`dis'", lc(red))
			   (line pub_count year if nih == 0 & cause == "`dis'" & year <= 2004, lc(green) lp(-))
			   (line pub_count year if nih == 0 & cause == "`dis'" & year >= 2005, lc(green) lp(l)),
			  legend(order(1 "NIH Presence" 2 "No NIH Presence" 3 "No Public Presence") r(1))
			  yti("`yvar_c'" " ") ylab(, angle(45)) xti("")
			  title("`dis'") subtitle("(`journals')");
			graph save "gphs/disease_GBD_counts_`pub_ct'byfunding`QA'_from1980-`abbr'.gph", replace;
			graph export "disease_GBD_counts_`pub_ct'byfunding`QA'_from1980-`abbr'.png", replace as(png) wid(1200) hei(700);
			
			tw (line pub_sh year if nih == 1 & cause == "`dis'" & year <= 2004, lc(red) lp(-))
			   (line pub_sh year if nih == 1 & cause == "`dis'" & year >= 2005, lc(red) lp(l)),
			  legend(off) ylab(0(20)100)
			  yti("Share of `yvar_sh'" "Receiving Funding from NIH (%)" " ") ylab(, angle(45)) xti("")
			  title("`dis'") subtitle("(`journals')");
			graph save "gphs/disease_GBD_sh_`pub_ct'byfunding`QA'_from1980-`abbr'.gph", replace;
			graph export "disease_GBD_sh_`pub_ct'byfunding`QA'_from1980-`abbr'.png", replace as(png) wid(1200) hei(700);
			
			#delimit cr
		} // end of diseases loop

	} // end Pub/CT loop

	#delimit ;
	foreach dis in Cardio ChronicResp Digestive Enteritis Kidney Mental
					Muscle Neoplasms Neurologic Dementia Nutrition OthInfectious
					Pregnancy RespInf Senses Skin STIs Substance Tropic {;

		grc1leg "gphs/disease_GBD_counts_byfunding`QA'_from1980-`dis'.gph"
				"gphs/disease_GBD_sh_byfunding`QA'_from1980-`dis'.gph"
				"gphs/disease_GBD_counts_CT_byfunding`QA'_from1980-`dis'.gph"
				"gphs/disease_GBD_sh_CT_byfunding`QA'_from1980-`dis'.gph",
			legendfrom("gphs/disease_GBD_counts_byfunding`QA'_from1980-`dis'.gph")
			c(2) xcom;
		graph export "disease_GBD_byfunding`QA'_combined-`dis'.png",
			replace as(png) wid(1200) hei(700);

	};
	#delimit cr

	foreach grp in "Dis" "Mech" "Bio" "Chem" "Phys" "Mult" "Other" {
		if "`grp'" == "Dis" local cat "Diseases"
		if "`grp'" == "Mech" local cat "Disease Mechanisms Only"
		if "`grp'" == "Bio" local cat "Biological Phenomena Only"
		if "`grp'" == "Chem" local cat "Chemical Phenomena Only"
		if "`grp'" == "Phys" local cat "Physical Phenomena Only"
		if "`grp'" == "Mult" local cat "Multiple Groups ex. Diseases"
		if "`grp'" == "Other" local cat "Other Disciplines"

		#delimit ;
		grc1leg "gphs/discipline_counts`QA'_NIH_vs_Priv-`grp'_from1980.gph"	
				"gphs/discipline_sh`QA'_NIH_vs_Priv-`grp'_from1980.gph",
			legendfrom("gphs/discipline_counts`QA'_NIH_vs_Priv-`grp'_from1980.gph")
			title("Publications About `cat'") subtitle("(`journals')") r(1);
		graph export "discipline_byfunding`QA'_combined-`grp'.png", replace wid(2000) hei(700);
		#delimit cr
	}

} // end QA/not QA loop

*-------------------------
}
*-------------------------

*======================================================================================

*-----------------------------
if `drugs_and_devices' == 1 {
*-----------------------------
cap cd "C:\Users\lmostrom\Dropbox\Amitabh\"

foreach priv in /*"notNIH"*/ "Corporation" { // misnomer - mostly Univ's & Hospitals
	if "`priv'" == "Corporation" local _vsCorp "_vsCorp"
foreach QA in "" "_notQA" {

	if "`QA'" == "" local journals "Top 8 Journals"
	if "`QA'" == "_notQA" local journals "All Journals"

	if "`QA'" == "_notQA" & "`priv'" == "notNIH" {
		import delimited "PubMed_Search_Results_drugs_devices_notQA_from1980.csv", clear varn(1)

		split query_name, p("_")
		gen nih = query_name3 == "NIH"

		drop query_name query_name3
		ren query_name1 query_name
		ren query_name2 pub_type
	}
	if "`QA'" == "" & "`priv'" == "notNIH" {
		use "PubMed/Master_dta/pmids_drugs_devices.dta", clear
			merge m:1 pmid year using `qa_pmids', keep(3) nogen


		drop query_name
		split ddcat, p("_") gen(query_name)
		gen nih = substr(query_name3,1,3) == "NIH"

		drop ddcat query_name3
		ren query_name1 query_name
		ren query_name2 pub_type

		collapse (count) pub_count = pmid, by(query_name pub_type nih year)
	}
	if "`priv'" == "Corporation" {
			
		use "PubMed/Master_dta/pmids_drugs_devices.dta", clear
			if "`QA'" == "" {
			    merge m:1 pmid using "PubMed/Master_dta/pmids_QA_wos_funding.dta", keep(3) nogen
			}
			else merge m:1 pmid using "PubMed/Master_dta/pmids`QA'_wos_funding.dta", keep(3) nogen
		
			if "`QA'" == "" {
				merge m:1 pmid year using `qa_pmids', keep(3) nogen
				drop query_name
			}
		split ddcat, p("_") gen(query_name)
		*gen nih = substr(query_name3,1,3) == "NIH"
		keep if !no_funding_info
		gen priv = (compustat | corp) & !nih & !gov & !foundation
		keep if nih | priv
		drop priv gov foundation educ hosp no_funding_info

		drop ddcat query_name3
		ren query_name1 query_name
		ren query_name2 pub_type

		collapse (count) pub_count = pmid, by(query_name pub_type nih year)
	}


	collapse (sum) pub_count, by(query_name pub_type nih)

	forval nih01 = 0/1 {
		foreach pt in "CT" "Pub" {
			preserve
				keep if query_name == "tot" & pub_type == "`pt'" & nih == `nih01'
				local N_`pt'`nih01': dis pub_count
				dis "N `pt's, NIH = `nih01' : `N_`pt'`nih01''"
			restore
		}
	}

	drop if pub_type == "CT" & inlist(query_name, "therapy", "chem", "tot")
	drop if pub_type == "Pub" & inlist(query_name, "phys", "tot")

	bys pub_type nih: egen counted = sum(pub_count) if query_name != "tot"

		/* When including an "Other" category
		bys pub_type: ereplace counted = max(counted)

		replace pub_count = pub_count-counted if query_name == "tot"
		replace query_name = "other" if query_name == "tot"
		*/

	forval nih01 = 0/1 {
		foreach pt in "CT" "Pub" {
			preserve
				keep if pub_type == "`pt'" & nih == `nih01'
				local n_`pt'`nih01': dis counted
				dis "Shown `pt's, NIH = `nih01' : `n_`pt'`nih01''"
			restore
		}
	}

	gen qcode = 1 if query_name == "drugs"
		replace query_name = "Drugs (Not Devices)" if query_name == "drugs"
	replace qcode = 2 if query_name == "drugs-and-dev"
		replace query_name = "Drugs & Devices" if query_name == "drugs-and-dev"
	replace qcode = 3 if query_name == "devices"
		replace query_name = "Devices (Not Drugs)" if query_name == "devices"
	replace qcode = 4 if query_name == "surgery"
		replace query_name = "Surgery" if query_name == "surgery"
	replace qcode = 4 if query_name == "surg-and-hc"
		replace query_name = "Surgery" if query_name == "surg-and-hc"
	replace qcode = 5 if query_name == "healthcare"
		replace query_name = "Healthcare Delivery Only" if query_name == "healthcare"
	replace qcode = 6 if query_name == "therapy"
		replace query_name = "Non-Drug Therapies Only" if query_name == "therapy"
	replace qcode = 7 if query_name == "chem"
		replace query_name = "Non-Drug Chemicals Only" if query_name == "chem"
	replace qcode = 8 if query_name == "bio"
		replace query_name = "Biological Phenomena Only" if query_name == "bio"

cap mkdir "WOS_Funding_Plots"
cd "WOS_Funding_Plots"
		
	forval nih01 = 0/1 {

		if `nih01' == 1 local fund "Funded by NIH"
		if "`priv'" == "Corporation" & `nih01' == 0 local fund "Corporate-Funded"
		if "`priv'" == "notNIH" & `nih01' == 0 local fund "Not Funded by NIH"


		
		graph pie pub_count if pub_type == "CT" & nih == `nih01', ///
			over(query_name) sort(qcode) ///
			pl(1 percent, c(white) format(%9.3g) size(medsmall)) ///
			pl(3 percent, c(white) format(%9.3g) size(medsmall)) ///
			pl(4 percent, c(white) format(%9.3g) size(medsmall) gap(small)) ///
			pl(5 percent, c(white) format(%9.3g) size(medsmall) gap(medium)) ///
			title("Clinical Trials (II & III)" "`fund'") legend(colfirst) ///
			subtitle("`journals'" "Shown: `n_CT`nih01'' of `N_CT`nih01'' Trials") ///
			pie(1, c(cranberry)) pie(2, c(magenta)) pie(3, c(purple)) ///
			pie(4, c(dkgreen)) pie(5, c(dkorange)) ///
			note("Funding information from Web of Science")
		graph save "../PubMed/gphs/pies_drugs_devices`_vsCorp'`QA'_CTs_nih`nih01'.gph", replace
		graph export "pies_drugs_devices`_vsCorp'`QA'_CTs_nih`nih01'.png", replace as(png)

		graph pie pub_count if pub_type == "Pub" & nih == `nih01', ///
			over(query_name) sort(qcode) ///
			pl(1 percent, c(white) format(%9.3g) size(medsmall) gap(medium)) ///
			pl(3 percent, c(white) format(%9.3g) size(medsmall) gap(small)) ///
			pl(4 percent, c(white) format(%9.3g) size(medsmall)) ///
			pl(5 percent, c(white) format(%9.3g) size(medsmall)) ///
			pl(6 percent, c(white) format(%9.3g) size(medsmall)) ///
			pl(7 percent, c(white) format(%9.3g) size(medsmall)) ///
			pl(8 percent, c(white) format(%9.3g) size(medsmall)) ///
			title("Non-Trial Journal Articles" "`fund'") legend(colfirst) ///
			subtitle("`journals'" "Shown: `n_Pub`nih01'' of `N_Pub`nih01'' Papers") ///
			pie(1, c(cranberry)) pie(2, c(magenta)) pie(3, c(purple)) ///
			pie(4, c(dkgreen)) pie(5, c(dkorange)) ///
			pie(6, c(sienna)) pie(7, c(midblue)) pie(8, c(midgreen)) ///
			note("Funding information from Web of Science")
		graph save "../PubMed/gphs/pies_drugs_devices`_vsCorp'`QA'_Pubs_nih`nih01'.gph", replace
		graph export "pies_drugs_devices`_vsCorp'`QA'_Pubs_nih`nih01'.png", replace as(png)
	}

		grc1leg "../PubMed/gphs/pies_drugs_devices`_vsCorp'`QA'_CTs_nih1.gph" ///
				"../PubMed/gphs/pies_drugs_devices`_vsCorp'`QA'_CTs_nih0.gph", r(1)
		graph export "pies_drugs_devices`_vsCorp'`QA'_CTs_combined.png", replace as(png)

		grc1leg "../PubMed/gphs/pies_drugs_devices`_vsCorp'`QA'_Pubs_nih1.gph" ///
				"../PubMed/gphs/pies_drugs_devices`_vsCorp'`QA'_Pubs_nih0.gph", r(1)
		graph export "pies_drugs_devices`_vsCorp'`QA'_Pubs_combined.png", replace as(png)


	forval nih01 = 0/1 {
		local N`nih01' = `N_CT`nih01'' + `N_Pub`nih01''
		local n`nih01' = `n_CT`nih01'' + `n_Pub`nih01''
	}

	collapse (sum) pub_count, by(query_name qcode nih)
	preserve
		collapse (sum) pub_count
		assert pub_count == `n0' + `n1'
	restore

	forval nih01 = 0/1 {

		if `nih01' == 1 local fund "Funded by NIH"
		if "`priv'" == "Corporation" & `nih01' == 0 local fund "Corporate-Funded"
		if "`priv'" == "notNIH" & `nih01' == 0 local fund "Not Funded by NIH"

		graph pie pub_count if nih == `nih01', over(query_name) sort(qcode) ///
			pl(1 percent, c(white) format(%9.3g) size (medsmall) gap(medium)) ///
			pl(3 percent, c(white) format(%9.3g) size (medsmall) gap(small)) ///
			pl(4 percent, c(white) format(%9.3g) size (medsmall)) ///
			pl(5 percent, c(white) format(%9.3g) size (medsmall)) ///
			pl(6 percent, c(white) format(%9.3g) size (medsmall)) ///
			pl(7 percent, c(white) format(%9.3g) size (medsmall)) ///
			pl(8 percent, c(white) format(%9.3g) size (medsmall)) ///
			title("Journal Articles and Clinical Trials (II & III)" "`fund'") legend(colfirst) ///
			subtitle("`journals'" "Shown: `n`nih01'' of `N`nih01'' Publications") ///
			pie(1, c(cranberry)) pie(2, c(magenta)) pie(3, c(purple)) ///
			pie(4, c(dkgreen)) pie(5, c(dkorange)) ///
			pie(6, c(sienna)) pie(7, c(midblue)) pie(8, c(midgreen)) ///
			note("Funding information from Web of Science")
		graph save "../PubMed/gphs/pies_drugs_devices`_vsCorp'`QA'_All_nih`nih01'.gph", replace
		graph export "pies_drugs_devices`_vsCorp'`QA'_All_nih`nih01'.png", replace as(png)
	}

		grc1leg "../PubMed/gphs/pies_drugs_devices`_vsCorp'`QA'_All_nih1.gph" ///
				"../PubMed/gphs/pies_drugs_devices`_vsCorp'`QA'_All_nih0.gph", r(1)
		graph export "pies_drugs_devices`_vsCorp'`QA'_All_combined.png", replace as(png)
cd ../
	*--------- Not Separated NIH/Not NIH -----------------*
	if "`QA'" == "_notQA" & "`priv'" == "notNIH" {
		import delimited "PubMed_Search_Results_drugs_devices_notQA_from1980.csv", clear varn(1)

		split query_name, p("_")
		gen nih = query_name3 == "NIH"

		drop query_name query_name3
		ren query_name1 query_name
		ren query_name2 pub_type
	}
	if "`QA'" == "" & "`priv'" == "notNIH" {
		use "PubMed/Master_dta/pmids_drugs_devices.dta", clear
			if "`QA'" == "" {
			    merge m:1 pmid using "PubMed/Master_dta/pmids_QA_wos_funding.dta", keep(3) nogen
			}
			else merge m:1 pmid using "PubMed/Master_dta/pmids`QA'_wos_funding.dta", keep(3) nogen


		drop query_name
		split ddcat, p("_") gen(query_name)
		gen nih = substr(query_name3,1,3) == "NIH"

		drop ddcat query_name3
		ren query_name1 query_name
		ren query_name2 pub_type

		collapse (count) pub_count = pmid, by(query_name pub_type nih year)
	}
	if "`priv'" == "Corporation" {
		use "PubMed/Master_dta/pmids_drugs_devices.dta", clear
			if "`QA'" == "" {
			    merge m:1 pmid using "PubMed/Master_dta/pmids_QA_wos_funding.dta", keep(3) nogen
			}
			else merge m:1 pmid using "PubMed/Master_dta/pmids`QA'_wos_funding.dta", keep(3) nogen
			
			if "`QA'" == "" {
				merge m:1 pmid year using `qa_pmids', keep(3) nogen
				drop query_name
			}
		split ddcat, p("_") gen(query_name)
		*gen nih = substr(query_name3,1,3) == "NIH"
		keep if !no_funding_info
		gen priv = (compustat | corp) & !nih & !gov & !foundation
		keep if nih | priv
		drop priv gov educ hosp foundation no_funding_info

		drop ddcat query_name3
		ren query_name1 query_name
		ren query_name2 pub_type

		collapse (count) pub_count = pmid, by(query_name pub_type nih year)
	}

	collapse (sum) pub_count, by(query_name pub_type)

	foreach pt in "CT" "Pub" {
		preserve
			keep if query_name == "tot" & pub_type == "`pt'"
			local N_`pt': dis pub_count
			dis "N `pt's: `N_`pt''"
		restore
	}

	drop if pub_type == "CT" & inlist(query_name, "therapy", "chem", "tot")
	drop if pub_type == "Pub" & inlist(query_name, "phys", "tot")

	bys pub_type: egen counted = sum(pub_count) if query_name != "tot"

		/* When including an "Other" category
		bys pub_type: ereplace counted = max(counted)

		replace pub_count = pub_count-counted if query_name == "tot"
		replace query_name = "other" if query_name == "tot"
		*/

	foreach pt in "CT" "Pub" {
		preserve
			keep if pub_type == "`pt'"
			local n_`pt': dis counted
			dis "Shown `pt's: `n_`pt''"
		restore
	}

	gen qcode = 1 if query_name == "drugs"
		replace query_name = "Drugs (Not Devices)" if query_name == "drugs"
	replace qcode = 2 if query_name == "drugs-and-dev"
		replace query_name = "Drugs & Devices" if query_name == "drugs-and-dev"
	replace qcode = 3 if query_name == "devices"
		replace query_name = "Devices (Not Drugs)" if query_name == "devices"
	replace qcode = 4 if query_name == "surgery"
		replace query_name = "Surgery" if query_name == "surgery"
	replace qcode = 4 if query_name == "surg-and-hc"
		replace query_name = "Surgery" if query_name == "surg-and-hc"
	replace qcode = 5 if query_name == "healthcare"
		replace query_name = "Healthcare Delivery Only" if query_name == "healthcare"
	replace qcode = 6 if query_name == "therapy"
		replace query_name = "Non-Drug Therapies Only" if query_name == "therapy"
	replace qcode = 7 if query_name == "chem"
		replace query_name = "Non-Drug Chemicals Only" if query_name == "chem"
	replace qcode = 8 if query_name == "bio"
		replace query_name = "Biological Phenomena Only" if query_name == "bio"

cd "WOS_Funding_Plots"
		
	graph pie pub_count if pub_type == "CT", ///
		over(query_name) sort(qcode) ///
		pl(1 percent, c(white) format(%9.3g)) ///
		pl(3 percent, c(white) format(%9.3g)) ///
		pl(4 percent, c(white) format(%9.3g)) ///
		pl(5 percent, c(white) format(%9.3g)) ///
		title("Clinical Trials (II & III)") legend(colfirst) ///
		subtitle("`journals'" "Shown: `n_CT' of `N_CT' Trials") ///
		pie(1, c(cranberry)) pie(2, c(magenta)) pie(3, c(purple)) ///
		pie(4, c(dkgreen)) pie(5, c(dkorange))
	graph export "pies_drugs_devices`_vsCorp'`QA'_CTs.png", replace as(png)

	graph pie pub_count if pub_type == "Pub", ///
		over(query_name) sort(qcode) ///
		pl(1 percent, c(white) format(%9.3g)) ///
		pl(3 percent, c(white) format(%9.3g)) ///
		pl(4 percent, c(white) format(%9.3g)) ///
		pl(5 percent, c(white) format(%9.3g)) ///
		pl(6 percent, c(white) format(%9.3g)) ///
		pl(7 percent, c(white) format(%9.3g)) ///
		pl(8 percent, c(white) format(%9.3g)) ///
		title("Non-Trial Journal Articles") legend(colfirst) ///
		subtitle("`journals'" "Shown: `n_Pub' of `N_Pub' Papers") ///
		pie(1, c(cranberry)) pie(2, c(magenta)) pie(3, c(purple)) ///
		pie(4, c(dkgreen)) pie(5, c(dkorange)) ///
		pie(6, c(sienna)) pie(7, c(midblue)) pie(8, c(midgreen))
	graph export "pies_drugs_devices`_vsCorp'`QA'_Pubs.png", replace as(png)

	local N`nih01' = `N_CT' + `N_Pub'
	local n`nih01' = `n_CT' + `n_Pub'

	collapse (sum) pub_count, by(query_name qcode)
	preserve
		collapse (sum) pub_count
		assert pub_count == `n0' + `n1'
	restore

	graph pie pub_count, over(query_name) sort(qcode) ///
		pl(1 percent, c(white) format(%9.3g)) ///
		pl(3 percent, c(white) format(%9.3g)) ///
		pl(4 percent, c(white) format(%9.3g)) ///
		pl(5 percent, c(white) format(%9.3g)) ///
		pl(6 percent, c(white) format(%9.3g)) ///
		pl(7 percent, c(white) format(%9.3g)) ///
		pl(8 percent, c(white) format(%9.3g)) ///
		title("Journal Articles and Clinical Trials (II & III)") legend(colfirst) ///
		subtitle("`journals'" "Shown: `n' of `N' Publications") ///
		pie(1, c(cranberry)) pie(2, c(magenta)) pie(3, c(purple)) ///
		pie(4, c(dkgreen)) pie(5, c(dkorange)) ///
		pie(6, c(sienna)) pie(7, c(midblue)) pie(8, c(midgreen))
	graph export "pies_drugs_devices`_vsCorp'`QA'_All.png", replace as(png)
cd ../
} // end QA loop
} // end Not NIH/Corporation loop

*-----------------------------
} // end `drugs_and_devices'
*-----------------------------

*-----------------------------
if `ba_tr_cl' == 1 {
*-----------------------------
cap cd "C:\Users\lmostrom\Dropbox\Amitabh\"

foreach priv in /*"notNIH"*/ "Corporation" {
	if "`priv'" == "Corporation" local _vsCorp "_vsCorp"
foreach _wCTs in /*""*/ "_wCTs" {
foreach QA in "" "_notQA" {
	
	if "`QA'" == "" local journals = "Top 8 Journals"
	if "`QA'" == "_notQA" local journals = "All Journals"

	if "`priv'" == "notNIH" {
		import delimited "PubMed_Search_Results_ba-tr-cl`QA'_from1980.csv", clear varn(1)

		split query_name, p("_")
		drop query_name
		ren query_name1 query_name
			replace query_name = "clinical" ///
				if inlist(query_name, "clinical1", "clinical2") // not needed anymore
		ren query_name2 fund
			gen nih = fund == "NIH"
			drop fund
		if "`_wCTs'" == "_wCTs" {
			replace query_name = "total" if query_name == "totalCTs"
			collapse (sum) pub_count, by(query_name nih year) fast
			replace query_name = "CT" if query_name == "trial"
		}
		if "`_wCTs'" == "" {
			drop if inlist(query_name, "trial", "totalCTs")
		}
	gen decade = int(year/10)*10
	collapse (sum) pub_count, by(query_name nih decade)
	}
	if "`priv'" == "Corporation" {
		use "PubMed/Master_dta/pmids_bas_trans_clin`QA'.dta", clear
		ren nih pm_nih
			if "`QA'" == "" {
			    merge m:1 pmid using "PubMed/Master_dta/pmids_QA_wos_funding.dta", keep(3) nogen
			}
			else merge m:1 pmid using "PubMed/Master_dta/pmids`QA'_wos_funding.dta", keep(3) nogen
		
			replace nih = 1 if nih == 0 & pm_nih == 1
				replace no_funding_info = 0 if pm_nih == 1
			replace gov = 0 if gov == 1 & nih == 1
			replace foundation = 0 if foundation == 1 & (nih | gov)
			gen priv = (compustat | corp) & !nih & !gov & !foundation & !no_funding_info
			replace educ = 0 if educ == 1 & (nih | gov | foundation | priv)
			replace hosp = 0 if hosp == 1 & (nih | gov | foundation | priv | educ)
			egen check = rowtotal(nih gov foundation priv educ hosp no_funding_info)
				assert check <= 1
		
	ren btc query_name
	

		if "`_wCTs'" == "_wCTs" {
			replace query_name = "total" if query_name == "totalCTs"
			replace query_name = "CT" if query_name == "trial"
			
			cd "WOS_Funding_Plots"
			
		foreach from2008 in "" "_from2008" {
			preserve
				drop if query_name == "total"
				if "`from2008'" == "_from2008" {
					drop if year < 2008 // better funding data 
					local subt "Since 2008"
				}
				else local subt ""
				collapse (sum) pub_countNIH = nih pub_countGov = gov ///
								pub_countFoundation = foundation pub_countCorp = priv ///
								pub_countEduc = educ pub_countHosp = hosp ///
								pub_countNoInfo = no_funding_info ///
						 (count) pub_count = pmid, by(query_name)
				gen sort_order = 1 if query_name == "basic"
					replace sort_order = 2 if query_name == "translational"
					replace sort_order = 3 if query_name == "clinical"
					replace sort_order = 4 if query_name == "CT"
				replace query_name = "trial" if query_name == "CT"
					replace query_name = proper(query_name)
				gen pub_countO = pub_count - pub_countNIH - pub_countGov ///
						- pub_countF - pub_countC - pub_countE - pub_countH - pub_countNo
				foreach var of varlist pub_count* {
				    replace `var' = `var'/1000
				}
				#delimit ;
				graph bar (asis) pub_countNIH pub_countG pub_countF
									pub_countC pub_countE pub_countH
									pub_countO pub_countNo,
					over(query_name, sort(sort_order)) stack
					legend(order(1 "NIH" 2 "Other Gov. Agency" 3 "Foundation"
								 4 "Corporation" 5 "Educational Institution"
								 6 "Hospital" 7 "Other Entity" 8 "No Funding Information")
							r(3) symx(small) symy(small))
					title("Publications by Research Stage and Funder")
					subtitle("(`journals')" "`subt'")
					yti("Number of Publications" "(in Thousands)")
					bar(1, col(blue)) bar(2, col(midgreen)) bar(3, col(purple))
					bar(4, col(red)) bar(5, col(dkorange)) bar(6, col(emerald))
					bar(7, col(sand)) bar(8, col(gs7));
				graph export "bars_ba-tr-cl_byfunder`QA'`from2008'.png", replace as(png);
				
				graph bar (asis) pub_countNIH pub_countG pub_countF
									pub_countC pub_countE pub_countH
									/*pub_countO pub_countNo*/,
					over(query_name, sort(sort_order)) stack
					legend(order(1 "NIH" 2 "Other Gov. Agency" 3 "Foundation"
								 4 "Corporation" 5 "Educational Institution"
								 6 "Hospital" /*7 "Other Entity" 8 "No Funding Information"*/)
							r(3) symx(small) symy(small))
					title("Publications by Research Stage and Funder")
					subtitle("(`journals')" "`subt'")
					yti("Number of Publications" "(in Thousands)")
					bar(1, col(blue)) bar(2, col(midgreen)) bar(3, col(purple))
					bar(4, col(red)) bar(5, col(dkorange)) bar(6, col(emerald))
					bar(7, col(sand)) bar(8, col(gs7))
					note("Includes only publications with available funding information");
				graph export "bars_ba-tr-cl_byfunder`QA'_wInfoOnly`from2008'.png", replace as(png);
				#delimit cr
			restore
		} // from 2008
		
		cd ../
		} // if including CTs
		if "`_wCTs'" == "" {
			drop if inlist(query_name, "trial", "totalCTs")
		}
		
		keep if !no_funding_info
		keep if nih | priv
		drop priv gov foundation educ hosp no_funding_info

	gen decade = int(year/10)*10
	collapse (count) pub_count = pmid, by(query_name nih decade)
	}

	*--------- BY DECADE AND FUNDING ---------*

	forval dec = 1980(10)2010 {
		preserve
			keep if query_name == "total" & decade == `dec'
			collapse (sum) pub_count
			local N_`dec': dis pub_count
			dis "N `dec's: `N_`dec''"
		restore
	}
	local N = `N_1980' + `N_1990' + `N_2000' + `N_2010'
	
	bys decade: egen counted = sum(pub_count) if query_name != "total"

	forval dec = 1980(10)2010 {
		preserve
			keep if decade == `dec' & query_name != "total"
			local n_`dec': dis counted
			dis "Shown `dec's: `n_`dec''"
		restore
	}
	local n = `n_1980' + `n_1990' + `n_2000' + `n_2010'

	drop if query_name == "total"
	keep decade nih pub_count query_name

	
		replace pub_count = pub_count/1000
		local units "Thousands"


	lab var pub_count "Publications (in `units')"

	if "`_wCTs'" == "_wCTs" {
		local CTbar "pub_countCT"
		local bar4col "bar(4, col(dkorange))"
		local legend4 4 "Clinical Trials (II & III)"
		local leg_rows "r(2)"
		local title "Journal Articles"
	}
	else {
		local CTbar ""
		local bar4col ""
		local legend4 ""
		local leg_rows "r(1)"
		local title "Non-Trial Journal Articles"
	}
	
	reshape wide pub_count, i(decade nih) j(query_name) string
	tostring decade, replace
	replace decade = decade + "s"

	gen fundname = "NIH" if nih
	replace fundname = "Private" if !nih

cd "WOS_Funding_Plots"

		#delimit ;
		graph bar (asis) pub_countb pub_countt pub_countc `CTbar',
			over(fundname) over(decade) stack
			legend(order(1 "Basic Science" 2 "Translational Science"
						 3 "Clinical Science" `legend4')
					`leg_rows' symx(small) symy(small))
			title("`title'")
			subtitle("(`journals')" "Shown: `n' of `N' Publications")
			yti("Number of Publications" "(in `units')")
			bar(1, col(midgreen)) bar(2, col(blue)) bar(3, col(cranberry))
			`bar4col';
		graph save "../PubMed/gphs/bars_ba-tr-cl`_wCTs'_bydecade`_vsCorp'`QA'_nih`nih01'.gph", replace;
		graph export "bars_ba-tr-cl`_wCTs'_bydecade`_vsCorp'`QA'_nih`nih01'.png", replace as(png);
		#delimit cr

	grc1leg "../PubMed/gphs/bars_ba-tr-cl`_wCTs'_bydecade`_vsCorp'`QA'_nih1.gph" ///
			"../PubMed/gphs/bars_ba-tr-cl`_wCTs'_bydecade`_vsCorp'`QA'_nih0.gph", r(2)
	graph export "bars_ba-tr-cl`_wCTs'_bydecade`_vsCorp'`QA'_combined.png", replace as(png)
cd ../
	*--------- BY FUNDING ---------*
	if "`priv'" == "notNIH" {
		import delimited "PubMed_Search_Results_ba-tr-cl`QA'_from1980.csv", clear varn(1)

		split query_name, p("_")
		drop query_name
		ren query_name1 query_name
		ren query_name2 fund
			gen nih = fund == "NIH"
			drop fund
		if "`_wCTs'" == "_wCTs" {
			replace query_name = "total" if query_name == "totalCTs"
			replace query_name = "CT" if query_name == "trial"
		}
		if "`_wCTs'" == "" {
			drop if inlist(query_name, "trial", "totalCTs")
		}
	collapse (sum) pub_count, by(query_name nih)
	}
	
	if "`priv'" == "Corporation" {
		use "PubMed/Master_dta/pmids_bas_trans_clin`QA'.dta", clear
			if "`QA'" == "" {
			    merge m:1 pmid using "PubMed/Master_dta/pmids_QA_wos_funding.dta", keep(3) nogen
			}
			else merge m:1 pmid using "PubMed/Master_dta/pmids`QA'_wos_funding.dta", keep(3) nogen
	
		ren btc query_name

		if "`_wCTs'" == "_wCTs" {
			replace query_name = "total" if query_name == "totalCTs"
			replace query_name = "CT" if query_name == "trial"
		}
		if "`_wCTs'" == "" {
			drop if inlist(query_name, "trial", "totalCTs")
		}
		
		keep if !no_funding_info
		gen priv = (compustat | corp) & !nih & !gov & !foundation
		keep if nih | priv
		drop priv gov foundation educ hosp no_funding_info
		
	collapse (count) pub_count=pmid, by(query_name nih)
	}


	forval f = 0/1 {
		preserve
			keep if query_name == "total" & nih == `f'
			local N_`f': dis pub_count
			dis "N `f's: `N_`f''"
		restore
	}

	bys nih: egen counted = sum(pub_count) if query_name != "total"

	/* When including an "Other" category
	bys nih: ereplace counted = max(counted)

	replace pub_count = pub_count-counted if query_name == "total"
	replace query_name = "other" if query_name == "total"
	*/

	forval f = 0/1 {
		preserve
			keep if nih == `f' & query_name != "total"
			local n_`f': dis counted
			dis "Shown `f's: `n_`f''"
		restore
	}

	drop if query_name == "total"

	gen qcode = 1 if query_name == "basic"
		replace query_name = "Basic Science" if query_name == "basic"
	replace qcode = 2 if query_name == "translational"
		replace query_name = "Translational Science" if query_name == "translational"
	replace qcode = 3 if query_name == "clinical"
		replace query_name = "Clinical Science" if query_name == "clinical"
	replace qcode = 4 if query_name == "CT"
		replace query_name = "Clinical Trials (II & III)" if query_name == "CT"

	if "`_wCTs'" == "_wCTs" {
		local pl4 "pl(4 percent, c(white) format(%9.3g) size(medium)) "
		local pie4 "pie(4, c(dkorange))"
		local subtitle "Journal Articles & Clinical Trials (II & III)"
		local legend "legend(r(2) symx(small) symy(small))"
	}
	else {
		local pl4 ""
		local pie4 ""
		local subtitle "Non-Trial Journal Articles"
		local legend "legend(r(1) symx(small) symy(small))"
	}
	
cd "WOS_Funding_Plots"

	graph pie pub_count if nih == 0, over(query_name) sort(qcode) ///
		pl(1 percent, c(white) format(%9.3g) size(medium)) ///
		pl(2 percent, c(white) format(%9.3g) size(medium)) ///
		pl(3 percent, c(white) format(%9.3g) size(medium)) `pl4' ///
		title("Corporate-Funded Publications") `legend' ///
		subtitle("`subtitle'" "(`journals')" ///
					"Shown: `n_0' of `N_0' Publications") ///
		pie(1, c(midgreen)) pie(2, c(blue)) pie(3, c(cranberry)) `pie4'
	graph save "../PubMed/gphs/pies_ba-tr-cl`_wCTs'`_vsCorp'`QA'_nih0.gph", replace
	graph export "pies_ba-tr-cl`_wCTs'`_vsCorp'`QA'_nih0.png", replace as(png)

	graph pie pub_count if nih == 1, over(query_name) sort(qcode) ///
		pl(1 percent, c(white) format(%9.3g) size(medium)) ///
		pl(2 percent, c(white) format(%9.3g) size(medium)) ///
		pl(3 percent, c(white) format(%9.3g) size(medium)) `pl4' ///
		title("NIH-Funded Publications") `legend' ///
		subtitle("`subtitle'" "(`journals')" ///
					"Shown: `n_1' of `N_1' Publications") ///
		pie(1, c(midgreen)) pie(2, c(blue)) pie(3, c(cranberry)) `pie4'
	graph save "../PubMed/gphs/pies_ba-tr-cl`_wCTs'`_vsCorp'`QA'_nih1.gph", replace
	graph export "pies_ba-tr-cl`_wCTs'`_vsCorp'`QA'_nih1.png", replace as(png)

		grc1leg "../PubMed/gphs/pies_ba-tr-cl`_wCTs'`_vsCorp'`QA'_nih0.gph" ///
				"../PubMed/gphs/pies_ba-tr-cl`_wCTs'`_vsCorp'`QA'_nih1.gph", r(1)
		graph export "pies_ba-tr-cl`_wCTs'`_vsCorp'`QA'_combined.png", replace as(png)

	local N = `N_0' + `N_1'
	local n = `n_0' + `n_1'
	collapse (sum) pub_count, by(query_name qcode)

	preserve
		collapse (sum) pub_count
		assert pub_count == `n'
	restore

	if "`_wCTs'" == "_wCTs" local pl4 "pl(4 percent, c(white) format(%9.3g)) "
	else local pl4 ""

	graph pie pub_count , over(query_name) sort(qcode) ///
		pl(1 percent, c(white) format(%9.3g)) ///
		pl(2 percent, c(white) format(%9.3g)) ///
		pl(3 percent, c(white) format(%9.3g)) `pl4' ///
		title("Total Publications") `legend' ///
		subtitle("`subtitle'" "(`journals')" ///
					"Shown: `n' of `N' Publications") ///
		pie(1, c(midgreen)) pie(2, c(blue)) pie(3, c(cranberry)) `pie4'
	graph save "../PubMed/gphs/pies_ba-tr-cl`_wCTs'`_vsCorp'`QA'_all.gph", replace
	graph export "pies_ba-tr-cl`_wCTs'`_vsCorp'`QA'_all.png", replace as(png)
	
cd ../
} // end QA loop
} // end w/ CTs loop
} // end loop comparing NIH to privately funded research
*-----------------------------
} // end `ba_tr_cl'
*-----------------------------

*-----------------------------
if `ba_tr_cl_bydisease' == 1 {
*-----------------------------
cap cd "C:\Users\lmostrom\Dropbox\Amitabh\"

*local filelist: dir "PubMed/PMIDs/PieCharts/" files "PMIDs_BTC_*.csv"

foreach priv in /*"notNIH"*/ "Corporation" { // misnomer - mostly Univ's & Hospitals
	if "`priv'" == "Corporation" local _vsCorp "_vsCorp"
foreach QA in "" "_notQA" {

	if "`QA'" == "" {
		local yes_no "!="
		local journals "Top 7 Journals"
	}
	if "`QA'" == "_notQA" {
		local yes_no "=="
		local journals "All Journals"
	}
	
	local i = 1
	foreach file of local filelist {
	if substr("`file'", 11, 5) `yes_no' "notqa" {
		import delimited pmid query_name using "PubMed/PMIDs/PieCharts/`file'", rowr(2:) clear
		dis "`file'"
		if _N > 0 {
			tostring pmid, replace
			drop if pmid == "NA"
			destring pmid, replace

			if `i' == 1 {
				tempfile full_pmids
				save `full_pmids', replace 
			}
			if `i' > 1 {
				append using `full_pmids'
				save `full_pmids', replace
			}
			local ++i
		}
	}
	}

	use `full_pmids', clear

	gen year = substr(query_name, -4, 4)
		destring year, replace
	split query_name, p("_")
	gen nih = substr(query_name2, 1, 3) == "NIH"
	drop query_name query_name2
		ren query_name1 btc

	save "PubMed/Master_dta/pmids_bas_trans_clin`QA'.dta", replace
/*
foreach _wCTs in /*""*/ "_wCTs" {
	use "PubMed/Master_dta/pmids_bas_trans_clin`QA'.dta", clear
			if "`QA'" == "" {
			    merge m:1 pmid using "PubMed/Master_dta/pmids_QA_wos_funding.dta", keep(3) nogen
			}
			else merge m:1 pmid using "PubMed/Master_dta/pmids`QA'_wos_funding.dta", keep(3) nogen

	if "`_wCTs'" == "_wCTs" {
		replace btc = "total" if btc == "totalCTs"
		replace btc = "CT" if btc == "trial"
	}
	if "`_wCTs'" == "" drop if inlist(btc, "trial", "totalCTs")

	preserve
		use "PubMed/Master_dta/pmids`QA'_bydisease.dta", clear
		append using "PubMed/Master_dta/pmids_clintr`QA'_bydisease.dta"
		tempfile dis_pmids
		save `dis_pmids', replace
	restore

	joinby pmid year using `dis_pmids'
		drop query_name

	drop if btc == "basic" // very few, should be 0

		keep if !no_funding_info
		gen priv = (compustat | corp) & !nih & !gov & !foundation
		keep if nih | priv
		drop priv gov foundation educ hosp no_funding_info
		
	duplicates drop pmid dis_abbr btc, force
	collapse (count) pub_count = pmid, by(dis_abbr btc nih)
	if "`QA'" == "" {
		replace pub_count = pub_count/1000
		lab var pub_count "Publications (in Thousands)"
		local units "Thousands"
	}
	if "`QA'" == "_notQA" {
		replace pub_count = pub_count/1000000
		lab var pub_count "Publications (in Millions)"
		local units "Millions"
	}

	bys dis_abbr nih: egen counted = total(pub_count) if btc != "total"
		bys dis_abbr nih: ereplace counted = max(counted)
		replace pub_count = pub_count - counted if btc == "total"
		replace btc = "other" if btc == "total"

	drop if dis_abbr == "Dementia"

	levelsof dis_abbr, local(diseases) clean
	gen disease = ""
	foreach abbr of local diseases {
		if "`abbr'" == "Cardio" replace disease = "Cardiovascular" ///
									if dis_abbr == "`abbr'"
		if "`abbr'" == "ChronicResp" replace disease = "Chronic Respiratory" ///
									if dis_abbr == "`abbr'"
		if "`abbr'" == "Kidney" replace disease = "Diabetes & Kidney" ///
									if dis_abbr == "`abbr'"
		if "`abbr'" == "Digestive" replace disease = "Digestive" ///
									if dis_abbr == "`abbr'"
		if "`abbr'" == "Enteritis" replace disease = "Enteric" ///
									if dis_abbr == "`abbr'"
		if "`abbr'" == "STIs" replace disease = "HIV/AIDS & Other STIs" ///
									if dis_abbr == "`abbr'"
		if "`abbr'" == "Pregnancy" replace disease = "Maternal/Neonatal" ///
									if dis_abbr == "`abbr'"
		if "`abbr'" == "Mental" replace disease = "Mental Health" ///
									if dis_abbr == "`abbr'"
		if "`abbr'" == "Muscle" replace disease = "Musculoskeletal" ///
									if dis_abbr == "`abbr'"
		if "`abbr'" == "Tropic" replace disease = "Tropical" ///
									if dis_abbr == "`abbr'"
		if "`abbr'" == "Neoplasms" replace disease = "Neoplasms" ///
									if dis_abbr == "`abbr'"
		if "`abbr'" == "Neurologic" replace disease = "Neurological" ///
									if dis_abbr == "`abbr'"
		if "`abbr'" == "Nutrition" replace disease = "Nutritional" ///
									if dis_abbr == "`abbr'"
		if "`abbr'" == "OthInfectious" replace disease = "Other Infectious Diseases" ///
									if dis_abbr == "`abbr'"
		if "`abbr'" == "RespInf" replace disease = "Respiratory Infections" ///
									if dis_abbr == "`abbr'"
		if "`abbr'" == "Senses" replace disease = "Sense Organ" ///
									if dis_abbr == "`abbr'"
		if "`abbr'" == "Skin" replace disease = "Skin & Subcutaneous" ///
									if dis_abbr == "`abbr'"
		if "`abbr'" == "Substance" replace disease = "Substance Use" ///
									if dis_abbr == "`abbr'"
	}
	reshape wide pub_count, i(disease dis_abbr nih) j(btc) string

	*--- Check ----
		gen ref = pub_countt + pub_countc
		assert round(counted,3) == round(ref,3)
		drop ref
	*--------------

	gen total = counted + pub_counto

	forval nih01 = 0/1 {

		if `nih01' == 1 local fund "Funded by NIH"
		if `nih01' == 0 & "`priv'" == "Corporation" local fund "Corporate-Funded"
		if `nih01' == 0 & "`priv'" == "notNIH" local fund "Not Funded by NIH"
		
cd "WOS_Funding_Plots"

		#delimit ;
		graph bar (asis) pub_countt pub_countc pub_counto if  nih == `nih01', stack
						over(disease, sort(total) descending
								lab(angle(60) labsize(small)))
					legend(order(1 "Translational Science" 2 "Clinical Science"
								 3 "Other") r(1) symx(small) symy(small) pos(12))
					title("Non-Trial Journal Articles About Diseases")
					subtitle("(`journals')")
					yti("Number of Publications" "(in `units')") aspect(0.32)
					bar(1, col(blue)) bar(2, col(cranberry)) bar(3, col(gs7));
		graph save "../PubMed/gphs/bars_ba-tr-cl_bydisease`_wCTs'`_vsCorp'`QA'_nih`nih01'.gphs", replace;
		graph export "bars_ba-tr-cl_bydisease`_wCTs'`_vsCorp'`QA'_nih`nih01'.png", replace as(png);
		#delimit cr
cd ../
	}

	grc1leg "PubMed/gphs/bars_ba-tr-cl_bydisease`_wCTs'`_vsCorp'`QA'_nih1.gphs" ///
			"PubMed/gphs/bars_ba-tr-cl_bydisease`_wCTs'`_vsCorp'`QA'_nih0.gphs", c(1) xcommon
	graph export "WOS_Funding_Plots/bars_ba-tr-cl_bydisease`_wCTs'`_vsCorp'`QA'_combined.png", replace as(png)

	gen fundname = "NIH" if nih
	replace fundname = "Private" if !nih

	if "`_wCTs'" == "_wCTs" {
		local title "Journal Articles & Clinical Trials (II & III)"
		local legend_ops "r(2) symx(small) symy(small)"
		local yvarCT "pub_countCT"
		local orderCT 3 "Clinical Trials (II & III)" 4 "Other"
		local barsCT "bar(3, col(dkorange)) bar(4, col(gs7))"
	}
	else {
		local title "Non-Trial Journal Articles"
		local legend_ops "r(1) symx(small) symy(small)"
		local yvarCT ""
		local orderCT 3 "Other"
		local barsCT "bar(3, col(gs7))"
	}

	#delimit ;
	graph bar (asis) pub_countt pub_countc `yvarCT' pub_counto, stack
					over(fundname, lab(angle(45) labsize(vsmall)))
					over(disease, sort(total) descending lab(angle(60) labsize(small)))
				legend(order(1 "Translational Science" 2 "Clinical Science"
							 `orderCT') `legend_ops' pos(12))
				title("`title'" "About Diseases")
				subtitle("(`journals')")
				yti("Number of Publications" "(in `units')") aspect(0.2)
				bar(1, col(blue)) bar(2, col(cranberry)) `barsCT';
	graph save "PubMed/gphs/bars_ba-tr-cl_bydisease`_wCTs'`_vsCorp'`QA'.gphs", replace;
	graph export "WOS_Funding_Plots/bars_ba-tr-cl_bydisease`_wCTs'`_vsCorp'`QA'.png", replace as(png);
	#delimit cr
} // end loop over w/CTs and without CTs
*/
} // end  QA loop
/*
foreach _wCTs in "" "_wCTs" {
	grc1leg "PubMed/gphs/bars_ba-tr-cl_bydisease`_wCTs'`_vsCorp'.gphs" ///
			"PubMed/gphs/bars_ba-tr-cl_bydisease`_wCTs'`_vsCorp'_notQA.gphs", c(1)
	graph export "WOS_Funding_Plots/bars_ba-tr-cl_bydisease`_wCTs'`_vsCorp'_QA_vs_All.png", replace as(png)
} // end loop over w/CTs and without CTs
*/
} // end loop through not NIH and Corporations
*-----------------------------
} // end `ba_tr_cl_bydisease'
*-----------------------------


*-----------------------------
if `basic_msas' == 1 {
*-----------------------------
cap cd "C:/Users/lmostrom/Dropbox/Amitabh/"
foreach QA in "" "_notQA" {
	use "PubMed/Master_dta/pmids_bas_trans_clin`QA'.dta", clear

	tempfile pmids
	save `pmids', replace

	if "`QA'" == "" {
		use "PubMed/clean_auth_affls.dta", clear
		local journals "Top 7 Journals, Full Sample"
		local graphnote "note(BMJ, Cell, JAMA, Lancet, Nature, NEJM, Science)"
	}
	if "`QA'" == "_notQA" {
		use "PubMed/clean_auth_affls_master.dta", clear
		local journals "All Journals, 5% Sample Scaled Up"
		local graphnote ""
	}
	
	merge 1:m pmid using `pmids', keep(2 3) nogen
		drop if inlist(btc, "total", "totalCTs")

	gen has_affl = affl != ""
	gen usa = has_affl & inlist(country, "", "USA")

	gen MSAgroup = "BOS" if cbsacode == 14460
		replace MSAgroup = "SF & SJ" if inlist(cbsacode, 41860, 41940)
		replace MSAgroup = "CHI" if cbsacode == 16980
		replace MSAgroup = "NY" if cbsacode == 35620
		replace MSAgroup = "DC" if inlist(cbsacode, 47900)
		replace MSAgroup = "LA" if cbsacode == 31080
		replace MSAgroup = "SD" if cbsacode == 41740
		replace MSAgroup = "NHAV" if cbsacode == 35300
		replace MSAgroup = "SEA" if cbsacode == 42660
		replace MSAgroup = "DUR/CH" if cbsacode == 20500

		replace MSAgroup = "Other" if cbsacode != . & MSAgroup == ""

	levelsof btc, local(B_T_C)
	gen decade = 10*int(year/10)

	keep if has_affl
	collapse (count) pmid, by(MSAgroup decade btc)
		bys MSAgroup btc: egen sort_tot = total(pmid)
		if "`QA'" == "_notQA" replace pmid = pmid * 20
	foreach cat of local B_T_C {
		if "`cat'" == "basic" {
			local ti "Basic Science Publications"
			local cols "bar(1, col(emerald)) bar(2, col(midgreen)) bar(3, col(mint))"
		}
		if "`cat'" == "translational" {
			local ti "Translational Science Publications"
			local cols "bar(1, col(navy)) bar(2, col(blue)) bar(3, col(eltblue))"
		}
		if "`cat'" == "clinical" {
			local ti "Clinical Science Publications"
			local cols "bar(1, col(maroon)) bar(2, col(cranberry)) bar(3, col(erose))"
		}
		if "`cat'" == "trial" {
			local ti "Clinical Trials"
			local cols "bar(1, col(sienna)) bar(2, col(dkorange)) bar(3, col(sand))"
		}
		
		* -- Calculating N to show what % in these top MSAs -- *	
		preserve
			keep if btc == "`cat'"
			collapse (sum) pmid
			local N: dis pmid
		restore
		preserve
			keep if btc == "`cat'" & !inlist(MSAgroup, "", "Other")
			collapse (sum) pmid
			local n: dis pmid
			local pctN = round(`n'/`N'*100, 1)
		restore
			
		#delimit ;
		graph bar (asis) pmid if inlist(decade, 1990, 2000, 2010) 
			& !inlist(MSAgroup, "", "Other") & btc == "`cat'", 
			over(decade, gap(5)) asyvars `cols'
			over(MSAgroup, sort(sort_tot) descending) yti("")
		title("`ti'") subtitle("(`journals')" "Shown: `n' of `N' (`pctN'%) Publications")
		`graphnote'
		legend(order(1 "1990s" 2 "2000s" 3 "2010s") r(1));
		graph save "PubMed/gphs/bars_BTC_`cat'_bymsa_bydecade`QA'.gph", replace;
		graph export "bars_BTC_`cat'_bymsa_bydecade`QA'.png",
			replace as(png) wid(1600) hei(700);
		#delimit cr

	} // disease loop
	
	collapse (sum) pmid, by(MSAgroup btc)
	foreach cat of local B_T_C {
		if "`cat'" == "basic" {
			local ti "Basic Science Publications"
			local col "bar(1, col(midgreen))"
		}
		if "`cat'" == "translational" {
			local ti "Translational Science Publications"
			local col "bar(1, col(blue))"
		}
		if "`cat'" == "clinical" {
			local ti "Clinical Science Publications"
			local col "bar(1, col(cranberry))"
		}
		if "`cat'" == "trial" {
			local ti "Clinical Trials"
			local col "bar(1, col(dkorange))"
		}

		* -- Calculating N to show what % in these top MSAs -- *	
		preserve
			keep if btc == "`cat'"
			collapse (sum) pmid
			local N: dis pmid
		restore
		preserve
			keep if btc == "`cat'" & !inlist(MSAgroup, "", "Other")
			collapse (sum) pmid
			local n: dis pmid
			local pctN = round(`n'/`N'*100, 1)
		restore
		
		#delimit ;
		graph bar (asis) pmid if !inlist(MSAgroup, "", "Other") & btc == "`cat'", 
			over(MSAgroup, sort(pmid) descending) yti("") `col'
			title("`ti'") subtitle("(`journals')" "Shown: `n' of `N' (`pctN'%) Publications")
			`graphnote';
		graph save "PubMed/gphs/bars_BTC_`cat'_bymsa`QA'.gph", replace;
		graph export "bars_BTC_`cat'_bymsa`QA'.png", replace as(png) wid(1600) hei(700);
		#delimit cr
	}

}

*---------------------------
} // end plots by discipline by MSA
*---------------------------



*-----------------------------
if `alz' == 1 {
*-----------------------------
cap cd "C:/Users/lmostrom/Dropbox/Amitabh/PubMed/"
foreach notQA in "" "_notQA" {
	import delimited "PubMed_Search_Results_GBDlev2`notQA'_from1980.csv", clear varn(1)
	split query_name, p("_")
		drop query_name query_name2
		ren query_name1 disease
		
	collapse (sum) pub_count, by(year disease)
	bys year: egen all_pubs = total(pub_count)
	gen sh_of_tot = pub_count/all_pubs * 100

	if "`notQA'" == "" local journals "Top 8 Journals"
	else local journals "All Journals"

	#delimit ;
		* Alzheimer's vs. Cancer;
		tw (line pub_count year if disease == "Neoplasms", lc(black) lw(thin))
		   (line pub_count year if disease == "Dementia", lc(red)),
		 legend(order(2 "Alzhemier's & Other Dementias" 1 "Neoplasms") r(1))
		 title("PubMed Journal Articles About Alzheimer's Relative to Neoplasms")
		 subtitle("`journals'") yti("No. of Publications" " ") xti("");
		 
		graph export "../ts_alz_vs_cancer`notQA'.png", replace as(png) wid(1200) hei(700);
		
		* Alzheimer's vs. Total Neurological Conditions;
		tw (line pub_count year if disease == "Neurologic", lc(black) lw(thin))
		   (line pub_count year if disease == "Dementia", lc(red)),
		 legend(order(2 "Alzhemier's & Other Dementias" 1 "Neurological Conditions") r(1))
		 title("PubMed Journal Articles About Alzheimer's"
				"Relative to All Neurological Conditions")
		 subtitle("`journals'") yti("No. of Publications" " ") xti("");
		 
		graph export "../ts_alz_vs_neuro`notQA'.png", replace as(png) wid(1200) hei(700);

		*Alzheimer's Share of Total Pubs;
		tw (line sh_of_tot year if disease == "Dementia", lc(red)),
		 legend(off) title("PubMed Journal Articles About Alzheimer's Relative to Total")
		 subtitle("`journals'") yti("Share of Total Disease Publications (%)" " ") xti("");
		 
		graph export "../ts_alz_sh_of_tot`notQA'.png", replace as(png) wid(1200) hei(700);

	#delimit cr
	
	keep if inlist(disease, "Dementia", "Neurologic")
	keep disease year pub_count
	reshape wide pub_count, i(year) j(disease) string
	gen alz_sh = pub_countD / pub_countN * 100
	
	#delimit ;
		* Alzheimer's Share of Total Neuro;
		tw (line alz_sh year, lc(red)), legend(off)
		title("PubMed Journal Articles About Alzheimer's"
				"Relative to All Neurological Conditions")
		subtitle("`journals'") yti("Share of Neurological Publications (%)" " ") xti("");
		
		graph export "../ts_alz_sh_of_neuro`notQA'.png", replace as(png) wid(1200) hei(700);
	#delimit cr
	
} // end QA loop

cd ../Econlit

import excel "Cancer 1-500.xls", clear first
tempfile cancer
save `cancer', replace
import excel "Cancer 501-1155.xls", clear first
append using `cancer'
save "cancer.dta", replace
keep year
tempfile cancer_yr
save `cancer_yr', replace

import excel "Neuro 1-173", clear first
save "neuro.dta", replace
keep year
tempfile neuro_yr
save `neuro_yr', replace

import excel "Alz-Dem 1-134.xls", clear first
save "alz_dementia.dta", replace
	
keep year
gen disease = "Dementia"

append using `neuro_yr'
replace disease = "Neurologic" if disease == ""

append using `cancer_yr'
replace disease = "Neoplasms" if disease == ""

destring year, replace
gen id = _n
collapse (count) pub_count = id, by(disease year)

egen dis_id = group(disease)
xtset dis_id year
tsfill
replace pub_count = 0 if pub_count == .
bys dis_id: ereplace disease = mode(disease)

#delimit ;
		* Alzheimer's vs. Cancer;
		tw (line pub_count year if disease == "Neoplasms", lc(black) lw(thin))
		   (line pub_count year if disease == "Dementia", lc(red)),
		 legend(order(2 "Alzhemier's & Other Dementias" 1 "Cancer") r(1))
		 title("Econlit Journal Articles About Alzheimer's Relative to Cancer")
		 yti("No. of Publications" " ") xti("");
		 
		graph export "../ts_econlit_alz_vs_cancer.png", replace as(png) wid(1200) hei(700);
		
		* Alzheimer's vs. Total Neurological Conditions;
		tw (line pub_count year if disease == "Neurologic", lc(black) lw(thin))
		   (line pub_count year if disease == "Dementia", lc(red)),
		 legend(order(2 "Alzhemier's & Other Dementias" 1 "Neurological Conditions") r(1))
		 title("Econlit Journal Articles About Alzheimer's"
				"Relative to All Neurological Conditions")
		 yti("No. of Publications" " ") xti("");
		 
		graph export "../ts_econlit_alz_vs_neuro.png", replace as(png) wid(1200) hei(700);
#delimit cr


*---------------------------
} // end plots by discipline by MSA
*---------------------------