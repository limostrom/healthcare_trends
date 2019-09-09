/*

plot_pubmed_trends.do

*/

cap log close
clear all
set more off
pause on

local plot 1


if `plot' == 1 {
*-------------------	
	bys nih year: egen sum_cats = total(count)
	gen sh_of_total = count/sum_cats*100

	merge m:1 year nih using "../pubmed_results_byyear_total.dta", nogen keep(1 3)
	merge m:1 year nih using "../pubmed_results_byyear_totaldisease.dta", nogen keep(1 3)

	keep if inrange(year, 1965, 2017)

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
		 yline(1, lc(gs8)) xline(1980, lp(-) lc(gs8))
		 yti("Fraction of Publications About Disease");
		graph export "../disease_share_of_pubmed.png", replace as(png) wid(1200) hei(700);

		tw (line frac_cat_coverage year if nih == 0, lc(blue))
		   (line frac_cat_coverage year if nih == 1, lc(red)),
		 legend(order(1 "Not NIH" 2 "NIH"))
		 yline(1, lc(gs8)) xline(1980, lp(-) lc(gs8))
		 yti("Fraction of Publications About Disease");
		graph export "../sum_of_disease_cats_div_by_disease_pubs.png", replace as(png) wid(1200) hei(700);
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
	   (line sh_of_total year if nih == 0 & disease_area == "hemic", lc(red) lp(--.))
	   (line sh_of_total year if nih == 0 & disease_area == "immune", lc(gs7) lp(.))
	   (line sh_of_total year if nih == 0 & disease_area == "male", lc(blue) lp(_))
	   (line sh_of_total year if nih == 0 & disease_area == "muscle", lc(gold) lp(-)) /* 11 */
	   (line sh_of_total year if nih == 0 & disease_area == "neoplasms", lc(orange) lp(.))
	   (line sh_of_total year if nih == 0 & disease_area == "nervous", lc(lavender) lp(_))
	   (line sh_of_total year if nih == 0 & disease_area == "nutrition", lc(lime) lp(_))
	   (line sh_of_total year if nih == 0 & disease_area == "psych", lc(purple) lp(-))
	   (line sh_of_total year if nih == 0 & disease_area == "respiratory", lc(navy) lp(_)) /* 16 */
	   (line sh_of_total year if nih == 0 & disease_area == "skin", lc(magenta) lp(_..))
	   (line sh_of_total year if nih == 0 & disease_area == "infectious", lc(eltblue) lp(.)),
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
	 			  8  "Hemic"
	 			  4  "Endocrine"
	 			  5  "ENT & Mouth"
	 			  6  "Eye"
				  2  "Chemically-Induced"
				  18 "Infectious Diseases") c(1) pos(3))
	 yti("Share of Publications (%)") title("Not NIH-Funded");

	 graph export "../pubmed_results_notnih_notwtd_1965-2018.png", replace as(png) wid(1600) hei(700);
	 #delimit cr

	keep if inrange(year, 1980, 2018)

*** Plot Shares of NIH-Funded Research by Disease Area
	#delimit ;
	tw (line sh_of_total year if nih == 1 & disease_area == "cardio", lc(cranberry) lp(-)) /* 1 */
	   (line sh_of_total year if nih == 1 & disease_area == "cheminduced", lc(sienna) lp(_))
	   (line sh_of_total year if nih == 1 & disease_area == "digestive", lc(erose) lp(--.))
	   (line sh_of_total year if nih == 1 & disease_area == "endocrine", lc(dkorange) lp(l))
	   (line sh_of_total year if nih == 1 & disease_area == "ent", lc(midgreen) lp(-.))
	   (line sh_of_total year if nih == 1 & disease_area == "eye", lc(gs12) lp(_.)) /* 6 */
	   (line sh_of_total year if nih == 1 & disease_area == "female", lc(pink) lp(__.))
	   (line sh_of_total year if nih == 1 & disease_area == "hemic", lc(red) lp(--.))
	   (line sh_of_total year if nih == 1 & disease_area == "immune", lc(gs7) lp(.))
	   (line sh_of_total year if nih == 1 & disease_area == "male", lc(blue) lp(_))
	   (line sh_of_total year if nih == 1 & disease_area == "muscle", lc(gold) lp(-)) /* 11 */
	   (line sh_of_total year if nih == 1 & disease_area == "neoplasms", lc(orange) lp(.))
	   (line sh_of_total year if nih == 1 & disease_area == "nervous", lc(lavender) lp(_))
	   (line sh_of_total year if nih == 1 & disease_area == "nutrition", lc(lime) lp(_))
	   (line sh_of_total year if nih == 1 & disease_area == "psych", lc(purple) lp(-))
	   (line sh_of_total year if nih == 1 & disease_area == "respiratory", lc(navy) lp(_)) /* 16 */
	   (line sh_of_total year if nih == 1 & disease_area == "skin", lc(magenta) lp(_..))
	   (line sh_of_total year if nih == 0 & disease_area == "infectious", lc(eltblue) lp(.)),
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
	 			  8  "Hemic"
	 			  6  "Eye"
				  5  "ENT & Mouth"
	 			  2  "Chemically-Induced"
	 			  18 "Infectious Diseases") c(1) pos(3))
	 yti("Share of Publications (%)") title("NIH-Funded");

	 graph export "../pubmed_results_nih_notwtd_1980-2018.png", replace as(png) wid(1600) hei(700);
	 #delimit cr
*-------------------
}
*-------------------

