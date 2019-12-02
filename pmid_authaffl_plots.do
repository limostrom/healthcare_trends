/*
pmid_authaffl_plots.do


*/

pause on

local plots 1
local plots_2005 0
	local old_MSAs 0
	local ext "" // set to "" for lifesci, "_hs" for health service
local non_us 0
local non_us_2005 0



*================================================================================
* (3) Plot Top MSA Publication Counts
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
	export delimited sample`ext'_byYr_10-15-2019.csv, replace
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
	graph export coverage_byLifeNonLife`ext'_10-15-19.png, as(png) replace wid(1200) hei(700)
restore

gen MSAgroup = "BOS" if cbsacode == 14460
	replace MSAgroup = "SF & SJ" if inlist(cbsacode, 41860, 41940)
	replace MSAgroup = "CHI" if cbsacode == 16980
	replace MSAgroup = "NY" if cbsacode == 35620
	replace MSAgroup = "DC" if inlist(cbsacode, 47900, 12580)
	replace MSAgroup = "LA" if cbsacode == 31080
	replace MSAgroup = "SD" if cbsacode == 41740

if `old_MSAs' == 0 {
	replace MSAgroup = "NHAV" if cbsacode == 35300
	replace MSAgroup = "SEA" if cbsacode == 42660
	replace MSAgroup = "DUR/CH" if cbsacode == 20500
	local folder ""
}
else {
	replace MSAgroup = "PHL" if cbsacode == 37980
	replace MSAgroup = "MIA" if cbsacode == 33100
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
			 			  3 "Matched to BOS, CHI, DC, DUR/CH, LA, NHAV, NY, SD, SEA, or SF/SJ")
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
		 			  3 "Matched to BOS, CHI, DC, DUR/CH, LA, NHAV, NY, SD, SEA, or SF/SJ")
		 		c(1))
		 title("`ti'") subtitle("(1988-2018)") yti("No. of `yvar'");
		graph export "`folder'pubs`ext'_ts_byMatched_life`life01'.png", replace as(png) wid(1600) hei(700);
		#delimit cr
	}
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
	replace MSAgroup = "DC" if inlist(cbsacode, 47900, 12580)
	replace MSAgroup = "LA" if cbsacode == 31080
	replace MSAgroup = "SD" if cbsacode == 41740
	replace MSAgroup = "NHAV" if cbsacode == 35300
	replace MSAgroup = "SEA" if cbsacode == 42660
	replace MSAgroup = "DUR/CH" if cbsacode == 20500
if `old_MSAs' == 0 {
	replace MSAgroup = "NHAV" if cbsacode == 35300
	replace MSAgroup = "SEA" if cbsacode == 42660
	replace MSAgroup = "DUR/CH" if cbsacode == 20500
	local folder ""
}
else {
	replace MSAgroup = "PHL" if cbsacode == 37980
	replace MSAgroup = "MIA" if cbsacode == 33100
	local folder "Plots - old Top MSAs/"
}	
	replace MSAgroup = "Other" if cbsacode != . & MSAgroup == ""



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

	forval life01 = 0/1 {
		if `life01' == 1 local ti "Total Life Science Research"
		if `life01' == 0 local ti "Total Non-Life Science Research"

		#delimit ;
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