/*
Cleaning PMID author affiliations

pmid_authaffl_clean.do

*/

local pmids_append 0
local affls_append 0
local affls_clean 1
local full_save 1



cap cd "C:\Users\lmostrom\Documents\Amitabh\"
global repo "../GitHub/healthcare_trends/"

*================================================================================
* (1) Append all PMIDs lists with the queries they came from
*================================================================================
if `pmids_append' == 1 {
*---------------------------
local filelist: dir "PMIDs\" files "*.csv"

local i = 1
foreach file of local filelist {
	import delimited pmid query_name using "PMIDs/`file'", rowr(2:) clear
	dis "`file'"
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

gen year = substr(query_name, -4, 4)
	destring year, replace
gen nih = substr(query_name, -8, 4) == "_NIH"
gen lifesci = substr(query_name, 1, 7) == "LifeSci"

*Keep earlier of two years when published in both (Epub timing diff from print publishing)
bys pmid: egen min_year = min(year)
	keep if year == min_year
isid pmid
pause

save pmids_QAqueries_full.dta, replace

*---------------------------
}
*---------------------------

*================================================================================
* (2) Clean and append list of author affiliations
*================================================================================
if `affls_append' == 1 {
*---------------------------
local i = 1

foreach subset in life_nih life_notnih_1_40000 life_notnih_40001_80000 life_notnih_80001_111999 ///
				nonlife_nih nonlife_notnih_1_40000 nonlife_notnih_40001_70000 ///
				nonlife_notnih_70001_120000 nonlife_notnih_120001_156438 {
	
	import delimited AuthAffs_QA_`subset'.csv, clear bindquote(nobind) varn(1)

	foreach var of varlist v* {
		replace affls = affls + ", " + `var' if `var' != ""
	}

	replace affls = affls[_n+1] if affls != "NA"
		ren affls affl_raw
	gen affl = subinstr(affl_raw, "&amp;", "and", .)
	* Drop affiliations of authors after the first author
	gen pos_2nd_auth = strpos(affl, "[2]")
	replace pos_2nd_auth = strpos(affl, ".);") + 3 ///
			if pos_2nd_auth == 0 & strpos(affl, ".);") > 0 // ; after initials in parentheses
		replace affl = substr(affl, 1, pos_2nd_auth) if pos_2nd_auth > 0

	destring pmid, replace force
		drop if pmid == .
	drop v*

	if `i' == 1 {
		tempfile full_affls
		save `full_affls', replace
	}
	if `i' > 1 {
		append using `full_affls'
		save `full_affls', replace
	}
	local ++i
}
duplicates drop // some appeared in more than one year
save "full_auth_affls.dta", replace
*---------------------------
}
*---------------------------

*---------------------------
if `affls_clean' == 1 {
*---------------------------
include $repo/clean_cbsa_codes.do

use "full_auth_affls.dta", clear
	
	replace affl = "" if affl_raw == "NA"

	*First check country
	gen country = ""
	include "$repo/country_tags.do"

		*Common points of confusion
		replace country = "USA" if strpos(affl, "Beth Israel") > 0 & country == "Israel"
		replace country = "USA" if strpos(affl, "New London") > 0 & country == "United Kingdom"
		replace country = "USA" if strpos(affl, "New England") > 0 & country == "United Kingdom"

	*Then find zipcodes
	gen zip = regexs(0) if regexm(affl, "[0-9][0-9][0-9][0-9][0-9]") & inlist(country, "USA", "")
	br if strpos(affl, "12208") > 0
	pause
	*Then search strings for state names
	gen state_name = ""

	foreach sn of local state_names {
		dis "`sn'"
		replace state_name = "`sn'" if strpos(affl, "`sn'") > 0 & state_name == "" & inlist(country, "USA", "")
		replace state_name = "`sn'" if strpos(affl, "`sn'") > 0 & state_name != "" & ///
										strpos(affl, "`sn'") < strpos(affl, state_name) & inlist(country, "USA", "")
	}

	*Then search strings for state abbreviations
	gen state_abbr = ""

	foreach SA of local state_abbrs {
		dis "`SA'"
		local Sa = upper(substr("`SA'",1,1)) + lower(substr("`SA'",2,1))
		replace state_abbr = "`SA'" if strpos(affl, "`SA'") > 0 & state_abbr == "" & inlist(country, "USA", "")
		replace state_abbr = "`SA'" if state_abbr != "" & strpos(affl, "`SA'") > 0 & ///
										strpos(affl, "`SA'") < strpos(affl, state_abbr) & inlist(country, "USA", "")
		replace state_abbr = "`SA'" if (strpos(affl, "`Sa' ") > 0 | strpos(affl, "`Sa',") > 0 | strpos(affl, "`Sa'.") > 0) ///
									& state_abbr == "" & state_name == "" & inlist(country, "USA", "")
	}

	*Then search strings for city names
	gen city = ""
	foreach c of local city_names {
		dis "`c'"
		replace city = "`c'" if strpos(affl, "`c'") > 0 & city == "" & inlist(country, "USA", "")
		replace city = "`c'" if strpos(affl, "`c'") > 0 & city != "" & ///
										strpos(affl, "`c'") > strpos(affl, city) & inlist(country, "USA", "")
			/* take city that appears later in the string because that's a more likely place for a city;
				"city names" found earlier more likely to be names of institutions or streets */
	}

	*Common points of confusion & specific places that need to be clarified:
	replace state_name = "" if strpos(affl, "Washington") > 0 & strpos(affl, "DC") > 0
		// streets named after states
	replace state_abbr = "MO" if strpos(affl, "Washington University") > 0
		replace state_name = "Missouri" if strpos(affl, "Washington University") > 0
	replace state_abbr = "NY" if strpos(affl, "Columbia University") > 0 & state_abbr == ""
		replace city = "New York" if strpos(affl, "Columbia University") > 0 & city == "Columbia"
	replace state_abbr = "CT" if strpos(affl, "Yale") > 0 & state_abbr == ""
		replace city = "New Haven" if strpos(affl, "Yale") > 0 & city == ""
	replace state_abbr = "FL" if strpos(affl, "University of Miami") > 0
	replace state_abbr = "OH" if strpos(affl, "Miami Univ") > 0
		replace city = "Oxford" if strpos(affl, "Miami Univ") > 0
	replace city = "San Diego" if strpos(affl, "La Jolla") > 0 & ///
						(city == "" | strpos(affl, "La Jolla") > strpos(affl, city))

	replace state_abbr = "NY" if strpos(affl, "N.Y.") > 0 & ///
				inlist(country, "USA", "") & state_abbr == "" & state_name == ""
	egen noccur_newyork = noccur(affl), s("New York")
		replace city = "New York" if noccur_newyork == 2 | (noccur_newyork == 1 & state_abbr == "NY")
		drop noccur_newyork
	replace state_abbr = "NC" if strpos(affl, "N.C.") > 0 & ///
				inlist(country, "USA", "") & state_abbr == "" & state_name == ""
	replace state_abbr = "NH" if strpos(affl, "N.H.") > 0 & ///
				inlist(country, "USA", "") & state_abbr == "" & state_name == ""
	
	replace state_name = "Arizona" if strpos(affl, "Ariz") > 0 ///
						& state_name == "" & state_abbr == ""
	replace state_name = "California" if strpos(affl, "Calif") > 0 ///
						& state_name == "" & state_abbr == ""
	replace state_name = "Connecticut" if strpos(affl, "Conn") > 0 ///
						& state_name == "" & state_abbr == ""
	replace state_name = "Florida" if strpos(affl, "Fla.") > 0 ///
						& state_name == "" & state_abbr == ""
	replace state_name = "Illinois" if strpos(affl, "Ill") > 0 ///
						& state_name == "" & state_abbr == ""
	replace state_name = "Massachusetts" if strpos(affl, "Mass") > 0 ///
						& state_name == "" & state_abbr == ""
	replace state_name = "Minnesota" if strpos(affl, "Minn") > 0 ///
						& state_name == "" & state_abbr == ""
	replace state_name = "Nebraska" if strpos(affl, "Nebr.") > 0 ///
						& state_name == "" & state_abbr == ""
	replace state_name = "Oklahoma" if strpos(affl, "Okla.") > 0 ///
						& state_name == "" & state_abbr == ""

	replace city = "Charlottesville" if city == "Charlotte" & strpos(affl, "Charlottesville")
	replace city = "Jacksonville" if city == "Jackson" & strpos(affl, "Charlottesville")

	*In case of conflicts / multiple author affiliations
	replace state_name = "" if state_name != "" & state_abbr != "" & ///
								strpos(affl, state_abbr) < strpos(affl, state_name)
	replace state_abbr = "" if state_name != "" & state_abbr != "" & ///
								strpos(affl, state_name) < strpos(affl, state_abbr)
	replace zip = "" if country != "" // 5-digit address probably
	replace country = "USA" if (strpos(affl, "USA") > 0 | state_name != "" | state_abbr != "" | zip != "") ///
						& country == ""

	merge m:1 state_name using "state_names_abbrs.dta", nogen keep(1 3) keepus(state_abbr) update

	*========================================

	merge m:1 city state_abbr using "CBSA_city_state_clean.dta", keep(1 3) keepus(cbsacode)
	destring cbsacode, replace

save clean_auth_affls.dta, replace

*---------------------------
}
*---------------------------
*---------------------------
if `full_save' == 1 {
*---------------------------
use clean_auth_affls.dta, clear

merge 1:1 pmid using "pmids_QAqueries_full.dta", nogen assert(2 3)

save affls_master.dta, replace
*---------------------------
}
*---------------------------

*================================================================================
* (3) Merge with CBSA Codes
*================================================================================
gen has_affl = affl != ""
gen usa = has_affl & country == "USA"

preserve
	#delimit ;
	collapse (count) Total = pmid
			 (sum) w_Affiliation = has_affl 
			 (sum) USA = usa
			 (count) Final = cbsacode, by(year);
	#delimit cr
	sort year
	export delimited sample_byYr_9-20-2019.csv, replace
restore

preserve
	collapse (sum) USA = usa (count) final = cbsacode, by(year lifesci)
	gen coverage = final/USA * 100
	#delimit ;
	tw (line coverage year if lifesci, lc(green) lp(l))
	   (line coverage year if !lifesci, lc(navy) lp(l)),
	 legend(order(1 "Life Science" 2 "Non-Life Science"))
	 yti("Share of US Publications with Found MSA Code (%)")
	 xti("Year");
	#delimit cr
	graph export coverage_byLifeNonLife_9-20-19.png, as(png) replace wid(1200) hei(700)
restore
