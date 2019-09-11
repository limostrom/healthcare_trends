/*

plot_pubmed_trends.do

*/

cap log close
clear all
set more off
pause on

local diseases_1980 0
local diseases_2005 1
local econ_1980 0
local econ_2005 0

*-----------------------------------------------------------
if `diseases_1980' == 1 {
*-------------------	
cap cd "C:\Users\lmostrom\Documents\Amitabh\"
import delimited "PubMed_Search_Results_byDisease_from1980.csv", varn(1) clear

split query_name, gen(disease_area) p("_")
	gen nih = (disease_area2 == "NIH")
	drop query_name
	ren pub_count count

preserve
	ren count total
	keep if disease_area1 == "Total"
	*br
	*pause
	save "pubmed_results_byyear_total_1980.dta", replace
restore
preserve
	ren count totaldisease
	keep if disease_area1 == "TotalDisease"
	*br
	*pause
	save "pubmed_results_byyear_totaldisease_1980.dta", replace
restore

ren disease_area1 disease_area
keep if !inlist(disease_area, "Total", "TotalDisease")
replace disease_area = lower(disease_area)
drop disease_area2

save "pubmed_results_byyear_bydisease_1980.dta", replace

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

		#delimit ;
		tw (line frac_disease year if nih == 0, lc(blue))
		   (line frac_disease year if nih == 1, lc(red)),
		 legend(order(1 "Not NIH" 2 "NIH"))
		 /*yline(1, lc(gs8)) xline(1980, lp(-) lc(gs8))*/
		 yti("Fraction of Publications About Disease");
		graph export "disease_share_of_pubmed_1980-2018.png", replace as(png) wid(1200) hei(700);

		tw (line frac_cat_coverage year if nih == 0, lc(blue))
		   (line frac_cat_coverage year if nih == 1, lc(red)),
		 legend(order(1 "Not NIH" 2 "NIH"))
		 /*yline(1, lc(gs8)) xline(1980, lp(-) lc(gs8))*/
		 yti("Ratio of Sum of Category Counts to Total Disease Counts" "(Overcounting Ratio)");
		graph export "sum_of_disease_cats_div_by_disease_pubs_1980-2018.png", replace as(png) wid(1200) hei(700);
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
	   (line sh_of_total year if nih == 0 & disease_area == "nutrition", lc(lime) lp(_))
	   (line sh_of_total year if nih == 0 & disease_area == "psych", lc(purple) lp(-))
	   (line sh_of_total year if nih == 0 & disease_area == "respiratory", lc(navy) lp(_)) /* 16 */
	   (line sh_of_total year if nih == 0 & disease_area == "skin", lc(magenta) lp(_..))
	   (line sh_of_total year if nih == 0 & disease_area == "infectiousdiseases", lc(red) lp(.)),
	 legend(order(15 "Psychiatry & Psychology"
				  12 "Cancer"
	 			  13 "Nervous System & Cognition"
	 			  1  "Cardiovascular"
	 			  16 "Respiratory"
	 			  9  "Immune System"
	 			  14 "Nutrition"
				  18 "Infectious Diseases"
	 			  3  "Digestive"
	 			  4  "Endocrine"
	 			  7  "Female Urogential & Pregnancy"
	 			  11 "Musculoskeletal"
	 			  17 "Skin & Connective Tissue"
	 			  10 "Male Urogenital"
	 			  8  "Hemic & Lymphomatic"
				  /*2  "Chemically-Induced" - Silenced because no longer included in the queries*/
	 			  6  "Eye"
	 			  5  "ENT & Mouth") c(1) pos(3))
	 yti("Share of Publications (%)") title("Not NIH-Funded");

	 graph export "pubmed_results_notnih_notwtd_1980-2018.png", replace as(png) wid(1600) hei(700);
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
	   (line sh_of_total year if nih == 1 & disease_area == "nervous", lc(lavender) lp(_))
	   (line sh_of_total year if nih == 1 & disease_area == "nutrition", lc(lime) lp(_))
	   (line sh_of_total year if nih == 1 & disease_area == "psych", lc(purple) lp(-))
	   (line sh_of_total year if nih == 1 & disease_area == "respiratory", lc(navy) lp(_)) /* 16 */
	   (line sh_of_total year if nih == 1 & disease_area == "skin", lc(magenta) lp(_..))
	   (line sh_of_total year if nih == 1 & disease_area == "infectiousdiseases", lc(red) lp(.)),
	 legend(order(15 "Psychiatry & Psychology"
				  12 "Cancer"
	 			  13 "Nervous System & Cognition"
	 			  1  "Cardiovascular"
	 			  9  "Immune System"
	 			  14 "Nutrition"
	 			  16 "Respiratory"
	 			  7  "Female Urogential & Pregnancy"
	 			  3  "Digestive"
	 			  4  "Endocrine"
	 			  17 "Skin & Connective Tissue"
	 			  11 "Musculoskeletal"
	 			  10 "Male Urogenital"
	 			  8  "Hemic & Lymphomatic"
	 			  6  "Eye"
				  5  "ENT & Mouth"
	 			  /*2  "Chemically-Induced" - Silenced because no longer included in the queries*/
	 			  18 "Infectious Diseases") c(1) pos(3))
	 yti("Share of Publications (%)") title("NIH-Funded");

	 graph export "pubmed_results_nih_notwtd_1980-2018.png", replace as(png) wid(1600) hei(700);
	 #delimit cr
*-------------------
}
*-------------------

*-----------------------------------------------------------
if `diseases_2005' == 1 {
*-------------------	
cap cd "C:\Users\lmostrom\Documents\Amitabh\"
import delimited "PubMed_Search_Results_byDisease_from2005.csv", varn(1) clear

lab def res_groups 1 "NIH" 2 "Gov't Non-NIH" 3 "Private"

split query_name, gen(disease_area) p("_")
	gen funding = 1 if (disease_area2 == "NIH")
		replace funding = 2 if (disease_area2 == "Pub")
		replace funding = 3 if (disease_area2 == "Priv")
		lab val funding res_groups
	drop query_name
	ren pub_count count

preserve
	ren count total
	keep if disease_area1 == "Total"
	*br
	*pause
	save "pubmed_results_byyear_total_2005.dta", replace
restore
preserve
	ren count totaldisease
	keep if disease_area1 == "TotalDisease"
	*br
	*pause
	save "pubmed_results_byyear_totaldisease_2005.dta", replace
restore

ren disease_area1 disease_area
keep if !inlist(disease_area, "Total", "TotalDisease")
replace disease_area = lower(disease_area)
drop disease_area2

save "pubmed_results_byyear_bydisease_2005.dta", replace

*-------------------------------------------------------------

bys funding year: egen sum_cats = total(count)
gen sh_of_total = count/sum_cats*100

merge m:1 year funding using "pubmed_results_byyear_total_2005.dta", nogen keep(1 3) keepus(total)
merge m:1 year funding using "pubmed_results_byyear_totaldisease_2005.dta", nogen keep(1 3) keepus(totaldisease)

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
		graph export "disease_share_of_pubmed_2005-2018.png", replace as(png) wid(1200) hei(700);

		tw (line frac_cat_coverage year if funding == 1, lc(red))
		   (line frac_cat_coverage year if funding == 2, lc(blue))
		   (line frac_cat_coverage year if funding == 3, lc(green)),
		 legend(order(1 "NIH" 2 "Gov't Non-NIH" 3 "Private"))
		 yti("Fraction of Publications About Disease");
		graph export "sum_of_disease_cats_div_by_disease_pubs_2005-2018.png", replace as(png) wid(1200) hei(700);
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
	   (line sh_of_total year if funding == 1 & disease_area == "nutrition", lc(lime) lp(_))
	   (line sh_of_total year if funding == 1 & disease_area == "psych", lc(purple) lp(-))
	   (line sh_of_total year if funding == 1 & disease_area == "respiratory", lc(navy) lp(_)) /* 16 */
	   (line sh_of_total year if funding == 1 & disease_area == "skin", lc(magenta) lp(_..))
	   (line sh_of_total year if funding == 1 & disease_area == "infectiousdiseases", lc(red) lp(.)),
	 legend(order(15 "Psychiatry & Psychology"
				  1  "Cardiovascular"
	 			  12 "Cancer"
	 			  13 "Nervous System & Cognition"
	 			  16 "Respiratory"
	 			  9  "Immune System"
	 			  14 "Nutrition"
	 			  7  "Female Urogential & Pregnancy"
	 			  11 "Musculoskeletal"
	 			  3  "Digestive"
	 			  17 "Skin & Connective Tissue"
	 			  10 "Male Urogenital"
	 			  8  "Hemic & Lymphomatic"
	 			  4  "Endocrine"
	 			  5  "ENT & Mouth"
	 			  6  "Eye"
				  /*2  "Chemically-Induced" - Silenced because no longer included in the queries*/
				  18 "Infectious Diseases") c(1) pos(3))
	 yti("Share of Publications (%)") title("NIH Funded");

	 graph export "pubmed_results_nih_notwtd_2005-2018.png", replace as(png) wid(1600) hei(700);
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
	   (line sh_of_total year if funding == 2 & disease_area == "nutrition", lc(lime) lp(_))
	   (line sh_of_total year if funding == 2 & disease_area == "psych", lc(purple) lp(-))
	   (line sh_of_total year if funding == 2 & disease_area == "respiratory", lc(navy) lp(_)) /* 16 */
	   (line sh_of_total year if funding == 2 & disease_area == "skin", lc(magenta) lp(_..))
	   (line sh_of_total year if funding == 2 & disease_area == "infectiousdiseases", lc(red) lp(.)),
	 legend(order(15 "Psychiatry & Psychology"
				  12 "Cancer"
	 			  13 "Nervous System & Cognition"
	 			  1  "Cardiovascular"
	 			  9  "Immune System"
	 			  14 "Nutrition"
	 			  16 "Respiratory"
	 			  7  "Female Urogential & Pregnancy"
	 			  3  "Digestive"
	 			  4  "Endocrine"
	 			  17 "Skin & Connective Tissue"
	 			  11 "Musculoskeletal"
	 			  10 "Male Urogenital"
	 			  8  "Hemic & Lymphomatic"
	 			  6  "Eye"
				  5  "ENT & Mouth"
	 			  /*2  "Chemically-Induced" - Silenced because no longer included in the queries*/
	 			  18 "Infectious Diseases") c(1) pos(3))
	 yti("Share of Publications (%)") title("Gov't Non-NIH Funded");

	 graph export "pubmed_results_public_notwtd_2005-2018.png", replace as(png) wid(1600) hei(700);
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
	   (line sh_of_total year if funding == 3 & disease_area == "nutrition", lc(lime) lp(_))
	   (line sh_of_total year if funding == 3 & disease_area == "psych", lc(purple) lp(-))
	   (line sh_of_total year if funding == 3 & disease_area == "respiratory", lc(navy) lp(_)) /* 16 */
	   (line sh_of_total year if funding == 3 & disease_area == "skin", lc(magenta) lp(_..))
	   (line sh_of_total year if funding == 3 & disease_area == "infectiousdiseases", lc(red) lp(.)),
	 legend(order(15 "Psychiatry & Psychology"
				  12 "Cancer"
	 			  13 "Nervous System & Cognition"
	 			  1  "Cardiovascular"
	 			  9  "Immune System"
	 			  14 "Nutrition"
	 			  16 "Respiratory"
	 			  7  "Female Urogential & Pregnancy"
	 			  3  "Digestive"
	 			  4  "Endocrine"
	 			  17 "Skin & Connective Tissue"
	 			  11 "Musculoskeletal"
	 			  10 "Male Urogenital"
	 			  8  "Hemic & Lymphomatic"
	 			  6  "Eye"
				  5  "ENT & Mouth"
	 			  /*2  "Chemically-Induced" - Silenced because no longer included in the queries*/
	 			  18 "Infectious Diseases") c(1) pos(3))
	 yti("Share of Publications (%)") title("Privately Funded");

	 graph export "pubmed_results_private_notwtd_2005-2018.png", replace as(png) wid(1600) hei(700);
	 #delimit cr
*-------------------
}
*-------------------

*-----------------------------------------------------------
if `econ_1980' == 1 {
*-------------------	
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

*-----------------------------------------------------------
if `econ_2005' == 1 {
*-------------------	
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