/*
pubmed_geo_plots.do



*/
clear all
cap log close
pause on

local QA 0
local notQA 1

cap cd "C:/Users/lmostrom/Dropbox/Amitabh/"
/*
import excel "PubMed/US_Census_MSAs_9-2018.xls", clear cellrange(A3:F1271) first case(lower)
	keep cbsacode cbsatitle
	duplicates drop
	replace cbsatitle = lower(cbsatitle)
	tempfile cbsas
	save `cbsas', replace

use if inlist(year, 1990, 2000, 2010) using usa_00007.dta, clear
	decode sample, gen(newsample)
	drop sample
	ren newsample sample
	keep if inlist(sample, "2010 acs", "2000 5%", "1990 5%")
	collapse (count) pop = pernum [pw = perwt], by(metaread metarea sample) fast

	decode metarea, gen(cbsatitle1)
	decode metaread, gen(cbsatitle2)
	replace cbsatitle1 = subinstr(cbsatitle1, "/", "-", .)
	replace cbsatitle2 = subinstr(cbsatitle2, "/", "-", .)
	
	ren cbsatitle1 cbsatitle
	merge m:1 cbsatitle using `cbsas', nogen keepus(cbsacode)
	ren cbsacode cbsacode1
	ren cbsatitle cbsatitle1
	
	ren cbsatitle2 cbsatitle
	merge m:1 cbsatitle using `cbsas', nogen keepus(cbsacode)
	ren cbsacode cbsacode2
	ren cbsatitle cbsatitle2
	
	replace cbsacode1 = cbsacode2 if cbsacode1 == "" & cbsacode2 != ""
	ren cbsacode1 cbsacode
	replace cbsatitle1 = cbsatitle2 if cbsatitle1 == "" & cbsatitle2 != ""
	ren cbsatitle1 cbsatitle
	
	gen decade = substr(sample, 1, 4)
	destring decade, replace
	
	replace cbsacode = "14460" if cbsacode == "" & strpos(cbsatitle, "boston") > 0 ///
								& strpos(cbsatitle, ", ma") > 0
	replace cbsacode = "41740" if cbsacode == "" & strpos(cbsatitle, "san diego") > 0 ///
								& strpos(cbsatitle, ", ca") > 0
	replace cbsacode = "41860" if cbsacode == "" & (strpos(cbsatitle, "san francisco") > 0 ///
									| strpos(cbsatitle, "oakland") > 0) ///
								& strpos(cbsatitle, ", ca") > 0
	replace cbsacode = "41940" if cbsacode == "" & cbsatitle == "san jose, ca"
	replace cbsacode = "12580" if cbsacode == "" & cbsatitle == "baltimore, md"
	replace cbsacode = "47900" if cbsacode == "" & cbsatitle == "washington, dc-md-va"
	replace cbsacode = "35300" if cbsacode == "" & strpos(cbsatitle, "new haven") > 0 ///
								& strpos(cbsatitle, ", ct") > 0
	replace cbsacode = "20500" if cbsacode == "" & cbsatitle == "raleigh-durham, nc"
	replace cbsacode = "16980" if cbsacode == "" & strpos(cbsatitle, "chicago") > 0 ///
								& strpos(cbsatitle, ", il") > 0
	replace cbsacode = "35620" if cbsacode == "" & strpos(cbsatitle, "new york") > 0 ///
								& strpos(cbsatitle, ", ny") > 0
	replace cbsacode = "42660" if cbsacode == "" ///
								& strpos(cbsatitle, "seattle") > 0 & strpos(cbsatitle, ", wa") > 0
	
	collapse (sum) pop, by(cbsacode decade)
	keep if pop > 0 & cbsacode != ""
	destring cbsacode, replace
	save "PubMed/cbsa_pop_1990-2010.dta", replace
*/

*===============================================================================
if `QA' == 1 {
*-------------------------------------------------------------------------------
    
	local journals "Top 7 Journals*, Full Sample"
	
    import delimited "PubMed/PMIDs/QA/QA_Full.csv", clear varn(1)
	duplicates drop
	ren pmids pmid
	replace pmid = "" if pmid == "NA"
	destring pmid, replace
	tempfile qa_pmids
	save `qa_pmids', replace
	
	use "PubMed/Master_dta/pmids_bas_trans_clin.dta", clear
	tempfile btc_pmids
	save `btc_pmids', replace
	*----------------------------------------------------------
	use "PubMed/bmj_master.dta", clear
	append using "PubMed/clean_auth_affls.dta"
	
	merge 1:1 pmid using `qa_pmids', nogen keep(3)
	
	merge 1:m pmid using `btc_pmids', keep(2 3) nogen
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
	
	merge m:1 decade cbsacode using "PubMed/cbsa_pop_1990-2010.dta", nogen keep(1 3)

	keep if has_affl
	collapse (count) pmid (max) pop, by(cbsacode MSAgroup decade btc)
	collapse (sum) pmid pop, by(MSAgroup decade btc)
		bys MSAgroup btc: egen sort_tot = total(pmid)
		bys btc decade: egen decade_pubs = total(pmid)
			gen sh_dec_pubs = pmid/decade_pubs * 100
		gen pubs_per_person = pmid/pop
		replace pubs_per_person = pubs_per_person * 100000
		lab var pubs_per_person "Publications per 100,000 People"
		summ pubs_per_person, d
	
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
			over(MSAgroup, sort(sort_tot) descending)
		yti("Journal Articles")
		title("`ti'")
		subtitle("(`journals')"
				 "Shown: `n' of `N' (`pctN'%) Publications with Available Affiliations")
		note("* BMJ, Cell, JAMA, Lancet, Nature, NEJM, and Science")
		legend(order(1 "1990s" 2 "2000s" 3 "2010s") r(1));
		graph save "PubMed/gphs/bars_BTC_`cat'_bymsa_bydecade.gph", replace;
		graph export "bars_BTC_`cat'_bymsa_bydecade.png",
			replace as(png) wid(1600) hei(700);
		
		graph bar (asis) pubs_per_person if inlist(decade, 1990, 2000, 2010) 
			& !inlist(MSAgroup, "", "Other") & btc == "`cat'", 
			over(decade, gap(5)) asyvars `cols'
			over(MSAgroup, sort(sort_tot) descending)
		yti("Journal Articles per 100,000 People")
		title("`ti'")
		subtitle("(`journals')"
				 "Shown: `n' of `N' (`pctN'%) Publications with Available Affiliations")
		note("* BMJ, Cell, JAMA, Lancet, Nature, NEJM, and Science")
		legend(order(1 "1990s" 2 "2000s" 3 "2010s") r(1));
		graph save "PubMed/gphs/bars_BTC_`cat'_bymsa_bydecade_popscale.gph", replace;
		graph export "bars_BTC_`cat'_bymsa_bydecade_popscale.png",
			replace as(png) wid(1600) hei(700);
			
		graph bar (asis) sh_dec_pubs if inlist(decade, 1990, 2000, 2010) 
			& !inlist(MSAgroup, "", "Other") & btc == "`cat'", 
			over(decade, gap(5)) asyvars `cols'
			over(MSAgroup, sort(sort_tot) descending)
		yti("Share of Journal Articles with Available Affiliations (%)")
		title("`ti'")
		subtitle("(`journals')"
				 "Shown: `n' of `N' (`pctN'%) Publications")
		note("* BMJ, Cell, JAMA, Lancet, Nature, NEJM, and Science")
		legend(order(1 "1990s" 2 "2000s" 3 "2010s") r(1));
		graph save "PubMed/gphs/bars_BTC_`cat'_bymsa_bydecade.gph", replace;
		graph export "bars_BTC_`cat'_bymsa_bydecade.png",
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
			title("`ti'")
			subtitle("(`journals')"
					 "Shown: `n' of `N' (`pctN'%) Publications with Available Affiliations")
			note("* BMJ, Cell, JAMA, Lancet, Nature, NEJM, and Science");
		graph save "PubMed/gphs/bars_BTC_`cat'_bymsa.gph", replace;
		graph export "bars_BTC_`cat'_bymsa.png", replace as(png) wid(1600) hei(700);
		#delimit cr
	}

	
}
*===============================================================================
if `notQA' == 1 {
*-------------------------------------------------------------------------------

local journals "All Journals"

use "PubMed/clean_auth_affls_master.dta", clear
	
	merge 1:m pmid using "PubMed/Master_dta/pmids_bas_trans_clin_notQA.dta", keep(2 3) nogen
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
	
	merge m:1 decade cbsacode using "PubMed/cbsa_pop_1990-2010.dta", nogen keep(1 3)

	keep if has_affl
	collapse (count) pmid (max) pop, by(cbsacode MSAgroup decade btc)
	collapse (sum) pmid pop, by(MSAgroup decade btc)
		bys MSAgroup btc: egen sort_tot = total(pmid)
		bys btc decade: egen decade_pubs = total(pmid)
			gen sh_dec_pubs = pmid/decade_pubs * 100
		replace pmid = pmid * 20
		gen pubs_per_person = pmid/pop
		replace pubs_per_person = pubs_per_person * 100000
		lab var pubs_per_person "Publications per 100,000 People"
		summ pubs_per_person, d
		pause
		
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
			over(MSAgroup, sort(sort_tot) descending)
		yti("Journal Articles")
		title("`ti', 5% Sample Scaled Up")
		subtitle("(`journals')"
				 "Shown: `n' of `N' (`pctN'%) Publications with Available Affiliations")
		legend(order(1 "1990s" 2 "2000s" 3 "2010s") r(1));
		graph save "PubMed/gphs/bars_BTC_`cat'_bymsa_bydecade_notQA.gph", replace;
		graph export "bars_BTC_`cat'_bymsa_bydecade_notQA.png",
			replace as(png) wid(1600) hei(700);
		
		graph bar (asis) pubs_per_person if inlist(decade, 1990, 2000, 2010) 
			& !inlist(MSAgroup, "", "Other") & btc == "`cat'", 
			over(decade, gap(5)) asyvars `cols'
			over(MSAgroup, sort(sort_tot) descending)
		yti("Journal Articles per 100,000 People")
		title("`ti', 5% Sample Scaled Up")
		subtitle("(`journals')"
				 "Shown: `n' of `N' (`pctN'%) Publications with Available Affiliations")
		legend(order(1 "1990s" 2 "2000s" 3 "2010s") r(1));
		graph save "PubMed/gphs/bars_BTC_`cat'_bymsa_bydecade_popscale_notQA.gph", replace;
		graph export "bars_BTC_`cat'_bymsa_bydecade_popscale_notQA.png",
			replace as(png) wid(1600) hei(700);
			
		graph bar (asis) sh_dec_pubs if inlist(decade, 1990, 2000, 2010) 
			& !inlist(MSAgroup, "", "Other") & btc == "`cat'", 
			over(decade, gap(5)) asyvars `cols'
			over(MSAgroup, sort(sort_tot) descending)
		yti("Share of Journal Articles with Available Affiliations (%)")
		title("`ti'")
		subtitle("(`journals')"
				 "Shown: `n' of `N' (`pctN'%) Publications")
		legend(order(1 "1990s" 2 "2000s" 3 "2010s") r(1));
		graph save "PubMed/gphs/bars_BTC_`cat'_bymsa_bydecade_notQA.gph", replace;
		graph export "bars_BTC_`cat'_bymsa_bydecade_notQA.png",
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
			title("`ti'") 
			subtitle("(`journals')"
					 "Shown: `n' of `N' (`pctN'%) Publications with Available Affiliations");
		graph save "PubMed/gphs/bars_BTC_`cat'_bymsa_notQA.gph", replace;
		graph export "bars_BTC_`cat'_bymsa_notQA.png", replace as(png) wid(1600) hei(700);
		#delimit cr
	}

}