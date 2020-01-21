/*
pmid_authaffl_plots.do


*/

pause on

local plots 0
local plots_2005 0
local plots_bydis 0
local plots_bydiscipline 1
	local old_MSAs 0
	local ext "_master" // set to "" for lifesci, "_hs" for health service

local non_us 0
local non_us_2005 0



*================================================================================
* (5) Plot Top MSA Publication Counts
*================================================================================
*---------------------------
if `plots' == 1 {
*---------------------------
use affls`ext'_master.dta, clear

gen has_affl = affl != ""
gen usa = has_affl & inlist(country, "", "USA")

preserve
	#delimit ;
	collapse (count) Total = pmid
			 (sum) w_Affiliation = has_affl 
			 (sum) USA = usa
			 (count) Final = cbsacode, by(year);
	#delimit cr
	sort year
	export delimited sample`ext'_byYr_12-10-2019.csv, replace
restore

preserve
	collapse (sum) USA = usa (count) final = cbsacode, by(year lifesci)
	gen coverage = final/USA * 100
	#delimit ;
	tw (line coverage year if lifesci, lc(green) lp(l))
	   (line coverage year if !lifesci, lc(navy) lp(l)),
	 legend(order(1 "Disease-Related" 2 "Non-Disease-Related"))
	 yti("Share of US Publications with Found MSA Code (%)")
	 xti("Year");
	#delimit cr
	graph export coverage_byLifeNonLife`ext'_12-10-19.png, as(png) replace wid(1200) hei(700)
restore

gen MSAgroup = "BOS" if cbsacode == 14460
	replace MSAgroup = "SF & SJ" if inlist(cbsacode, 41860, 41940)
	replace MSAgroup = "CHI" if cbsacode == 16980
	replace MSAgroup = "NY" if cbsacode == 35620
	replace MSAgroup = "DC" if inlist(cbsacode, 47900)
	replace MSAgroup = "LA" if cbsacode == 31080
	replace MSAgroup = "SD" if cbsacode == 41740
if `old_MSAs' == 0 {
	replace MSAgroup = "PHL" if cbsacode == 37980
	replace MSAgroup = "MIA" if cbsacode == 33100
	replace MSAgroup = "MN-SP" if cbsacode == 33460
	local folder ""
}
else {
	replace MSAgroup = "NHAV" if cbsacode == 35300
	replace MSAgroup = "SEA" if cbsacode == 42660
	replace MSAgroup = "DUR/CH" if cbsacode == 20500
	local folder "Plots - old Top MSAs/"
}	
	replace MSAgroup = "Other" if cbsacode != . & MSAgroup == ""


if "`ext'" == "_ct" {
	local years "1995, 2005, 2015"
	local yvar "Clinical Trials"
	local subti "1995-2015"
	local life_nonlife "life01 = 0/0"
}
else {
	local years "1990, 2000, 2010"
	local yvar "Publications"
	local subti "1990-2010"
	if "`ext'" == "_hs" local life_nonlife "life01 = 0/0"
	else local life_nonlife "life01 = 1/1"
}

preserve
	collapse (count) pmid, by(MSAgroup year nih lifesci)
	forval nih01 = 0/1 {
		forval `life_nonlife' {
			if `nih01' == 1 local ti "NIH-Funded"
			if `nih01' == 0 local ti "Non-NIH-Funded"

			if "`ext'" == "" {
				if `life01' == 1 local ti "`ti' Disease-Related Research"
				if `life01' == 0 local ti "`ti' Non-Disease-Related Research"
			}

			#delimit ;
			graph bar (asis) pmid if inlist(year, `years') & !inlist(MSAgroup, "", "Other") 
					& lifesci == `life01' & nih == `nih01', 
				over(year, gap(5)) asyvars bar(1, col(green)) bar(2, col(eltblue)) bar(3, col(gold))
				over(MSAgroup, sort(msa_order)) yti("No. of `yvar'") legend(r(1))
			title("`ti'")   subtitle("(`subti')");
			graph export "`folder'pubs`ext'_byYr_byMSA_life`life01'_nih`nih01'.png", replace as(png) wid(1600) hei(700);
			#delimit cr
		}
	}
	collapse (sum) pmid, by(MSAgroup year lifesci)
	forval `life_nonlife' {
		if "`ext'" == "" {
				if `life01' == 1 local ti "Disease-Related Research, All Funding Types"
				if `life01' == 0 local ti "Non-Disease-Related Research, All Funding Types"
		}
		else local ti "All Funding Types"

		#delimit ;
		graph bar (asis) pmid if inlist(year,`years') & !inlist(MSAgroup, "", "Other") 
				& lifesci == `life01', 
			over(year, gap(5)) asyvars bar(1, col(green)) bar(2, col(eltblue)) bar(3, col(gold))
			over(MSAgroup, sort(msa_order)) yti("No. of `yvar'") legend(r(1))
			title("`ti'")   subtitle("(`subti')");
		graph export "`folder'pubs`ext'_byYr_byMSA_life`life01'.png", replace as(png) wid(1600) hei(700);
		#delimit cr
	}
restore

gen match_group = "TopMSA" if !inlist(MSAgroup, "", "Other")
replace match_group = "OtherMSA" if MSAgroup == "Other"
replace match_group = "NotMatched" if has_affl == 1 & cbsacode == . & inlist(country, "", "USA")

preserve
	collapse (count) pubs = pmid, by(match_group year lifesci nih)
	keep if match_group != ""

	reshape wide pubs, i(year lifesci nih) j(match_group) string
		sort year lifesci nih
		export delimited "`folder'pubs`ext'_ts_byMatched.csv", replace
	gen pubsOtherMSA_adj = pubsOtherMSA + pubsTopMSA
	gen pubsNotMatched_adj = pubsNotMatched + pubsOtherMSA + pubsTopMSA

	forval nih01 = 0/1 {
		forval life01 = 0/1 {
			if `nih01' == 1 local ti "NIH-Funded"
			if `nih01' == 0 local ti "Non-NIH-Funded"

			if "`ext'" == "" {
				if `life01' == 1 local ti "`ti' Disease-Related Research"
				if `life01' == 0 local ti "`ti' Non-Disease-Related Research"
			}

			#delimit ;
			tw (area pubsNotMatched_adj year if lifesci == `life01' & nih == `nih01', col(gs8))
			   (area pubsOtherMSA_adj year if lifesci == `life01' & nih == `nih01', col(navy))
			   (area pubsTopMSA year if lifesci == `life01' & nih == `nih01', col(cranberry)),
			 legend(order(1 "Have Affiliations but Not Matched to MSA Codes"
			 			  2 "Matched to MSA Codes Other than Top 10"
			 			  3 "Matched to BOS, CHI, DC, LA, MIA, MN-SP, NY, PHL, SD, or SF/SJ")
			 		c(1))
			 title("`ti'") subtitle("(1988-2018)") yti("No. of `yvar'");
			graph export "`folder'pubs`ext'_ts_byMatched_life`life01'_nih`nih01'.png", replace as(png) wid(1600) hei(700);
			#delimit cr
		}
	}

	collapse (sum) pubs*, by(year lifesci)
	forval life01 = 0/1 {
		if "`ext'" == "" {
				if `life01' == 1 local ti "Disease-Related Research, All Funding Types"
				if `life01' == 0 local ti "Non-Disease-Related Research, All Funding Types"
		}
		else local ti "All Funding Types"

		#delimit ;
		tw (area pubsNotMatched_adj year if lifesci == `life01', col(gs8))
		   (area pubsOtherMSA_adj year if lifesci == `life01', col(navy))
		   (area pubsTopMSA year if lifesci == `life01', col(cranberry)),
		 legend(order(1 "Have Affiliations but Not Matched to MSA Codes"
		 			  2 "Matched to MSA Codes Other than Top 10"
		 			  3 "Matched to BOS, CHI, DC, LA, MIA, MN-SP, NY, PHL, SD, or SF/SJ")
		 		c(1))
		 title("`ti'") subtitle("(1988-2018)") yti("No. of `yvar'");
		graph export "`folder'pubs`ext'_ts_byMatched_life`life01'.png", replace as(png) wid(1600) hei(700);
		#delimit cr
	}

	collapse (sum) pubs*, by(year)
	#delimit ;
		tw (area pubsNotMatched_adj year, col(gs8))
		   (area pubsOtherMSA_adj year, col(navy))
		   (area pubsTopMSA year, col(cranberry)),
		 legend(order(1 "Have Affiliations but Not Matched to MSA Codes"
		 			  2 "Matched to MSA Codes Other than Top 10"
		 			  3 "Matched to BOS, CHI, DC, LA, MIA, MN-SP, NY, PHL, SD, or SF/SJ")
		 		c(1))
		 title("Total PubMed Publications from Top 13 Journals") subtitle("(1988-2018)") yti("No. of `yvar'");
		graph export "`folder'pubs`ext'_ts_byMatched.png", replace as(png) wid(1600) hei(700);
		#delimit cr

		export delimited "`folder'pubs`ext'_ts_byMatched.csv", replace
restore


replace match_group = "" if inlist(match_group, "OtherMSA", "NotMatched")
preserve
	assert inlist(match_group, "", "TopMSA")
	replace match_group = "Other" if match_group == ""
	collapse (count) pubs = pmid, by(match_group year lifesci)


	reshape wide pubs, i(year lifesci) j(match_group) string
		sort year lifesci
	gen pubsOther_adj = pubsOther + pubsTopMSA

	#delimit ;
		tw (area pubsOther_adj year if lifesci == 1, col(gs8))
		   (area pubsTopMSA year if lifesci == 1, col(cranberry)),
		 legend(order(2 "Publications matched to BOS, CHI, DC, LA, MIA, MN-SP, NY, PHL, SD, or SF/SJ"
		 			  1 "Other Publications")
		 		c(1))
		 title("Disease-Related PubMed Publications from the Top 10 MSAs")
		 subtitle("From Top 13 Journals" "(1988-2018)") yti("No. of `yvar'");
		graph export "`folder'pubs`ext'_ts_top10_disease.png", replace as(png) wid(1600) hei(700);
	#delimit cr

	gen pubsTotal = pubsOther_adj
	export delimited year pubsTopMSA pubsTotal using "`folder'pubs`ext'_ts_top10_disease.csv" if lifesci == 1, replace
	drop pubsTotal

	collapse (sum) pubs*, by(year)
	
	#delimit ;
		tw (area pubsOther_adj year, col(gs8))
		   (area pubsTopMSA year, col(cranberry)),
		 legend(order(2 "Matched to BOS, CHI, DC, LA, MIA, MN-SP, NY, PHL, SD, or SF/SJ"
		 			  1 "Other Publications")
		 		c(1))
		 title("Total PubMed Publications from the Top 10 MSAs")
		 subtitle("From Top 13 Journals" "(1988-2018)") yti("No. of `yvar'");
		graph export "`folder'pubs`ext'_ts_top10_all.png", replace as(png) wid(1600) hei(700);
	#delimit cr

	gen pubsTotal = pubsOther_adj
	export delimited year pubsTopMSA pubsTotal using "`folder'pubs`ext'_ts_top10_all.csv", replace
	drop pubsTotal

restore
*---------------------------
}
*---------------------------

*---------------------------
if `plots_2005' == 1 {
*---------------------------
use affls_master_2005.dta, clear

gen has_affl = affl != ""
gen usa = has_affl & inlist(country, "", "USA")

gen MSAgroup = "BOS" if cbsacode == 14460
	replace MSAgroup = "SF & SJ" if inlist(cbsacode, 41860, 41940)
	replace MSAgroup = "CHI" if cbsacode == 16980
	replace MSAgroup = "NY" if cbsacode == 35620
	replace MSAgroup = "DC" if inlist(cbsacode, 47900)
	replace MSAgroup = "LA" if cbsacode == 31080
	replace MSAgroup = "SD" if cbsacode == 41740
if `old_MSAs' == 0 {
	replace MSAgroup = "PHL" if cbsacode == 37980
	replace MSAgroup = "MIA" if cbsacode == 33100
	replace MSAgroup = "MN-SP" if cbsacode == 33460
	local folder ""
}
else {
	replace MSAgroup = "NHAV" if cbsacode == 35300
	replace MSAgroup = "SEA" if cbsacode == 42660
	replace MSAgroup = "DUR/CH" if cbsacode == 20500
	local folder "Plots - old Top MSAs/"
}	
	*replace MSAgroup = "Other" if cbsacode != . & MSAgroup == ""



preserve
	collapse (count) pmid, by(MSAgroup year nih pub lifesci)
	forval nih01 = 0/1 {
		forval pub01 = 0/1 {
		if (`nih01' == 1 & `pub01' == 0) == 0 {
			forval life01 = 0/1 {
				if `nih01' == 1 local ti "NIH"
				if `nih01' == 0 {
					local ti "Non-NIH"
					if `pub01' == 1 local ti "`ti' Publicly Funded"
					if `pub01' == 0 local ti "`ti' Privately Funded"
				}

				if `life01' == 1 local ti "`ti' Life Science Research"
				if `life01' == 0 local ti "`ti' Non-Life Science Research"

				#delimit ;
				graph bar (asis) pmid if inlist(year, 2005, 2010, 2015) & !inlist(MSAgroup, "", "Other") 
						& lifesci == `life01' & nih == `nih01' & pub == `pub01', 
					over(year, gap(5)) asyvars bar(1, col(green)) bar(2, col(eltblue)) bar(3, col(gold))
					over(MSAgroup, sort(msa_order)) yti("No. of Publications") legend(r(1))
					title("`ti'")  subtitle("(2005-2015)");
				graph export "`folder'pubs_byYr_byMSA_2005_life`life01'_nih`nih01'_pub`pub01'.png", replace as(png) wid(1600) hei(700);
				#delimit cr
			} // loop through life science/not life science
		} // don't bother if NIH and !public
		} // loop through public/private funding
	} // loop through NIH/non-NIH funding


	collapse (sum) pmid, by(MSAgroup year lifesci)

	forval life01 = 1/1 {
		if `life01' == 1 local ti "Total Research About Diseases"
		if `life01' == 0 local ti "Total Non-Life Science Research"

		#delimit ;
		tw ()

		graph bar (asis) pmid if inlist(year, 2005, 2010, 2015) & !inlist(MSAgroup, "", "Other") 
				& lifesci == `life01', 
			over(year, gap(5)) asyvars bar(1, col(green)) bar(2, col(eltblue)) bar(3, col(gold))
			over(MSAgroup, sort(msa_order)) yti("No. of Publications") legend(r(1))
			title("`ti'") subtitle("(2005-2015)");
		graph export "`folder'pubs_byYr_byMSA_2005_life`life01'.png", replace as(png) wid(1600) hei(700);
		#delimit cr
	}
restore


gen match_group = "TopMSA" if !inlist(MSAgroup, "", "Other")
replace match_group = "OtherMSA" if MSAgroup == "Other"
replace match_group = "NotMatched" if has_affl == 1 & cbsacode == . & inlist(country, "", "USA")

preserve
	collapse (count) pubs = pmid, by(match_group year lifesci nih pub)
	keep if match_group != ""

	reshape wide pubs, i(year lifesci nih pub) j(match_group) string 
	gen pubsOtherMSA_adj = pubsOtherMSA + pubsTopMSA
	gen pubsNotMatched_adj = pubsNotMatched + pubsOtherMSA + pubsTopMSA

	forval nih01 = 0/1 {
		forval pub01 = 0/1 {
		if (`nih01' == 1 & `pub01' == 0) == 0 {
			forval life01 = 0/1 {
				if `nih01' == 1 local ti "NIH-Funded"
				if `nih01' == 0 {
					local ti "Non-NIH"
					if `pub01' == 1 local ti "`ti' Publicly Funded"
					if `pub01' == 0 local ti "`ti' Privately Funded"
				}

				if `life01' == 1 local ti "`ti' Life Science Research"
				if `life01' == 0 local ti "`ti' Non-Life Science Research"

				#delimit ;
				tw (area pubsNotMatched_adj year if lifesci == `life01' & nih == `nih01' & pub == `pub01', col(gs8))
				   (area pubsOtherMSA_adj year if lifesci == `life01' & nih == `nih01' & pub == `pub01', col(navy))
				   (area pubsTopMSA year if lifesci == `life01' & nih == `nih01' & pub == `pub01', col(cranberry)),
				 legend(order(1 "Have Affiliations but Not Matched to MSA Codes"
				 			  2 "Matched to MSA Codes Other than Top 10"
				 			  3 "Matched to BOS, CHI, DC, DUR/CH, LA, NHAV, NY, SD, SEA, or SF/SJ")
				 		c(1))
				 title("`ti'") subtitle("(2005-2018)") yti("No. of Publications");
				graph export "`folder'pubs_ts_byMatched_2005_life`life01'_nih`nih01'_pub`pub01'.png",
					replace as(png) wid(1600) hei(700);
				#delimit cr
			} // loop through life science/not life science
		} // don't bother if NIH and !public
		} // loop through public/private funding
	} // loop through NIH/non-NIH funding

	collapse (sum) pubs*, by(year lifesci)
	forval life01 = 0/1 {
		if `life01' == 1 local ti "Total Life Science Research"
		if `life01' == 0 local ti "Total Non-Life Science Research"

		#delimit ;
		tw (area pubsNotMatched_adj year if lifesci == `life01', col(gs8))
		   (area pubsOtherMSA_adj year if lifesci == `life01', col(navy))
		   (area pubsTopMSA year if lifesci == `life01', col(cranberry)),
		 legend(order(1 "Have Affiliations but Not Matched to MSA Codes"
		 			  2 "Matched to MSA Codes Other than Top 10"
		 			  3 "Matched to BOS, CHI, DC, DUR/CH, LA, NHAV, NY, SD, SEA, or SF/SJ")
		 		c(1))
		 title("`ti'") subtitle("(2005-2018)") yti("No. of Publications");
		graph export "`folder'pubs_ts_byMatched_2005_life`life01'.png", replace as(png) wid(1600) hei(700);
		#delimit cr
	}
*---------------------------
}
*---------------------------

*---------------------------
if `plots_bydis' == 1 {
*---------------------------
foreach ct_not in "" /*"clintr_"*/ {
	foreach QA in /*""*/ "fullQA_" /*"notQA_"*/ {
		if "`QA'" != "fullQA_" {
			use "Master_dta/pmids_`ct_not'`QA'bydisease.dta", clear
			drop query_name query
			tempfile pmids
			save `pmids', replace

			use clean_auth_affls_master.dta, clear
		}

		if "`QA'" == "fullQA_" {
			use "Master_dta/pmids_`ct_not'bydisease.dta", clear
			drop query_name query
			tempfile pmids
			save `pmids', replace

			use clean_auth_affls.dta, clear
		}

		merge 1:m pmid using `pmids', keep(2 3) nogen
		egen tagged = tag(pmid)

		gen has_affl = affl != ""
		gen usa = has_affl & inlist(country, "", "USA")

		preserve
			#delimit ;
			keep if tagged;
			collapse (count) Total = pmid
					 (sum) w_Affiliation = has_affl 
					 (sum) USA = usa
					 (count) Final = cbsacode, by(year);
			#delimit cr
			sort year
			export delimited sample`ext'_1pct_byYr_1-2-2020.csv, replace
		restore

		preserve
			keep if tagged
			collapse (sum) USA = usa (count) final = cbsacode, by(year)
			gen coverage = final/USA * 100
			#delimit ;
			tw (line coverage year, lc(green) lp(l)),
			 legend(off)
			 yti("Share of US Publications with Found MSA Code (%)")
			 xti("Year");
			#delimit cr
			graph export coverage`ext'_samp1pct_1-2-2020.png, as(png) replace wid(1200) hei(700)
		restore

		gen MSAgroup = "BOS" if cbsacode == 14460
			replace MSAgroup = "SF & SJ" if inlist(cbsacode, 41860, 41940)
			replace MSAgroup = "CHI" if cbsacode == 16980
			replace MSAgroup = "NY" if cbsacode == 35620
			replace MSAgroup = "DC" if inlist(cbsacode, 47900)
			replace MSAgroup = "LA" if cbsacode == 31080
			replace MSAgroup = "SD" if cbsacode == 41740
		if `old_MSAs' == 0 {
			replace MSAgroup = "PHL" if cbsacode == 37980
			replace MSAgroup = "MIA" if cbsacode == 33100
			replace MSAgroup = "MN-SP" if cbsacode == 33460
			local folder ""
		}
		else {
			replace MSAgroup = "NHAV" if cbsacode == 35300
			replace MSAgroup = "SEA" if cbsacode == 42660
			replace MSAgroup = "DUR/CH" if cbsacode == 20500
			local folder "Plots - old Top MSAs/"
		}	
			replace MSAgroup = "Other" if cbsacode != . & MSAgroup == ""


		if "`ct_not'" == "clintr_" local yvar "Clinical Trial (II & III) Publications"
		else local yvar "Non-Trial Publications"

		if "`QA'" == "" local journals "Top 13 Journals, Based on 1% Sample"
		if "`QA'" == "notQA_" local journals "All Journals, Based on 1% Sample"
		if "`QA'" == "fullQA_" local journals "Top 13 Journals, Full Sample"

		levelsof dis_abbr, local(diseases)
		gen decade = 10*int(year/10)

		preserve
			keep if has_affl
			collapse (count) pmid, by(MSAgroup decade nih dis_abbr)
			foreach dis of local diseases {
				forval nih01 = 0/1 {
					if `nih01' == 1 local ti "NIH-Funded"
					if `nih01' == 0 local ti "Non-NIH-Funded"

					if "`dis'" == "Cardio" local dis_name "Cardiovascular Diseases"
					if "`dis'" == "ChronicResp" local dis_name "Chronic Respiratory Diseases"
					if "`dis'" == "Kidney" local dis_name "Diabetes and Kidney Diseases"
					if "`dis'" == "Digestive" local dis_name "Digestive Diseases"
					if "`dis'" == "Enteritis" local dis_name "Enteric Infections"
					if "`dis'" == "STIs" local dis_name "HIV/AIDS and other STIs"
					if "`dis'" == "Pregnancy" local dis_name "Maternal and Neonatal Disorders"
					if "`dis'" == "Mental" local dis_name "Mental Disorders"
					if "`dis'" == "Muscle" local dis_name "Musculoskeletal Disorders"
					if "`dis'" == "Tropic" local dis_name "Neglected Tropical Diseases and Malaria"
					if "`dis'" == "Neoplasms" local dis_name "Neoplasms (includes Cancer)"
					if "`dis'" == "Neurologic" local dis_name "Neurological Disorders"
					if "`dis'" == "Nutrition" local dis_name "Nutritional Deficiencies"
					if "`dis'" == "OthInfectious" local dis_name "Other Infectious Diseases"
					if "`dis'" == "RespInf" local dis_name "Respiratory Infections and Tuberculosis"
					if "`dis'" == "Senses" local dis_name "Sense Organ Diseases"
					if "`dis'" == "Skin" local dis_name "Skin and Subcutaneous Diseases"
					if "`dis'" == "Substance" local dis_name "Substance Use Disorders"

					#delimit ;
					cap noisily graph bar (asis) pmid if inlist(decade, 1990, 2000, 2010) & !inlist(MSAgroup, "", "Other") 
							& dis_abbr == "`dis'" & nih == `nih01', 
						over(decade, gap(5)) asyvars bar(1, col(green)) bar(2, col(eltblue)) bar(3, col(gold))
						over(MSAgroup) yti("No. of `yvar'") legend(r(1))
					title("`ti' Research About" "`dis_name'") subtitle("(`journals')")
					legend(order(1 "1990s" 2 "2000s" 3 "2010s"));
					cap noisily graph save "gphs/pubs`ext'_`ct_not'`QA'byDec_byMSA_`dis'_nih`nih01'.gph", replace;
					cap noisily graph export "pubs`ext'_`ct_not'`QA'byDec_byMSA_`dis'_nih`nih01'.png",
						replace as(png) wid(1600) hei(700);
					#delimit cr
					*pause
				} // nih loop

				#delimit ;
				grc1leg "gphs/pubs`ext'_`ct_not'`QA'byDec_byMSA_`dis'_nih1.gph"
						"gphs/pubs`ext'_`ct_not'`QA'byDec_byMSA_`dis'_nih0.gph",
					legendfrom("gphs/pubs`ext'_`ct_not'`QA'byDec_byMSA_`dis'_nih0.gph")
					xcommon c(1);
				graph export "pubs`ext'_`ct_not'`QA'byDec_byMSA_`dis'_combined.png",
					replace as(png) wid(1600) hei(1400);
				#delimit cr

			} // disease loop

			collapse (sum) pmid, by(MSAgroup decade dis_abbr)
			foreach dis of local diseases {
				if "`dis'" == "Cardio" local dis_name "Cardiovascular Diseases"
				if "`dis'" == "ChronicResp" local dis_name "Chronic Respiratory Diseases"
				if "`dis'" == "Kidney" local dis_name "Diabetes and Kidney Diseases"
				if "`dis'" == "Digestive" local dis_name "Digestive Diseases"
				if "`dis'" == "Enteritis" local dis_name "Enteric Infections"
				if "`dis'" == "STIs" local dis_name "HIV/AIDS and other STIs"
				if "`dis'" == "Pregnancy" local dis_name "Maternal and Neonatal Disorders"
				if "`dis'" == "Mental" local dis_name "Mental Disorders"
				if "`dis'" == "Muscle" local dis_name "Musculoskeletal Disorders"
				if "`dis'" == "Tropic" local dis_name "Neglected Tropical Diseases and Malaria"
				if "`dis'" == "Neoplasms" local dis_name "Neoplasms (includes Cancer)"
				if "`dis'" == "Neurologic" local dis_name "Neurological Disorders"
				if "`dis'" == "Nutrition" local dis_name "Nutritional Deficiencies"
				if "`dis'" == "OthInfectious" local dis_name "Other Infectious Diseases"
				if "`dis'" == "RespInf" local dis_name "Respiratory Infections and Tuberculosis"
				if "`dis'" == "Senses" local dis_name "Sense Organ Diseases"
				if "`dis'" == "Skin" local dis_name "Skin and Subcutaneous Diseases"
				if "`dis'" == "Substance" local dis_name "Substance Use Disorders"

				#delimit ;
				cap noisily graph bar (asis) pmid if inlist(decade,1990, 2000, 2010) & !inlist(MSAgroup, "", "Other") 
						& dis_abbr == "`dis'", 
					over(decade, gap(5)) asyvars bar(1, col(green)) bar(2, col(eltblue)) bar(3, col(gold))
					over(MSAgroup, sort(msa_order)) yti("No. of `yvar'") legend(r(1))
					title("Research About" "`dis_name'") subtitle("(`journals')")
					legend(order(1 "1990s" 2 "2000s" 3 "2010s"));
				cap noisily graph save "gphs/pubs`ext'_`ct_not'`QA'byDec_byMSA_`dis'.gph", replace;
				cap noisily graph export "pubs`ext'_`ct_not'`QA'byDec_byMSA_`dis'.png", replace as(png) wid(1600) hei(700);
				#delimit cr
			}
		restore

		gen match_group = "TopMSA" if !inlist(MSAgroup, "", "Other")
		replace match_group = "OtherMSA" if MSAgroup == "Other"
		replace match_group = "NotMatched" if has_affl == 1 & cbsacode == . & inlist(country, "", "USA")

		preserve
			collapse (count) pubs = pmid, by(match_group year dis_abbr nih)
			keep if match_group != ""

			reshape wide pubs, i(year dis_abbr nih) j(match_group) string
				sort year dis_abbr nih
				export delimited "pubs`ext'_ts_byMatched.csv", replace
			gen pubsOtherMSA_adj = pubsOtherMSA + pubsTopMSA
			gen pubsNotMatched_adj = pubsNotMatched + pubsOtherMSA + pubsTopMSA

			forval nih01 = 0/1 {
				foreach dis of local diseases {
					if `nih01' == 1 local ti "NIH-Funded"
					if `nih01' == 0 local ti "Non-NIH-Funded"

					if "`dis'" == "Cardio" local dis_name "Cardiovascular Diseases"
					if "`dis'" == "ChronicResp" local dis_name "Chronic Respiratory Diseases"
					if "`dis'" == "Kidney" local dis_name "Diabetes and Kidney Diseases"
					if "`dis'" == "Digestive" local dis_name "Digestive Diseases"
					if "`dis'" == "Enteritis" local dis_name "Enteric Infections"
					if "`dis'" == "STIs" local dis_name "HIV/AIDS and other STIs"
					if "`dis'" == "Pregnancy" local dis_name "Maternal and Neonatal Disorders"
					if "`dis'" == "Mental" local dis_name "Mental Disorders"
					if "`dis'" == "Muscle" local dis_name "Musculoskeletal Disorders"
					if "`dis'" == "Tropic" local dis_name "Neglected Tropical Diseases and Malaria"
					if "`dis'" == "Neoplasms" local dis_name "Neoplasms (includes Cancer)"
					if "`dis'" == "Neurologic" local dis_name "Neurological Disorders"
					if "`dis'" == "Nutrition" local dis_name "Nutritional Deficiencies"
					if "`dis'" == "OthInfectious" local dis_name "Other Infectious Diseases"
					if "`dis'" == "RespInf" local dis_name "Respiratory Infections and Tuberculosis"
					if "`dis'" == "Senses" local dis_name "Sense Organ Diseases"
					if "`dis'" == "Skin" local dis_name "Skin and Subcutaneous Diseases"
					if "`dis'" == "Substance" local dis_name "Substance Use Disorders"

					#delimit ;
					tw (area pubsNotMatched_adj year if dis_abbr == "`dis'" & nih == `nih01', col(gs8))
					   (area pubsOtherMSA_adj year if dis_abbr == "`dis'" & nih == `nih01', col(navy))
					   (area pubsTopMSA year if dis_abbr == "`dis'" & nih == `nih01', col(cranberry)),
					 legend(order(1 "Have Affiliations but Not Matched to MSA Codes"
					 			  2 "Matched to MSA Codes Other than Top 10"
					 			  3 "Matched to BOS, CHI, DC, LA, MIA, MN-SP, NY, PHL, SD, or SF/SJ")
					 		c(1))
					 title("`ti' Research About" "`dis_name'") subtitle("(`journals')")
					 yti("No. of `yvar'");
					graph export "pubs`ext'_ts_`ct_not'`QA'byMatched_`dis'_nih`nih01'.png", replace as(png) wid(1600) hei(700);
					#delimit cr
				}
			}

			collapse (sum) pubs*, by(year dis_abbr)
			foreach dis of local diseases {
				if "`dis'" == "Cardio" local dis_name "Cardiovascular Diseases"
				if "`dis'" == "ChronicResp" local dis_name "Chronic Respiratory Diseases"
				if "`dis'" == "Kidney" local dis_name "Diabetes and Kidney Diseases"
				if "`dis'" == "Digestive" local dis_name "Digestive Diseases"
				if "`dis'" == "Enteritis" local dis_name "Enteric Infections"
				if "`dis'" == "STIs" local dis_name "HIV/AIDS and other STIs"
				if "`dis'" == "Pregnancy" local dis_name "Maternal and Neonatal Disorders"
				if "`dis'" == "Mental" local dis_name "Mental Disorders"
				if "`dis'" == "Muscle" local dis_name "Musculoskeletal Disorders"
				if "`dis'" == "Tropic" local dis_name "Neglected Tropical Diseases and Malaria"
				if "`dis'" == "Neoplasms" local dis_name "Neoplasms (includes Cancer)"
				if "`dis'" == "Neurologic" local dis_name "Neurological Disorders"
				if "`dis'" == "Nutrition" local dis_name "Nutritional Deficiencies"
				if "`dis'" == "OthInfectious" local dis_name "Other Infectious Diseases"
				if "`dis'" == "RespInf" local dis_name "Respiratory Infections and Tuberculosis"
				if "`dis'" == "Senses" local dis_name "Sense Organ Diseases"
				if "`dis'" == "Skin" local dis_name "Skin and Subcutaneous Diseases"
				if "`dis'" == "Substance" local dis_name "Substance Use Disorders"

				#delimit ;
				tw (area pubsNotMatched_adj year if dis == "`dis'", col(gs8))
				   (area pubsOtherMSA_adj year if dis == "`dis'", col(navy))
				   (area pubsTopMSA year if dis == "`dis'", col(cranberry)),
				 legend(order(1 "Have Affiliations but Not Matched to MSA Codes"
				 			  2 "Matched to MSA Codes Other than Top 10"
				 			  3 "Matched to BOS, CHI, DC, LA, MIA, MN-SP, NY, PHL, SD, or SF/SJ")
				 		c(1))
				 title("Research About `dis_name'") subtitle("(`journals')")
				 yti("No. of `yvar'");
				graph save "gphs/pubs`ext'_ts_`ct_not'`QA'byMatched_`dis'.gph", replace;
				graph export "pubs`ext'_ts_`ct_not'`QA'byMatched_`dis'.png", replace as(png) wid(1200) hei(700);

				cap noisily graph combine "gphs/pubs`ext'_`ct_not'`QA'byDec_byMSA_`dis'.gph"
								"gphs/pubs`ext'_ts_`ct_not'`QA'byMatched_`dis'.gph", c(1);
				cap noisily graph export "pubs`ext'_bar_and_ts_combined_`dis'.png",
					replace as(png) wid(1600) hei(1400);

				#delimit cr
			}

			collapse (sum) pubs*, by(year)
			#delimit ;
				tw (area pubsNotMatched_adj year, col(gs8))
				   (area pubsOtherMSA_adj year, col(navy))
				   (area pubsTopMSA year, col(cranberry)),
				 legend(order(1 "Have Affiliations but Not Matched to MSA Codes"
				 			  2 "Matched to MSA Codes Other than Top 10"
				 			  3 "Matched to BOS, CHI, DC, LA, MIA, MN-SP, NY, PHL, SD, or SF/SJ")
				 		c(1))
				 title("Total `ti'") subtitle("(`journals')")
				 yti("No. of `yvar'");
				graph export "pubs`ext'_ts_`ct_not'`QA'byMatched.png", replace as(png) wid(1600) hei(700);
			#delimit cr

				export delimited "pubs`ext'_ts_`ct_not'`QA'byMatched.csv", replace
		restore

	} // end `QA' loop

} // end `ct_not' loop

*---------------------------
} // end plots by disease by MSA
*---------------------------

*---------------------------
if `plots_bydiscipline' == 1 {
*---------------------------
use "Master_dta/pmids_bydiscipline.dta", clear
	drop query_name query
	replace discipline = "Mult" if substr(discipline, 1, 7) == "MandBCP"
tempfile pmids
save `pmids', replace

use clean_auth_affls.dta, clear

merge 1:m pmid using `pmids', keep(2 3) nogen
egen tagged = tag(pmid)

gen has_affl = affl != ""
gen usa = has_affl & inlist(country, "", "USA")

gen MSAgroup = "BOS" if cbsacode == 14460
	replace MSAgroup = "SF & SJ" if inlist(cbsacode, 41860, 41940)
	replace MSAgroup = "CHI" if cbsacode == 16980
	replace MSAgroup = "NY" if cbsacode == 35620
	replace MSAgroup = "DC" if inlist(cbsacode, 47900)
	replace MSAgroup = "LA" if cbsacode == 31080
	replace MSAgroup = "SD" if cbsacode == 41740
if `old_MSAs' == 0 {
	replace MSAgroup = "PHL" if cbsacode == 37980
	replace MSAgroup = "MIA" if cbsacode == 33100
	replace MSAgroup = "MN-SP" if cbsacode == 33460
	local folder ""
}
else {
	replace MSAgroup = "NHAV" if cbsacode == 35300
	replace MSAgroup = "SEA" if cbsacode == 42660
	replace MSAgroup = "DUR/CH" if cbsacode == 20500
	local folder "Plots - old Top MSAs/"
}	
	replace MSAgroup = "Other" if cbsacode != . & MSAgroup == ""


local yvar "Total Publications"
local journals "Top 13 Journals, Full Sample"

levelsof discipline, local(disciplines)
gen decade = 10*int(year/10)

preserve
	keep if has_affl
	collapse (count) pmid, by(MSAgroup decade nih discipline)
	foreach dis of local disciplines {
		forval nih01 = 0/1 {
			if `nih01' == 1 local ti "NIH-Funded"
			if `nih01' == 0 local ti "Non-NIH-Funded"

			if "`dis'" == "Bio" local dis_name "About Biological Phenomena Only"
			if "`dis'" == "Chem" local dis_name "About Chemical Phenomena Only"
			if "`dis'" == "Phys" local dis_name "About Physical Phenomena Only"
			if "`dis'" == "Dis" local dis_name "About Diseases"
			if "`dis'" == "Mech" local dis_name "About Disease Mechanisms"
			if "`dis'" == "Mult" local dis_name "About "
			if "`dis'" == "Total" local dis_name ""
			
			#delimit ;
			cap noisily graph bar (asis) pmid if inlist(decade, 1990, 2000, 2010) & !inlist(MSAgroup, "", "Other") 
					& dis_abbr == "`dis'" & nih == `nih01', 
				over(decade, gap(5)) asyvars bar(1, col(green)) bar(2, col(eltblue)) bar(3, col(gold))
				over(MSAgroup) yti("No. of `yvar'") legend(r(1))
			title("`ti' Publications" "`dis_name'") subtitle("(`journals')")
			legend(order(1 "1990s" 2 "2000s" 3 "2010s"));
			cap noisily graph save "gphs/pubs`ext'_`ct_not'`QA'byDec_byMSA_`dis'_nih`nih01'.gph", replace;
			cap noisily graph export "pubs`ext'_`ct_not'`QA'byDec_byMSA_`dis'_nih`nih01'.png",
				replace as(png) wid(1600) hei(700);
			#delimit cr
			*pause
		} // nih loop

		#delimit ;
		grc1leg "gphs/pubs`ext'_`ct_not'`QA'byDec_byMSA_`dis'_nih1.gph"
				"gphs/pubs`ext'_`ct_not'`QA'byDec_byMSA_`dis'_nih0.gph",
			legendfrom("gphs/pubs`ext'_`ct_not'`QA'byDec_byMSA_`dis'_nih0.gph")
			xcommon c(1);
		graph export "pubs`ext'_`ct_not'`QA'byDec_byMSA_`dis'_combined.png",
			replace as(png) wid(1600) hei(1400);
		#delimit cr

	} // disease loop

	collapse (sum) pmid, by(MSAgroup decade dis_abbr)
	foreach dis of local diseases {
		if "`dis'" == "Cardio" local dis_name "Cardiovascular Diseases"
		if "`dis'" == "ChronicResp" local dis_name "Chronic Respiratory Diseases"
		if "`dis'" == "Kidney" local dis_name "Diabetes and Kidney Diseases"
		if "`dis'" == "Digestive" local dis_name "Digestive Diseases"
		if "`dis'" == "Enteritis" local dis_name "Enteric Infections"
		if "`dis'" == "STIs" local dis_name "HIV/AIDS and other STIs"
		if "`dis'" == "Pregnancy" local dis_name "Maternal and Neonatal Disorders"
		if "`dis'" == "Mental" local dis_name "Mental Disorders"
		if "`dis'" == "Muscle" local dis_name "Musculoskeletal Disorders"
		if "`dis'" == "Tropic" local dis_name "Neglected Tropical Diseases and Malaria"
		if "`dis'" == "Neoplasms" local dis_name "Neoplasms (includes Cancer)"
		if "`dis'" == "Neurologic" local dis_name "Neurological Disorders"
		if "`dis'" == "Nutrition" local dis_name "Nutritional Deficiencies"
		if "`dis'" == "OthInfectious" local dis_name "Other Infectious Diseases"
		if "`dis'" == "RespInf" local dis_name "Respiratory Infections and Tuberculosis"
		if "`dis'" == "Senses" local dis_name "Sense Organ Diseases"
		if "`dis'" == "Skin" local dis_name "Skin and Subcutaneous Diseases"
		if "`dis'" == "Substance" local dis_name "Substance Use Disorders"

		#delimit ;
		cap noisily graph bar (asis) pmid if inlist(decade,1990, 2000, 2010) & !inlist(MSAgroup, "", "Other") 
				& dis_abbr == "`dis'", 
			over(decade, gap(5)) asyvars bar(1, col(green)) bar(2, col(eltblue)) bar(3, col(gold))
			over(MSAgroup, sort(msa_order)) yti("No. of `yvar'") legend(r(1))
			title("Research About" "`dis_name'") subtitle("(`journals')")
			legend(order(1 "1990s" 2 "2000s" 3 "2010s"));
		cap noisily graph save "gphs/pubs`ext'_`ct_not'`QA'byDec_byMSA_`dis'.gph", replace;
		cap noisily graph export "pubs`ext'_`ct_not'`QA'byDec_byMSA_`dis'.png", replace as(png) wid(1600) hei(700);
		#delimit cr
	}
restore

gen match_group = "TopMSA" if !inlist(MSAgroup, "", "Other")
replace match_group = "OtherMSA" if MSAgroup == "Other"
replace match_group = "NotMatched" if has_affl == 1 & cbsacode == . & inlist(country, "", "USA")

preserve
	collapse (count) pubs = pmid, by(match_group year dis_abbr nih)
	keep if match_group != ""

	reshape wide pubs, i(year dis_abbr nih) j(match_group) string
		sort year dis_abbr nih
		export delimited "pubs`ext'_ts_byMatched.csv", replace
	gen pubsOtherMSA_adj = pubsOtherMSA + pubsTopMSA
	gen pubsNotMatched_adj = pubsNotMatched + pubsOtherMSA + pubsTopMSA

	forval nih01 = 0/1 {
		foreach dis of local diseases {
			if `nih01' == 1 local ti "NIH-Funded"
			if `nih01' == 0 local ti "Non-NIH-Funded"

			if "`dis'" == "Cardio" local dis_name "Cardiovascular Diseases"
			if "`dis'" == "ChronicResp" local dis_name "Chronic Respiratory Diseases"
			if "`dis'" == "Kidney" local dis_name "Diabetes and Kidney Diseases"
			if "`dis'" == "Digestive" local dis_name "Digestive Diseases"
			if "`dis'" == "Enteritis" local dis_name "Enteric Infections"
			if "`dis'" == "STIs" local dis_name "HIV/AIDS and other STIs"
			if "`dis'" == "Pregnancy" local dis_name "Maternal and Neonatal Disorders"
			if "`dis'" == "Mental" local dis_name "Mental Disorders"
			if "`dis'" == "Muscle" local dis_name "Musculoskeletal Disorders"
			if "`dis'" == "Tropic" local dis_name "Neglected Tropical Diseases and Malaria"
			if "`dis'" == "Neoplasms" local dis_name "Neoplasms (includes Cancer)"
			if "`dis'" == "Neurologic" local dis_name "Neurological Disorders"
			if "`dis'" == "Nutrition" local dis_name "Nutritional Deficiencies"
			if "`dis'" == "OthInfectious" local dis_name "Other Infectious Diseases"
			if "`dis'" == "RespInf" local dis_name "Respiratory Infections and Tuberculosis"
			if "`dis'" == "Senses" local dis_name "Sense Organ Diseases"
			if "`dis'" == "Skin" local dis_name "Skin and Subcutaneous Diseases"
			if "`dis'" == "Substance" local dis_name "Substance Use Disorders"

			#delimit ;
			tw (area pubsNotMatched_adj year if dis_abbr == "`dis'" & nih == `nih01', col(gs8))
			   (area pubsOtherMSA_adj year if dis_abbr == "`dis'" & nih == `nih01', col(navy))
			   (area pubsTopMSA year if dis_abbr == "`dis'" & nih == `nih01', col(cranberry)),
			 legend(order(1 "Have Affiliations but Not Matched to MSA Codes"
			 			  2 "Matched to MSA Codes Other than Top 10"
			 			  3 "Matched to BOS, CHI, DC, LA, MIA, MN-SP, NY, PHL, SD, or SF/SJ")
			 		c(1))
			 title("`ti' Research About" "`dis_name'") subtitle("(`journals')")
			 yti("No. of `yvar'");
			graph export "pubs`ext'_ts_`ct_not'`QA'byMatched_`dis'_nih`nih01'.png", replace as(png) wid(1600) hei(700);
			#delimit cr
		}
	}

	collapse (sum) pubs*, by(year dis_abbr)
	foreach dis of local diseases {
		if "`dis'" == "Cardio" local dis_name "Cardiovascular Diseases"
		if "`dis'" == "ChronicResp" local dis_name "Chronic Respiratory Diseases"
		if "`dis'" == "Kidney" local dis_name "Diabetes and Kidney Diseases"
		if "`dis'" == "Digestive" local dis_name "Digestive Diseases"
		if "`dis'" == "Enteritis" local dis_name "Enteric Infections"
		if "`dis'" == "STIs" local dis_name "HIV/AIDS and other STIs"
		if "`dis'" == "Pregnancy" local dis_name "Maternal and Neonatal Disorders"
		if "`dis'" == "Mental" local dis_name "Mental Disorders"
		if "`dis'" == "Muscle" local dis_name "Musculoskeletal Disorders"
		if "`dis'" == "Tropic" local dis_name "Neglected Tropical Diseases and Malaria"
		if "`dis'" == "Neoplasms" local dis_name "Neoplasms (includes Cancer)"
		if "`dis'" == "Neurologic" local dis_name "Neurological Disorders"
		if "`dis'" == "Nutrition" local dis_name "Nutritional Deficiencies"
		if "`dis'" == "OthInfectious" local dis_name "Other Infectious Diseases"
		if "`dis'" == "RespInf" local dis_name "Respiratory Infections and Tuberculosis"
		if "`dis'" == "Senses" local dis_name "Sense Organ Diseases"
		if "`dis'" == "Skin" local dis_name "Skin and Subcutaneous Diseases"
		if "`dis'" == "Substance" local dis_name "Substance Use Disorders"

		#delimit ;
		tw (area pubsNotMatched_adj year if dis == "`dis'", col(gs8))
		   (area pubsOtherMSA_adj year if dis == "`dis'", col(navy))
		   (area pubsTopMSA year if dis == "`dis'", col(cranberry)),
		 legend(order(1 "Have Affiliations but Not Matched to MSA Codes"
		 			  2 "Matched to MSA Codes Other than Top 10"
		 			  3 "Matched to BOS, CHI, DC, LA, MIA, MN-SP, NY, PHL, SD, or SF/SJ")
		 		c(1))
		 title("Research About `dis_name'") subtitle("(`journals')")
		 yti("No. of `yvar'");
		graph save "gphs/pubs`ext'_ts_`ct_not'`QA'byMatched_`dis'.gph", replace;
		graph export "pubs`ext'_ts_`ct_not'`QA'byMatched_`dis'.png", replace as(png) wid(1200) hei(700);

		cap noisily graph combine "gphs/pubs`ext'_`ct_not'`QA'byDec_byMSA_`dis'.gph"
						"gphs/pubs`ext'_ts_`ct_not'`QA'byMatched_`dis'.gph", c(1);
		cap noisily graph export "pubs`ext'_bar_and_ts_combined_`dis'.png",
			replace as(png) wid(1600) hei(1400);

		#delimit cr
	}

	collapse (sum) pubs*, by(year)
	#delimit ;
		tw (area pubsNotMatched_adj year, col(gs8))
		   (area pubsOtherMSA_adj year, col(navy))
		   (area pubsTopMSA year, col(cranberry)),
		 legend(order(1 "Have Affiliations but Not Matched to MSA Codes"
		 			  2 "Matched to MSA Codes Other than Top 10"
		 			  3 "Matched to BOS, CHI, DC, LA, MIA, MN-SP, NY, PHL, SD, or SF/SJ")
		 		c(1))
		 title("Total `ti'") subtitle("(`journals')")
		 yti("No. of `yvar'");
		graph export "pubs`ext'_ts_`ct_not'`QA'byMatched.png", replace as(png) wid(1600) hei(700);
	#delimit cr

		export delimited "pubs`ext'_ts_`ct_not'`QA'byMatched.csv", replace
restore

*---------------------------
} // end plots by discipline by MSA
*---------------------------



*---------------------------
if `non_us' == 1 {
*---------------------------
use affls_master.dta, clear

gen has_affl = affl != ""
gen has_country = country != ""

preserve
	#delimit ;
	collapse (count) Total = pmid
			 (sum) w_Affiliation = has_affl w_Country = has_country, by(year);
	#delimit cr
	sort year
	export delimited sample_wCountry_byYr_10-7-2019.csv, replace
restore

preserve
	collapse (sum) w_Affiliation = has_affl w_Country = has_country, by(year lifesci)
	gen coverage = w_Country/w_Affiliation * 100
	#delimit ;
	tw (line coverage year if lifesci, lc(green) lp(l))
	   (line coverage year if !lifesci, lc(navy) lp(l)),
	 legend(order(1 "Life Science" 2 "Non-Life Science"))
	 yti("Share of Publications with Matched Country (%)")
	 xti("Year");
	#delimit cr
	graph export coverage_wCountry_10-7-19.png, as(png) replace wid(1200) hei(700)
restore

replace country = "UK" if country == "United Kingdom"
preserve
	drop if country == ""
	collapse (count) pubs = pmid, by(country)
	egen rank = rank(pubs), field
	tempfile country_ranks
	save `country_ranks', replace
restore

preserve
	collapse (count) pmid, by(country year nih lifesci)
		merge m:1 country using `country_ranks', nogen keep(1 3) keepus(rank)
		keep if inrange(rank, 2, 11)
		gen country_abbr = substr(country, 1, 3) + "." if strlen(country) > 3
			replace country_abbr = country if strlen(country) <= 3
	
	forval nih01 = 0/1 {
		forval life01 = 0/1 {
			if `nih01' == 1 local ti "NIH-Funded"
			if `nih01' == 0 local ti "Non-NIH-Funded"

			if `life01' == 1 local ti "`ti' Life Science Research"
			if `life01' == 0 local ti "`ti' Non-Life Science Research"

			#delimit ;
			graph bar (asis) pmid if inlist(year, 1990, 2000, 2010)
					& lifesci == `life01' & nih == `nih01', 
				over(year, gap(5)) asyvars bar(1, col(green)) bar(2, col(eltblue)) bar(3, col(gold))
				over(country_abbr) yti("No. of Publications") legend(r(1))
			title("`ti'")   subtitle("(1990-2010)");
			graph export "pubs_byYr_byCountry_life`life01'_nih`nih01'.png", replace as(png) wid(1600) hei(700);
			#delimit cr
		}
	}
	collapse (sum) pmid, by(country country_abbr year lifesci)
		merge m:1 country using `country_ranks', nogen keep(1 3) keepus(rank)
		keep if inrange(rank, 2, 11)
	forval life01 = 0/1 {
		if `life01' == 1 local ti "Total Life Science Research"
		if `life01' == 0 local ti "Total Non-Life Science Research"

		#delimit ;
		graph bar (asis) pmid if inlist(year, 1990, 2000, 2010)
				& lifesci == `life01', 
			over(year, gap(5)) asyvars bar(1, col(green)) bar(2, col(eltblue)) bar(3, col(gold))
			over(country_abbr) yti("No. of Publications") legend(r(1))
			title("`ti'")   subtitle("(1990-2010)");
		graph export "pubs_byYr_byCountry_life`life01'.png", replace as(png) wid(1600) hei(700);
		#delimit cr
	}
restore

merge m:1 country using `country_ranks', nogen keep(1 3) keepus(rank)

gen match_group = "USA" if country == "USA"
replace match_group = "Top" if inrange(rank, 2, 11)
replace match_group = "Other" if rank > 11
replace match_group = "NotMatched" if has_affl == 1 & country == ""

preserve
	collapse (count) pubs = pmid, by(match_group year lifesci nih)
	keep if match_group != ""

	reshape wide pubs, i(year lifesci nih) j(match_group) string
		replace pubsNotMatched = 0 if pubsNotMatched == .
	gen pubsTop_adj = pubsTop + pubsUSA
	gen pubsOther_adj = pubsOther + pubsTop + pubsUSA
	gen pubsNotMatched_adj = pubsNotMatched + pubsOther + pubsTop + pubsUSA

	forval nih01 = 0/1 {
		forval life01 = 0/1 {
			if `nih01' == 1 local ti "NIH-Funded"
			if `nih01' == 0 local ti "Non-NIH-Funded"

			if `life01' == 1 local ti "`ti' Life Science Research"
			if `life01' == 0 local ti "`ti' Non-Life Science Research"

			#delimit ;
			tw (area pubsNotMatched_adj year if lifesci == `life01' & nih == `nih01', col(gs8))
			   (area pubsOther_adj year if lifesci == `life01' & nih == `nih01', col(navy))
			   (area pubsTop_adj year if lifesci == `life01' & nih == `nih01', col(dkorange))
			   (area pubsUSA year if lifesci == `life01' & nih == `nih01', col(cranberry)),
			 legend(order(1 "Have Affiliations but Not Matched to Country"
			 			  2 "Matched to Countries Other than Top 10"
			 			  3 "Matched to UK, Ger., Fr., Can., Neth., Sw., Jap., Aus., Ch., Ita. "
			 		 	  4 "Matched to USA")
			 		c(1))
			 title("`ti'") subtitle("(1988-2018)") yti("No. of Publications");
			graph export "pubs_ts_byMatchedCountry_life`life01'_nih`nih01'.png", replace as(png) wid(1600) hei(700);
			#delimit cr
		}
	}

	collapse (sum) pubs*, by(year lifesci)
	forval life01 = 0/1 {
		if `life01' == 1 local ti "Total Life Science Research"
		if `life01' == 0 local ti "Total Non-Life Science Research"

		#delimit ;
		tw (area pubsNotMatched_adj year if lifesci == `life01', col(gs8))
			   (area pubsOther_adj year if lifesci == `life01', col(navy))
			   (area pubsTop_adj year if lifesci == `life01', col(dkorange))
			   (area pubsUSA year if lifesci == `life01', col(cranberry)),
		 legend(order(1 "Have Affiliations but Not Matched to Country"
			 		  2 "Matched to Countries Other than Top 10"
			 		  3 "Matched to UK, Ger., Fr., Can., Neth., Sw., Jap., Aus., Ch., Ita. "
			 		  4 "Matched to USA")
		 		c(1))
		 title("`ti'") subtitle("(1998-2018)") yti("No. of Publications");
		graph export "pubs_ts_byMatchedCountry_life`life01'.png", replace as(png) wid(1600) hei(700);
		#delimit cr
	}
restore
*---------------------------
}
*---------------------------

*---------------------------
if `non_us_2005' == 1 {
*---------------------------
use affls_master_2005.dta, clear


gen has_affl = affl != ""
gen has_country = country != ""

replace country = "UK" if country == "United Kingdom"
preserve
	drop if country == ""
	collapse (count) pubs = pmid, by(country)
	egen rank = rank(pubs), field
	tempfile country_ranks
	save `country_ranks', replace
restore

preserve
	collapse (count) pmid, by(country year nih lifesci)
		merge m:1 country using `country_ranks', nogen keep(1 3) keepus(rank)
		keep if inrange(rank, 2, 11)
		gen country_abbr = substr(country, 1, 3) + "." if strlen(country) > 3
			replace country_abbr = country if strlen(country) <= 3
	
	forval nih01 = 0/1 {
		forval life01 = 0/1 {
			if `nih01' == 1 local ti "NIH-Funded"
			if `nih01' == 0 local ti "Non-NIH-Funded"

			if `life01' == 1 local ti "`ti' Life Science Research"
			if `life01' == 0 local ti "`ti' Non-Life Science Research"

			#delimit ;
			graph bar (asis) pmid if inlist(year, 2005, 2010, 2015)
					& lifesci == `life01' & nih == `nih01', 
				over(year, gap(5)) asyvars bar(1, col(green)) bar(2, col(eltblue)) bar(3, col(gold))
				over(country_abbr) yti("No. of Publications") legend(r(1))
			title("`ti'")   subtitle("(2005-2015)");
			graph export "pubs_byYr_byCountry_2005_life`life01'_nih`nih01'.png", replace as(png) wid(1600) hei(700);
			#delimit cr
		}
	}
	collapse (sum) pmid, by(country country_abbr year lifesci)
		merge m:1 country using `country_ranks', nogen keep(1 3) keepus(rank)
		keep if inrange(rank, 2, 11)
	forval life01 = 0/1 {
		if `life01' == 1 local ti "Total Life Science Research"
		if `life01' == 0 local ti "Total Non-Life Science Research"

		#delimit ;
		graph bar (asis) pmid if inlist(year, 2005, 2010, 2015)
				& lifesci == `life01', 
			over(year, gap(5)) asyvars bar(1, col(green)) bar(2, col(eltblue)) bar(3, col(gold))
			over(country_abbr) yti("No. of Publications") legend(r(1))
			title("`ti'")   subtitle("(2005-2015)");
		graph export "pubs_byYr_byCountry_2005_life`life01'.png", replace as(png) wid(1600) hei(700);
		#delimit cr
	}
restore

merge m:1 country using `country_ranks', nogen keep(1 3) keepus(rank)

gen match_group = "USA" if country == "USA"
replace match_group = "Top" if inrange(rank, 2, 11)
replace match_group = "Other" if rank > 11
replace match_group = "NotMatched" if has_affl == 1 & country == ""

preserve
	collapse (count) pubs = pmid, by(match_group year lifesci nih)
	keep if match_group != ""

	reshape wide pubs, i(year lifesci nih) j(match_group) string
		replace pubsNotMatched = 0 if pubsNotMatched == .
	gen pubsTop_adj = pubsTop + pubsUSA
	gen pubsOther_adj = pubsOther + pubsTop + pubsUSA
	gen pubsNotMatched_adj = pubsNotMatched + pubsOther + pubsTop + pubsUSA

	forval nih01 = 0/1 {
		forval life01 = 0/1 {
			if `nih01' == 1 local ti "NIH-Funded"
			if `nih01' == 0 local ti "Non-NIH-Funded"

			if `life01' == 1 local ti "`ti' Life Science Research"
			if `life01' == 0 local ti "`ti' Non-Life Science Research"

			#delimit ;
			tw (area pubsNotMatched_adj year if lifesci == `life01' & nih == `nih01', col(gs8))
			   (area pubsOther_adj year if lifesci == `life01' & nih == `nih01', col(navy))
			   (area pubsTop_adj year if lifesci == `life01' & nih == `nih01', col(dkorange))
			   (area pubsUSA year if lifesci == `life01' & nih == `nih01', col(cranberry)),
			 legend(order(1 "Have Affiliations but Not Matched to Country"
			 			  2 "Matched to Countries Other than Top 10"
			 			  3 "Matched to UK, Ger., Fr., Can., Neth., Sw., Jap., Aus., Ch., Ita. "
			 		 	  4 "Matched to USA")
			 		c(1))
			 title("`ti'") subtitle("(2005-2015)") yti("No. of Publications");
			graph export "pubs_ts_byMatchedCountry_2005_life`life01'_nih`nih01'.png", replace as(png) wid(1600) hei(700);
			#delimit cr
		}
	}

	collapse (sum) pubs*, by(year lifesci)
	forval life01 = 0/1 {
		if `life01' == 1 local ti "Total Life Science Research"
		if `life01' == 0 local ti "Total Non-Life Science Research"

		#delimit ;
		tw (area pubsNotMatched_adj year if lifesci == `life01', col(gs8))
			   (area pubsOther_adj year if lifesci == `life01', col(navy))
			   (area pubsTop_adj year if lifesci == `life01', col(dkorange))
			   (area pubsUSA year if lifesci == `life01', col(cranberry)),
		 legend(order(1 "Have Affiliations but Not Matched to Country"
			 		  2 "Matched to Countries Other than Top 10"
			 		  3 "Matched to UK, Ger., Fr., Can., Neth., Sw., Jap., Aus., Ch., Ita. "
			 		  4 "Matched to USA")
		 		c(1))
		 title("`ti'") subtitle("(2005-2015)") yti("No. of Publications");
		graph export "pubs_ts_byMatchedCountry_2005_life`life01'.png", replace as(png) wid(1600) hei(700);
		#delimit cr
	}
*---------------------------
}
*---------------------------