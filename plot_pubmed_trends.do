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
local ba_tr_cl 1

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

import delimited "PubMed_Search_Results_drugs_devices_notQA_from1980.csv", clear varn(1)

split query_name, p("_")
gen nih = query_name3 == "NIH"

drop query_name query_name3
ren query_name1 query_name
ren query_name2 pub_type

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

forval nih01 = 0/1 {

	if `nih01' == 0 local fund "Not Funded by NIH"
	if `nih01' == 1 local fund "Funded by NIH"

	graph pie pub_count if pub_type == "CT" & nih == `nih01', ///
		over(query_name) sort(qcode) ///
		pl(1 percent, c(white) format(%9.3g)) ///
		pl(3 percent, c(white) format(%9.3g)) ///
		pl(4 percent, c(white) format(%9.3g)) ///
		pl(5 percent, c(white) format(%9.3g)) ///
		title("Clinical Trials (II & III) `fund'") legend(colfirst) ///
		subtitle("All Journals" "Shown: `n_CT`nih01'' of `N_CT`nih01'' Trials") ///
		pie(1, c(cranberry)) pie(2, c(magenta)) pie(3, c(purple)) ///
		pie(4, c(dkgreen)) pie(5, c(dkorange))
	graph export "pies_drugs_devices_CTs_nih`nih01'.png", replace as(png)

	graph pie pub_count if pub_type == "Pub" & nih == `nih01', ///
		over(query_name) sort(qcode) ///
		pl(1 percent, c(white) format(%9.3g)) ///
		pl(3 percent, c(white) format(%9.3g)) ///
		pl(4 percent, c(white) format(%9.3g)) ///
		pl(5 percent, c(white) format(%9.3g)) ///
		pl(6 percent, c(white) format(%9.3g)) ///
		pl(7 percent, c(white) format(%9.3g)) ///
		pl(8 percent, c(white) format(%9.3g)) ///
		title("Non-Trial Journal Articles `fund'") legend(colfirst) ///
		subtitle("All Journals" "Shown: `n_Pub`nih01'' of `N_Pub`nih01'' Papers") ///
		pie(1, c(cranberry)) pie(2, c(magenta)) pie(3, c(purple)) ///
		pie(4, c(dkgreen)) pie(5, c(dkorange)) ///
		pie(6, c(sienna)) pie(7, c(midblue)) pie(8, c(midgreen))
	graph export "pies_drugs_devices_Pubs_nih`nih01'.png", replace as(png)
}

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

	if `nih01' == 0 local fund "Not Funded by NIH"
	if `nih01' == 1 local fund "Funded by NIH"

	graph pie pub_count if nih == `nih01', over(query_name) sort(qcode) ///
		pl(1 percent, c(white) format(%9.3g)) ///
		pl(3 percent, c(white) format(%9.3g)) ///
		pl(4 percent, c(white) format(%9.3g)) ///
		pl(5 percent, c(white) format(%9.3g)) ///
		pl(6 percent, c(white) format(%9.3g)) ///
		pl(7 percent, c(white) format(%9.3g)) ///
		pl(8 percent, c(white) format(%9.3g)) ///
		title("Journal Articles and Clinical Trials (II & III)" "`fund'") legend(colfirst) ///
		subtitle("All Journals" "Shown: `n`nih01'' of `N`nih01'' Publications") ///
		pie(1, c(cranberry)) pie(2, c(magenta)) pie(3, c(purple)) ///
		pie(4, c(dkgreen)) pie(5, c(dkorange)) ///
		pie(6, c(sienna)) pie(7, c(midblue)) pie(8, c(midgreen))
	graph export "pies_drugs_devices_All_nih`nih01'.png", replace as(png)
}

*--------- Not Separated NIH/Not NIH -----------------*
import delimited "PubMed_Search_Results_drugs_devices_notQA_from1980.csv", clear varn(1)

split query_name, p("_")

drop query_name query_name3
ren query_name1 query_name
ren query_name2 pub_type

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

graph pie pub_count if pub_type == "CT", ///
	over(query_name) sort(qcode) ///
	pl(1 percent, c(white) format(%9.3g)) ///
	pl(3 percent, c(white) format(%9.3g)) ///
	pl(4 percent, c(white) format(%9.3g)) ///
	pl(5 percent, c(white) format(%9.3g)) ///
	title("Clinical Trials (II & III)") legend(colfirst) ///
	subtitle("All Journals" "Shown: `n_CT' of `N_CT' Trials") ///
	pie(1, c(cranberry)) pie(2, c(magenta)) pie(3, c(purple)) ///
	pie(4, c(dkgreen)) pie(5, c(dkorange))
graph export "pies_drugs_devices_CTs.png", replace as(png)

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
	subtitle("All Journals" "Shown: `n_Pub' of `N_Pub' Papers") ///
	pie(1, c(cranberry)) pie(2, c(magenta)) pie(3, c(purple)) ///
	pie(4, c(dkgreen)) pie(5, c(dkorange)) ///
	pie(6, c(sienna)) pie(7, c(midblue)) pie(8, c(midgreen))
graph export "pies_drugs_devices_Pubs.png", replace as(png)

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
	subtitle("All Journals" "Shown: `n' of `N' Publications") ///
	pie(1, c(cranberry)) pie(2, c(magenta)) pie(3, c(purple)) ///
	pie(4, c(dkgreen)) pie(5, c(dkorange)) ///
	pie(6, c(sienna)) pie(7, c(midblue)) pie(8, c(midgreen))
graph export "pies_drugs_devices_All.png", replace as(png)

*-----------------------------
} // end `drugs_and_devices'
*-----------------------------

*-----------------------------
if `ba_tr_cl' == 1 {
*-----------------------------
cap cd "C:\Users\lmostrom\Dropbox\Amitabh\"

foreach QA in "" "_notQA" {
	
	if "`QA'" == "" local journals = "Top 13 Journals"
	if "`QA'" == "_notQA" local journals = "All Journals"

	import delimited "PubMed_Search_Results_ba-tr-cl`QA'_from1980.csv", clear varn(1)

	split query_name, p("_")
	drop query_name
	ren query_name1 query_name
		replace query_name = "clinical" ///
			if inlist(query_name, "clinical1", "clinical2") // not needed anymore
	ren query_name2 fund
		gen nih = fund == "NIH"
		drop fund

	gen decade = int(year/10)*10

	*--------- BY DECADE AND FUNDING ---------*
	collapse (sum) pub_count, by(query_name nih decade)

	forval f = 0/1 {
		forval dec = 1980(10)2010 {
			preserve
				keep if query_name == "total" & nih == `f' & decade == `dec'
				local N_`dec'_`f': dis pub_count
				dis "N `dec's `f's: `N_`dec'_`f''"
			restore
		}
		local N_`f' = `N_1980_`f'' + `N_1990_`f'' + `N_2000_`f'' + `N_2010_`f''
	}

	bys decade nih: egen counted = sum(pub_count) if query_name != "total"

	forval f = 0/1 {
		forval dec = 1980(10)2010 {
			preserve
				keep if nih == `f' & decade == `dec'
				local n_`dec'_`f': dis counted
				dis "Shown `dec's `f's: `n_`dec'_`f''"
			restore
		}
		local n_`f' = `n_1980_`f'' + `n_1990_`f'' + `n_2000_`f'' + `n_2010_`f''
	}

	drop if query_name == "total"
	keep decade nih pub_count query_name

	if "`QA'" == "" {
		replace pub_count = pub_count/1000
		local units "Thousands"
	}
	if "`QA'" == "_notQA" {
		replace pub_count = pub_count/1000000
		local units "Millions"
	}
	lab var pub_count "Publications (in `units')"

	reshape wide pub_count, i(decade nih) j(query_name) string
	tostring decade, replace
	replace decade = decade + "s"

	forval nih01 = 0/1 {

		if `nih01' == 0 local fund "Not Funded by NIH"
		if `nih01' == 1 local fund "Funded by NIH"

		#delimit ;
		graph bar (asis) pub_countb pub_countt pub_countc if nih == `nih01',
			over(decade) stack
			legend(order(1 "Basic" 2 "Translational" 3 "Clinical" ) r(1))
			title("Non-Trial Journal Articles `fund'")
			subtitle("(`journals')" "Shown: `n_`nih01'' of `N_`nih01'' Publications")
			yti("Number of Publications" "(in `units')")
			bar(1, col(midgreen)) bar(2, col(blue)) bar(3, col(cranberry));
		graph save "PubMed/gphs/bars_ba-tr-cl_bydecade`QA'_nih`nih01'.gph", replace;
		graph export "bars_ba-tr-cl_bydecade`QA'_nih`nih01'.png", replace as(png);
		#delimit cr
	}

	grc1leg "PubMed/gphs/bars_ba-tr-cl_bydecade`QA'_nih1.gph" ///
			"PubMed/gphs/bars_ba-tr-cl_bydecade`QA'_nih0.gph", r(2)
	graph export "bars_ba-tr-cl_bydecade`QA'_combined.png", replace as(png)

	*--------- BY FUNDING ---------*
	import delimited "PubMed_Search_Results_ba-tr-cl`QA'_from1980.csv", clear varn(1)

	split query_name, p("_")
	drop query_name
	ren query_name1 query_name
		replace query_name = "clinical" ///
			if inlist(query_name, "clinical1", "clinical2") // not needed anymore
	ren query_name2 fund
		gen nih = fund == "NIH"
		drop fund

	collapse (sum) pub_count, by(query_name nih)

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

	graph pie pub_count if nih == 0, over(query_name) sort(qcode) ///
		pl(1 percent, c(white) format(%9.3g) size(medium)) ///
		pl(2 percent, c(white) format(%9.3g) size(medium)) ///
		pl(3 percent, c(white) format(%9.3g) size(medium)) ///
		title("Non-NIH-Funded Publications") legend(colfirst r(1)) ///
		subtitle("Non-Trial Journal Articles" "(`journals')" ///
					"Shown: `n_0' of `N_0' Publications") ///
		pie(1, c(midgreen)) pie(2, c(blue)) pie(3, c(cranberry))
	graph save "PubMed/gphs/pies_ba-tr-cl`QA'_nih0.gph", replace
	graph export "pies_ba-tr-cl`QA'_nih0.png", replace as(png)

	graph pie pub_count if nih == 1, over(query_name) sort(qcode) ///
		pl(1 percent, c(white) format(%9.3g) size(medium)) ///
		pl(2 percent, c(white) format(%9.3g) size(medium)) ///
		pl(3 percent, c(white) format(%9.3g) size(medium)) ///
		title("NIH-Funded Publications") legend(colfirst r(1)) ///
		subtitle("Non-Trial Journal Articles" "(`journals')" ///
					"Shown: `n_1' of `N_1' Publications") ///
		pie(1, c(midgreen)) pie(2, c(blue)) pie(3, c(cranberry))
	graph save "PubMed/gphs/pies_ba-tr-cl`QA'_nih1.gph", replace
	graph export "pies_ba-tr-cl`QA'_nih1.png", replace as(png)

		grc1leg "PubMed/gphs/pies_ba-tr-cl`QA'_nih0.gph" ///
				"PubMed/gphs/pies_ba-tr-cl`QA'_nih1.gph", r(1)
		graph export "pies_ba-tr-cl`QA'_combined.png", replace as(png)

	local N = `N_0' + `N_1'
	local n = `n_0' + `n_1'
	collapse (sum) pub_count, by(query_name qcode)

	preserve
		collapse (sum) pub_count
		assert pub_count == `n'
	restore

	graph pie pub_count , over(query_name) sort(qcode) ///
		pl(1 percent, c(white) format(%9.3g)) ///
		pl(2 percent, c(white) format(%9.3g)) ///
		pl(3 percent, c(white) format(%9.3g)) ///
		title("Total Publications") legend(colfirst r(1)) ///
		subtitle("Non-Trial Journal Articles" "(`journals')" ///
					"Shown: `n' of `N' Publications") ///
		pie(1, c(midgreen)) pie(2, c(blue)) pie(3, c(cranberry))
	graph save "PubMed/gphs/pies_ba-tr-cl`QA'_all.gph", replace
	graph export "pies_ba-tr-cl`QA'_all.png", replace as(png)
} // end QA loop
*-----------------------------
} // end `ba_tr_cl'
*-----------------------------