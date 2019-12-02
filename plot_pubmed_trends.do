/*

plot_pubmed_trends.do

*/

cap log close
clear all
set more off
pause on

local diseases_1980 1
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