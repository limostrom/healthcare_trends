/*
pubmed_geo_plots.do

NOTE: basic science pubs in top 7 journals: 141,696
		basic science pubs in Cell, Nature, and Science: 110,448 (78%)

*/
clear all
cap log close
pause on

local QA 0
local notQA 0
local scatter 1

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
	replace cbsacode = "12060" if cbsacode == "" & cbsatitle == "atlanta, ga"
	replace cbsacode = "31080" if cbsacode == "" ///
		& strpos(cbsatitle, "los angeles") > 0
	replace cbsacode = "37980" if cbsacode == "" ///
		& strpos(cbsatitle, "philadelphia") > 0
	replace cbsacode = "26420" if cbsacode == "" ///
		& strpos(cbsatitle, "houston") > 0
	replace cbsacode = "19100" if cbsacode == "" ///
		& strpos(cbsatitle, "dallas") > 0
	replace cbsacode = "45940" if cbsacode == "" ///
		& strpos(cbsatitle, "trenton") > 0
	replace cbsacode = "17460" if cbsacode == "" ///
		& strpos(cbsatitle, "cleveland") > 0
	replace cbsacode = "49340" if cbsacode == "" ///
		& strpos(cbsatitle, "worcester") > 0
	replace cbsacode = "33460" if cbsacode == "" ///
		& strpos(cbsatitle, "minneapolis") > 0
	replace cbsacode = "34980" if cbsacode == "" ///
		& strpos(cbsatitle, "nashville") > 0
	replace cbsacode = "19740" if cbsacode == "" ///
		& cbsatitle == "denver-boulder, co"
	replace cbsacode = "40900" if cbsacode == "" ///
		& strpos(cbsatitle, "sacramento") > 0
	replace cbsacode = "41620" if cbsacode == "" ///
		& strpos(cbsatitle, "salt lake city") > 0
	replace cbsacode = "38900" if cbsacode == "" ///
		& cbsatitle == "portland, or-wa"
	replace cbsacode = "39300" if cbsacode == "" ///
		& strpos(cbsatitle, "providence") > 0
	replace cbsacode = "16580" if cbsacode == "" ///
		& strpos(cbsatitle, "champaign-urbana") > 0
	replace cbsacode = "32820" if cbsacode == "" ///
		& strpos(cbsatitle, "memphis") > 0
	replace cbsacode = "33100" if cbsacode == "" ///
		& strpos(cbsatitle, "miami") > 0
	replace cbsacode = "12420" if cbsacode == "" ///
		& strpos(cbsatitle, "austin") > 0
	replace cbsacode = "38060" if cbsacode == "" ///
		& strpos(cbsatitle, "phoenix") > 0
	replace cbsacode = "13820" if cbsacode == "" ///
		& strpos(cbsatitle, "birmingham") > 0
	replace cbsacode = "42200" if cbsacode == "" ///
		& strpos(cbsatitle, "santa barbara") > 0
	replace cbsacode = "19820" if cbsacode == "" ///
		& strpos(cbsatitle, "detroit") > 0
	replace cbsacode = "12020" if cbsacode == "" ///
		& strpos(cbsatitle, "athens") > 0
	replace cbsacode = "41700" if cbsacode == "" ///
		& strpos(cbsatitle, "san antonio") > 0
	replace cbsacode = "22660" if cbsacode == "" ///
		& strpos(cbsatitle, "fort collins") > 0
	replace cbsacode = "44300" if cbsacode == "" ///
		& cbsatitle == "state college, pa"
	replace cbsacode = "26900" if cbsacode == "" ///
		& strpos(cbsatitle, "indianapolis") > 0
	replace cbsacode = "46520" if cbsacode == "" ///
		& strpos(cbsatitle, "honolulu") > 0
	replace cbsacode = "42100" if cbsacode == "" ///
		& strpos(cbsatitle, "santa cruz") > 0
	replace cbsacode = "29620" if cbsacode == "" ///
		& strpos(cbsatitle, "lansing") > 0
	replace cbsacode = "26980" if cbsacode == "" ///
		& strpos(cbsatitle, "iowa city") > 0
	replace cbsacode = "29200" if cbsacode == "" ///
		& cbsatitle == "lafayette-w. lafayette, in"
	replace cbsacode = "23540" if cbsacode == "" ///
		& cbsatitle == "gainesville, fl"
	replace cbsacode = "39580" if cbsacode == "" ///
		& strpos(cbsatitle, "raleigh") > 0
	replace cbsacode = "40140" if cbsacode == "" ///
		& cbsatitle == "riverside-san bernardino, ca"
	replace cbsacode = "14020" if cbsacode == "" ///
		& cbsatitle == "bloomington, in"
	replace cbsacode = "40060" if cbsacode == "" ///
		& cbsatitle == "richmond-petersburg, va"
	replace cbsacode = "33340" if cbsacode == "" ///
		& cbsatitle == "milwaukee, wi"
	replace cbsacode = "17780" if cbsacode == "" ///
		& cbsatitle == "bryan-college station, tx"
	replace cbsacode = "31140" if cbsacode == "" ///
		& cbsatitle == "louisville, ky-in"
	replace cbsacode = "45220" if cbsacode == "" ///
		& cbsatitle == "tallahassee, fl"
	replace cbsacode = "15380" if cbsacode == "" ///
		& cbsatitle == "buffalo-niagara falls, ny"
	replace cbsacode = "36540" if cbsacode == "" ///
		& cbsatitle == "omaha, ne-ia"
	replace cbsacode = "25540" if cbsacode == "" ///
		& strpos(cbsatitle, "hartford") > 0
	replace cbsacode = "24340" if cbsacode == "" ///
		& cbsatitle == "grand rapids, mi"
	replace cbsacode = "35380" if cbsacode == "" ///
		& cbsatitle == "new orleans, la"
	replace cbsacode = "16700" if cbsacode == "" ///
		& cbsatitle == "charleston-n. charleston, sc"
	
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
	
	use "PubMed/Master_dta/pmids_bas_trans_clin_notQA.dta", clear
	tempfile btc_pmids
	save `btc_pmids', replace
	*----------------------------------------------------------
	use "PubMed/bmj_master.dta", clear
	append using "PubMed/clean_auth_affls.dta"
	
	merge 1:1 pmid using `qa_pmids', nogen keep(3)
	
	merge 1:m pmid using `btc_pmids', keep(3) nogen
		drop if inlist(btc, "total", "totalCTs")
		
	gen has_affl = affl != ""
	gen usa = has_affl & inlist(country, "", "USA")
	
	gen MSAgroup = "BOS" if cbsacode == 14460 // 1
		replace MSAgroup = "DC/BETH" if cbsacode == 47900 // 2
		replace MSAgroup = "SF/SJ" if inlist(cbsacode, 41860, 41940) // 3 & 6
		replace MSAgroup = "BALT" if cbsacode == 12580 // 4
		replace MSAgroup = "SD" if cbsacode == 41740 // 5
		replace MSAgroup = "LA" if cbsacode == 31080 // 7 
		replace MSAgroup = "CHI" if cbsacode == 16980 // 8
		replace MSAgroup = "NHAV" if cbsacode == 35300 // 9
		replace MSAgroup = "DUR/CH" if cbsacode == 20500 // 10
		*replace MSAgroup = "ATL" if cbsacode == 12060 // 11
		*replace MSAgroup = "SEA" if cbsacode == 42660 // 12
		replace MSAgroup = "NY" if cbsacode == 35620 // 28

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
			local note2 "78% of basic science publications are in Cell, Nature, or Science"
		}
		if "`cat'" == "translational" {
			local ti "Translational Science Publications"
			local cols "bar(1, col(navy)) bar(2, col(blue)) bar(3, col(eltblue))"
			local note2 ""
		}
		if "`cat'" == "clinical" {
			local ti "Clinical Science Publications"
			local cols "bar(1, col(maroon)) bar(2, col(cranberry)) bar(3, col(erose))"
			local note2 ""
		}
		if "`cat'" == "healthcare" {
			local ti "Healthcare Publications"
			local cols "bar(1, col(purple*2)) bar(2, col(purple)) bar(3, col(lavender))"
			local note2 ""
		}
		if "`cat'" == "trial" {
			local ti "Clinical Trials"
			local cols "bar(1, col(sienna)) bar(2, col(dkorange)) bar(3, col(sand))"
			local note2 ""
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
				 "Top MSAs account for `n' of `N' (`pctN'%) with Available Affiliations")
		note("* BMJ, Cell, JAMA, Lancet, Nature, NEJM, and Science" "`note2'")
		legend(order(1 "1990s" 2 "2000s" 3 "2010s") r(1));
		graph save "PubMed/gphs/bars_BTC_`cat'_bymsa_bydecade.gph", replace;
		graph export "bars_BTC_`cat'_bymsa_bydecade.png",
			replace as(png) wid(1600) hei(700);
		pause
		graph bar (asis) pubs_per_person if inlist(decade, 1990, 2000, 2010) 
			& !inlist(MSAgroup, "", "Other") & btc == "`cat'", 
			over(decade, gap(5)) asyvars `cols'
			over(MSAgroup, sort(sort_tot) descending)
		yti("Journal Articles per 100,000 People")
		title("`ti'")
		subtitle("(`journals')"
				 "Top MSAs account for `n' of `N' (`pctN'%) with Available Affiliations")
		note("* BMJ, Cell, JAMA, Lancet, Nature, NEJM, and Science" "`note2'")
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
				 "Top MSAs account for `n' of `N' (`pctN'%) with Available Affiliations")
		note("* BMJ, Cell, JAMA, Lancet, Nature, NEJM, and Science" "`note2'")
		legend(order(1 "1990s" 2 "2000s" 3 "2010s") r(1));
		graph save "PubMed/gphs/bars_BTC_`cat'_bymsa_bydecade.gph", replace;
		graph export "bars_BTC_`cat'_bymsa_bydecade.png",
			replace as(png) wid(1600) hei(700);
		#delimit cr

	} // B/T/C loop
	
	collapse (sum) pmid, by(MSAgroup btc)
	foreach cat of local B_T_C {
		if "`cat'" == "basic" {
			local ti "Basic Science Publications"
			local col "bar(1, col(midgreen))"
			local note2 "78% of basic science publications are in Cell, Nature, or Science"
		}
		if "`cat'" == "translational" {
			local ti "Translational Science Publications"
			local col "bar(1, col(blue))"
			local note2 ""
		}
		if "`cat'" == "clinical" {
			local ti "Clinical Science Publications"
			local col "bar(1, col(cranberry))"
			local note2 ""
		}
		if "`cat'" == "healthcare" {
			local ti "Healthcare Publications"
			local col "bar(1, col(purple))"
			local note2 ""
		}
		if "`cat'" == "trial" {
			local ti "Clinical Trials"
			local col "bar(1, col(dkorange))"
			local note2 ""
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
					 "Top MSAs account for `n' of `N' (`pctN'%) with Available Affiliations")
			note("* BMJ, Cell, JAMA, Lancet, Nature, NEJM, and Science" "`note2'");
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
	
	merge 1:m pmid using "PubMed/Master_dta/pmids_bas_trans_clin_notQA.dta", keep(3) nogen
		drop if inlist(btc, "total", "totalCTs")

	gen has_affl = affl != ""
	gen usa = has_affl & inlist(country, "", "USA")

	gen MSAgroup = "BOS" if cbsacode == 14460 // 1
		replace MSAgroup = "DC/BETH" if cbsacode == 47900 // 2
		replace MSAgroup = "SF/SJ" if inlist(cbsacode, 41860, 41940) // 3 & 6
		replace MSAgroup = "BALT" if cbsacode == 12580 // 4
		replace MSAgroup = "SD" if cbsacode == 41740 // 5
		replace MSAgroup = "LA" if cbsacode == 31080 // 7 
		replace MSAgroup = "CHI" if cbsacode == 16980 // 8
		replace MSAgroup = "NHAV" if cbsacode == 35300 // 9
		replace MSAgroup = "DUR/CH" if cbsacode == 20500 // 10
		*replace MSAgroup = "ATL" if cbsacode == 12060 // 11
		*replace MSAgroup = "SEA" if cbsacode == 42660 // 12
		replace MSAgroup = "NY" if cbsacode == 35620 // 28
		
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
		if "`cat'" == "healthcare" {
			local ti "Healthcare Publications"
			local cols "bar(1, col(purple*2)) bar(2, col(purple)) bar(3, col(lavender))"
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
				 "Top MSAs account for `n' of `N' (`pctN'%) with Available Affiliations")
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
				 "Top MSAs account for `n' of `N' (`pctN'%) with Available Affiliations")
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
				 "Top MSAs account for `n' of `N' (`pctN'%) with Available Affiliations")
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
		if "`cat'" == "healthcare" {
			local ti "Healthcare Publications"
			local col "bar(1, col(purple))"
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
					 "Top MSAs account for `n' of `N' (`pctN'%) with Available Affiliations");
		graph save "PubMed/gphs/bars_BTC_`cat'_bymsa_notQA.gph", replace;
		graph export "bars_BTC_`cat'_bymsa_notQA.png", replace as(png) wid(1600) hei(700);
		#delimit cr
	}

}


*===============================================================================
if `scatter' == 1 {
*-------------------------------------------------------------------------------
    
	use VC_Deals/deals_pfcomp_byMSA.dta, clear
	replace cbsacode = 41860 if cbsacode == 41940 // Bay Area
	gen decade = 10*int(dealyear/10)
		keep if inlist(decade, 2000, 2010)
	collapse (sum) deals_2020USDmn*, by(cbsacode decade)
	tempfile vcdollars
	save `vcdollars', replace
	
	local journals "Top 7 Journals*, Full Sample"
	
    import delimited "PubMed/PMIDs/QA/QA_Full.csv", clear varn(1)
	duplicates drop
	ren pmids pmid
	replace pmid = "" if pmid == "NA"
	destring pmid, replace
	tempfile qa_pmids
	save `qa_pmids', replace
	
	use "PubMed/Master_dta/pmids_bas_trans_clin_notQA.dta", clear
	tempfile btc_pmids
	save `btc_pmids', replace
	*----------------------------------------------------------
	use "PubMed/bmj_master.dta", clear
	append using "PubMed/clean_auth_affls.dta"
	
	merge 1:1 pmid using `qa_pmids', nogen keep(3)
	
	merge 1:m pmid using `btc_pmids', keep(3) nogen
		drop if inlist(btc, "total", "totalCTs")
		
	gen has_affl = affl != ""
	gen usa = has_affl & inlist(country, "", "USA")
	
	levelsof btc, local(B_T_C)
	gen decade = 10*int(year/10)
		keep if inlist(decade, 2000, 2010)
	
	keep if has_affl
	
	replace cbsacode = 41860 if cbsacode == 41940 // Bay Area
	replace cbsacode = 19740 if cbsacode == 14500 // Denver-Boulder
	collapse (count) pmid, by(cbsacode btc decade)
	
	reshape wide pmid, i(cbsacode decade) j(btc) string
	ren pmidtranslational pmidt
	ren pmidbasic pmidb
	ren pmidclinical pmidc
	ren pmidhealthcare pmidh
	drop pmidtrial
	merge 1:1 cbsacode decade using `vcdollars', keep(3) nogen
	merge 1:1 cbsacode decade using "PubMed/cbsa_pop_1990-2010.dta", ///
			nogen keep(1 3)
		ren deals*y vc_biotech
		ren deals*s vc_pharma
		ren deals*e vc_healthcare
	reshape wide pmidb pmidt pmidc pmidh vc_* pop, i(cbsacode) j(decade)
	
	egen msa_pub_tot = rowtotal(pmid*)
	drop if cbsacode == .
	
	drop if vc_healthcare2000 == . & vc_healthcare2010 == .
	gsort -msa_pub_tot
	g byte sample1 = _n <= 26 & _n != 25
	g byte sample2 = _n <= 50
	g byte sample3 = _n <= 75
	
	
	forval y = 2000(10)2010 {
		gen vc_drugs`y' = vc_biotech`y' + vc_pharma`y'
	egen tot_vc_drugs`y' = total(vc_drugs`y')
		gen sh_vc_drugs`y' = vc_drugs`y'/tot_vc_drugs`y'*100
	egen totbas`y' = total(pmidb`y')
		gen shbas`y' = pmidb`y'/totbas`y'*100
			lab var shbas`y' "Share of Basic Science Publications (%)"
	egen tottra`y' = total(pmidt`y')
		gen shtra`y' = pmidt`y'/tottra`y'*100
			lab var shtra`y' "Share of Translational Science Publications (%)"
	gen sh_science`y' = (pmidb`y'+pmidt`y')/(totbas`y'+tottra`y')*100
		lab var sh_science`y' "Share of Science Publications (%)"
	egen totclin`y' = total(pmidc`y')
		gen shclin`y' = pmidc`y'/totclin`y'*100
			lab var shclin`y' "Share of Clinical Science Publications (%)"
	}
	
	gen shbas = (pmidb2000 + pmidb2010)/(totbas2000 + totbas2010)
	gen shtra = (pmidt2000 + pmidt2010)/(tottra2000 + tottra2010)
	gen shclin = (pmidc2000 + pmidc2010)/(totclin2000 + totclin2010)
	
	foreach var of varlist pmid* {
		if substr("`var'", 5, 1) == "b" local scilab "Basic Science"
		if substr("`var'", 5, 1) == "t" local scilab "Translational Science"
		if substr("`var'", 5, 1) == "c" local scilab "Clinical Science"
		local yr = substr("`var'", -4, .)
		gen `var'_popscale = `var'/pop`yr'*100000
		lab var `var'_popscale "`scilab' Pubs per 100,000 People"
	}
	
	gen deg45y = 0 if _n == 1
	gen deg45x = 0 if _n == 1
	replace deg45y = 25 if _n == 2
	replace deg45x = 25 if _n == 2
	
	gen cbsaname = "Boston" if cbsacode == 14460 // 1
		replace cbsaname = "DC-Bethesda" if cbsacode == 47900 // 3
		replace cbsaname = "Bay Area" if cbsacode == 41860 // 2
		replace cbsaname = "Baltimore" if cbsacode == 12580 // 4
		replace cbsaname = "San Diego" if cbsacode == 41740 // 5
		replace cbsaname = "Los Angeles" if cbsacode == 31080 // 6 
		replace cbsaname = "Chicago" if cbsacode == 16980 // 10
		replace cbsaname = "New Haven" if cbsacode == 35300 // 9
		replace cbsaname = "Durham-Chapel Hill" if cbsacode == 20500 // 7
		replace cbsaname = "Atlanta" if cbsacode == 12060 // 11
		replace cbsaname = "Seattle" if cbsacode == 42660 // 8
		replace cbsaname = "Philadelphia" if cbsacode == 37980 // 12
		replace cbsaname = "Houston" if cbsacode == 26420 // 13
		replace cbsaname = "Dallas" if cbsacode == 19100 // 14
		replace cbsaname = "St. Louis" if cbsacode == 41180 // 15
		replace cbsaname = "Ann Arbor" if cbsacode == 11460 // 16
		replace cbsaname = "Denver-Boulder" if cbsacode == 19740 // 17
		replace cbsaname = "Princeton-Trenton" if cbsacode == 45940 // 18
		replace cbsaname = "Pittsburgh" if cbsacode == 38300 // 19
		replace cbsaname = "Madison" if cbsacode == 31540 // 20
		replace cbsaname = "Cleveland" if cbsacode == 17460 // 21
		replace cbsaname = "Worcester" if cbsacode == 49340 // 22
		replace cbsaname = "Minneapolis-St.Paul" if cbsacode == 33460 // 23
		replace cbsaname = "Nashville" if cbsacode == 34980 // 24
		replace cbsaname = "Ithaca" if cbsacode == 27060 // 25
		replace cbsaname = "New York" if cbsacode == 35620 // 26
	
	forval y = 2010(10)2010 {
		local yend = `y' + 9
		#delimit ;
		/*
		tw (line deg45y deg45x if _n<3, lw(thin) lc(gs10))
		   (scatter shtra`y' shbas`y' if sample1 & _n==1, /* Boston */
					msym("o") mc(white) mlabel(cbsaname) mlabp(9) mlabc(black) mlabsize(vsmall) mlabgap(0.5cm))
		   (scatter shtra`y' shbas`y' if sample1 & inlist(_n,2), /* Bay */
					msym("o") mc(white) mlabel(cbsaname) mlabp(2) mlabc(black) mlabsize(vsmall) mlabgap(0.5cm))
		   (scatter shtra`y' shbas`y' if sample1 & inlist(_n,5), /* SD */
					msym("o") mc(white) mlabel(cbsaname) mlabp(2) mlabc(black) mlabsize(vsmall) mlabgap(0.3cm))
		   (scatter shtra`y' shbas`y' if sample1 & inlist(_n,3,6), /*DC & LA */
					msym("o") mc(white) mlabel(cbsaname) mlabp(3) mlabc(black) mlabsize(vsmall))
		   (scatter shtra`y' shbas`y' if sample1 & _n==4, /* Baltimore */
					msym("o") mc(white) mlabel(cbsaname) mlabp(2) mlabc(black) mlabsize(vsmall))
		   (scatter shtra`y' shbas`y' if sample1 & _n==9, /* New Haven */
					msym("o") mc(white) mlabel(cbsaname) mlabp(1) mlabc(black) mlabsize(vsmall))
		   (scatter shtra`y' shbas`y' if sample1 & _n==8, /* Seattle */
					msym("o") mc(white) mlabel(cbsaname) mlabp(3) mlabc(black) mlabsize(vsmall) mlabgap(0.05in))
		   (scatter shtra`y' shbas`y' if sample1 & inlist(_n,7), /*Durham*/
					msym("o") mc(white) mlabel(cbsaname) mlabp(5) mlabc(black) mlabsize(vsmall))
		   (scatter shtra`y' shbas`y' if sample1 & inlist(_n,10), /*Chicago*/
					msym("o") mc(white) mlabel(cbsaname) mlabp(5) mlabc(black) mlabsize(vsmall) mlabgap(0.1in))
		   (scatter shtra`y' shbas`y' if sample1 & inlist(_n,12), /*Philly*/
					msym("o") mc(white) mlabel(cbsaname) mlabp(5) mlabc(black) mlabsize(vsmall) mlabgap(0.07in))
		   (scatter shtra`y' shbas`y' if sample1 & inlist(_n,11, 13), /*Altanta & Houston */
					msym("o") mc(white) mlabel(cbsaname) mlabp(12) mlabc(black) mlabsize(vsmall) mlabgap(1.75in))
		   (scatter shtra`y' shbas`y' if sample1 & inlist(_n,15), /* St. Louis */
					msym("o") mc(white) mlabel(cbsaname) mlabp(12) mlabc(black) mlabsize(vsmall) mlabgap(1.6in))
		   (scatter shtra`y' shbas`y' if sample1 & inlist(_n,14), /* Dallas */
					msym("o") mc(white) mlabel(cbsaname) mlabp(12) mlabc(black) mlabsize(vsmall) mlabgap(1.5in))
		   (scatter shtra`y' shbas`y' if sample1 & _n==26,
					msym("o") mc(white) mlabel(cbsaname) mlabp(4) mlabc(black) mlabsize(vsmall))
		   (scatter shtra`y' shbas`y' if sample1 [w=vc_drugs`y'], msym("oh") mc(black)),
			legend(off)
			xti("Share of Basic Science Publications (%)", size(small))
			yti("Share of Translational Science Publications (%)" " " " ", size(small))
			ti("Scientific Research, `y'-`yend'" "Scaled by VC$s in Biotech & Pharma", size(medsmall))
			subti("Top 26 MSAs", size(small)) ylab(0(5)25) xlab(0(5)25)
			note("Lower Left: Ann Arbor, Denver-Boulder, Princeton, Pittsburgh, Madison WI,"
				"Cleveland, Worcester MA, Minneapolis-St. Paul, Nashville, Ithaca NY", size(vsmall));
		graph export "VC_Deals/Output/CPIAUCSL/scatter_TvsB_scaledVC_`y'.png",
			replace as(png) wid(800) hei(800);
		*/
	replace deg45y = 30 if _n == 2;
	replace deg45x = 30 if _n == 2;
		tw (line deg45y deg45x if _n<3, lw(thin) lc(gs10))
		   (scatter sh_vc_drugs`y' sh_science`y' if sample1 & inlist(_n,1,2,5,10),
				msym("o") mc(white) mlabel(cbsaname) mlabp(9) mlabc(black) mlabsize(vsmall))
		   (scatter sh_vc_drugs`y' sh_science`y' if sample1 & inlist(_n,26,3,6),
				msym("o") mc(white) mlabel(cbsaname) mlabp(3) mlabc(black) mlabsize(vsmall))
		   (scatter sh_vc_drugs`y' sh_science`y' if sample1 & inlist(_n,4),
				msym("o") mc(white) mlabel(cbsaname) mlabp(4) mlabc(black) mlabsize(vsmall))
		   (scatter sh_vc_drugs`y' sh_science`y' if sample1 & inlist(_n,8,12),
				msym("o") mc(white) mlabel(cbsaname) mlabp(10) mlabc(black) mlabsize(vsmall))
		   (scatter sh_vc_drugs`y' sh_science`y' if sample1 & inlist(_n,9),
				msym("o") mc(white) mlabel(cbsaname) mlabp(1) mlabc(black) mlabsize(vsmall) mlabgap(0.35in))
		   (scatter sh_vc_drugs`y' sh_science`y' if sample1 & inlist(_n,7),
				msym("o") mc(white) mlabel(cbsaname) mlabp(2) mlabc(black) mlabsize(vsmall) mlabgap(0.3in))
		   (scatter sh_vc_drugs`y' sh_science`y' if sample1, msym("oh") mc(black)),
			legend(off)
			xti("Share of Science Publications (%)", size(small)) xlab(0(5)30)
			yti("Share of VC Funding to Drugs (%)" " " " ", size(small)) ylab(0(5)30)
			ti("Scientific Research & VC Investment in Drugs" "`y'-`yend'", size(medsmall))
			subti("Top 26 MSAs", size(small)) /*ylab(0(5)25) xlab(0(5)25)*/
			note("Lower Left: Atlanta, Houston, Dallas, St. Louis, Ann Arbor, Denver-Boulder, Princeton,"
				"Pittsburgh, Madison, Cleveland, Worcester MA, Minneapolis-St. Paul, Nashville, Ithaca NY", size(vsmall));
		graph export "VC_Deals/Output/CPIAUCSL/scatter_VCvsSci_`y'.png",
			replace as(png) wid(800) hei(800);
			
		preserve;
			gsort -sh_science2010;
			keep if _n<=10;
			egen top10_share = total(sh_science2010);
			local Spct: dis top10_share;
			local Spct = round(`Spct', 1);
			replace cbsaname = "Durham" if cbsaname == "Durham-Chapel Hill";
			graph bar (asis) sh_science2010, over(cbsaname, sort(sh_science2010) descending)
						bar(1, col(navy)) ti("Top 10 MSAs for Academic Science")
						subtitle("Top MSAs account for `Spct'% of Science Publications");
			graph export "VC_Deals/Output/CPIAUCSL/bars_BTscience_`y'.png",
				replace as(png) wid(1800) hei(700);
		restore;
	/*
		twoway (scatter pmidt`y'_popscale pmidb`y'_popscale if sample1 [w=vc_drugs`y'],
					msym("oh") mc(black)),
			ti("Research Scaled by VC$s in Biotech & Pharma" "`y'-`yend'")
			subti("Top 25 MSAs");
		graph export "VC_Deals/Output/CPIAUCSL/scatter_TvsB_popscale_scaledVC_`y'.png",
			replace as(png) wid(1200) hei(700);
			
		twoway (scatter shclin`y' shtra`y' if sample1 [w=vc_drugs`y'], msym("oh") mc(black)),
			ti("Research Scaled by VC$s in Biotech & Pharma" "`y'-`yend'")
			subti("Top 25 MSAs");
		graph export "VC_Deals/Output/CPIAUCSL/scatter_CvsT_scaledVC_`y'.png",
			replace as(png) wid(1200) hei(700);
			
		twoway (scatter pmidc`y'_popscale pmidt`y'_popscale if sample1 [w=vc_drugs`y'],
					msym("oh") mc(black)),
			ti("Research Scaled by VC$s in Biotech & Pharma" "`y'-`yend'")
			subti("Top 25 MSAs");
		graph export "VC_Deals/Output/CPIAUCSL/scatter_CvsT_popscale_scaledVC_`y'.png",
			replace as(png) wid(1200) hei(700);
		*/
		eststo r`y'a, title("VC$s           `y'-`yend'        N=25"):
			reg vc_drugs`y' shbas`y' shtra`y' if sample1, vce(robust);
		eststo r`y'b, title("VC$s           `y'-`yend'        N=50"):
			reg vc_drugs`y' shbas`y' shtra`y' if sample2, vce(robust);
		eststo r`y'c, title("VC$s           `y'-`yend'        N=75"):
			reg vc_drugs`y' shbas`y' shtra`y' if sample3, vce(robust);
			
		eststo r`y'd, title("VC $s           `y'-`yend'        w/ Pop.           N=25"):
			reg vc_drugs`y' shbas`y' shtra`y' pop`y' if sample1, vce(robust);
		eststo r`y'e, title("VC $s           `y'-`yend'        w/ Pop.           N=50"):
			reg vc_drugs`y' shbas`y' shtra`y' pop`y' if sample2, vce(robust);
		eststo r`y'f, title("VC $s           `y'-`yend'        w/ Pop.           N=75"):
			reg vc_drugs`y' shbas`y' shtra`y' pop`y' if sample3, vce(robust);
			
		eststo r`y'g, title("VC$s           `y'-`yend'        N=25"):
			reg vc_drugs`y' shbas`y' shtra`y' shclin`y' if sample1, vce(robust);
		eststo r`y'h, title("VC $s           `y'-`yend'        w/ Pop.           N=25"):
			reg vc_drugs`y' shbas`y' shtra`y' shclin`y' pop`y' if sample1, vce(robust);
		
		#delimit cr
	}
	
	esttab r*a r*b r*c r*d r*e r*f r*g r*h using "VC_Deals/Output/CPIAUCSL/msa_regs.csv", ///
		replace r2(%9.2f) ar2(%9.2f) b(%9.3f) p(%9.3f) mtitles ///
		title("VC Funding ($ M) and Share of Basic & Translational Science Research")
	/*
	#delimit ;
		twoway (scatter shtra shbas if sample1 [w=vc_drugs], msym("oh") mc(black)),
			ti("Research Scaled by VC$s in Biotech & Pharma" "2000-2019")
			subti("Top 25 MSAs");
		graph export "VC_Deals/Output/CPIAUCSL/scatter_TvsB_scaledVC.png",
			replace as(png) wid(1200) hei(700);
		twoway (scatter shclin shtra if sample1 [w=vc_drugs], msym("oh") mc(black)),
			ti("Research Scaled by VC$s in Biotech & Pharma" "2000-2019")
			subti("Top 25 MSAs");
		graph export "VC_Deals/Output/CPIAUCSL/scatter_CvsT_scaledVC.png",
			replace as(png) wid(1200) hei(700);
	#delimit cr
	*/
}