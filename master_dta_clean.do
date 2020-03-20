/*
master_dta_clean.do

*/

pause on

cap cd "C:\Users\lmostrom\Dropbox\Amitabh\Master_dta"
cap cd "/export/home/dor/lmostrom/Documents/Amitabh/Master_dta/"
local cwd: pwd

local append 0
local split 1

local all 1
local mesh 0
local date 0
local journals 0
local pub_type 0
local grants 0
local affl 0

local save 1


*** for testing: use raw_samp1pct.dta, clear

*===============================================================================
* Append scraped files
if `append' == 1 {
*===============================================================================
local filelist: dir "`cwd'" files "raw_*.csv"

local i = 1
foreach file of local filelist {
	import delimited "`file'", clear varn(1)
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
	}

	local ++i
}
save "../master_dta_appended.dta", replace
*===============================================================================
}
else use "../master_dta_appended.dta", clear
*===============================================================================

*===============================================================================
* Append scraped files
if `split' == 1 {
*===============================================================================

forval i = 1/13 {
	preserve
	if `i' == 1 {
		local start = 1
		local end = 100000
	}
	if inrange(`i', 2, 12) {
		local start = (`i' - 1) * 100000 + 1
		local end = `i'*100000
	}
	if `i' == 13 {
		local start = 1200000 + 1
		local end = _N
	}
	dis "`start' : `end'"
	keep if inrange(_n, `start', `end')
	tempfile sub`i'
	save `sub`i'', replace
	
	restore
}

*===============================================================================
}
*===============================================================================
forval I = 1/13 {
	use `sub`I'', clear
*===============================================================================
* Clean MeSH Terms Field
if `mesh' == 1 | `all' == 1 {
*===============================================================================
gen mesh_na = mesh == "NA"
tab mesh_na

split mesh, p("</MeshHeading>")
ren mesh mesh_raw

egen nterms = noccur(mesh_raw), string("<MeshHeading>")
	egen max_nterms = max(nterms)
	local max_nterms: dis max_nterms
	drop max_nterms

forval x=1/`max_nterms' {
	gen start = strpos(mesh`x', "MajorTopicYN=") + 17
	gen maj = start - 3
	gen end = strpos(mesh`x', "</DescriptorName>")
	gen len = end-start
	gen majortopic = substr(mesh`x', maj, 1)
	replace mesh`x' = substr(mesh`x', start, len)
	replace mesh`x' = "" if majortopic == "N"
	drop start end len maj majortopic
	compress mesh`x', nocoalesce
}
/*
local max_1 = `max_nterms' - 1
forval i = 1/`max_1' {
	local j = `i' + 1
	forval k = `j'/`max_nterms' {
		replace mesh`i' = mesh`k' if mesh`i' == "" & mesh`k' != ""
		replace mesh`k' = "" if mesh`k' == mesh`i'
	}
	compress mesh`i'
}
*/
* Double check pmid 12285838, which supposedly has 26 major mesh topics

*===============================================================================
} // end `mesh'
*===============================================================================

*===============================================================================
* Clean Date Field
if `date' == 1 | `all' == 1 {
*===============================================================================
ren date date_raw
gen start = strpos(date_raw, "<Year>") + 6
gen y = substr(date_raw, start, 4)
	destring y, replace
drop start

gen start = strpos(date_raw, "<Month>") + 7
gen m = substr(date_raw, start, 2)
	destring m, replace
drop start

gen start = strpos(date_raw, "<Day>") + 5
gen d = substr(date_raw, start, 2)
	destring d, replace
drop start

gen date = mdy(m, d, y)
	format date  %td
drop d m y

*===============================================================================
} // end `date'
*===============================================================================

*===============================================================================
* Clean Journals Field
if `journals' == 1 | `all' == 1 {
*===============================================================================
gen journal_na = journal == "NA"
tab journal_na

ren journal journal_raw
gen start = strpos(journal_raw, "<Title>") + 7
gen end = strpos(journal_raw, "</Title>")
gen len = end-start

gen journal = substr(journal_raw, start, len) if start != 7
drop start end len

gen start = strpos(journal_raw, "<ISOAbbreviation>") + 17
gen end = strpos(journal_raw, "</ISOAbbreviation>")
gen len = end-start

gen journal_abbr = substr(journal_raw, start, len) if start != 17
drop start end len

*===============================================================================
} // end `journals'
*===============================================================================

*===============================================================================
* Clean Publication Type Field
if `pub_type' == 1 | `all' == 1 {
*===============================================================================
gen pt_na = pt == "NA"
tab pt_na

ren pt pt_raw
gen start = strpos(pt_raw, "<PublicationType UI=") + 30
gen end = strpos(pt_raw, "</PublicationType>")
gen len = end-start

gen pub_type = substr(pt_raw, start, len)
drop start end len

gen start = strpos(pub_type, ">") + 1
replace pub_type = substr(pub_type, start, .)
drop start
*===============================================================================
} // end `pub_type'
*===============================================================================

*===============================================================================
* Clean Affiliation Field
if `affl' == 1 | `all' == 1 {
*===============================================================================
gen affl_raw = affil
ren affil affl // to work in included do file

cd ../../
include pmid_authaffl_clean.do
cd Amitabh/Master_dta/
*===============================================================================
} // end `affl'
*===============================================================================

*===============================================================================
* Clean Grants Field
if `grants' == 1 | `all' == 1 {
*===============================================================================
gen gr_na = gr == "NA"
tab gr_na

egen ngrants = noccur(gr), string("<Grant>")
	egen max_ngrants = max(ngrants)
	local max_ngrants: dis max_ngrants
	drop max_ngrants
forval i = 1/`max_ngrants' {
	split gr, p("</Grant>") gen(grant) l(1)
	gen start = strlen(grant1) + 1 + 10 // length of "  </Grant>"
	replace gr = substr(gr, start, .)
	
	gen startA = strpos(grant1, "<Agency>") + 8
	gen endA = strpos(grant1, "</Agency>")
	gen lenA = endA - startA
		gen gr_agency`i' = substr(grant1, startA, lenA)
		
	gen startC = strpos(grant1, "<Country>") + 9
	gen endC = strpos(grant1, "</Country>")
	gen lenC = endC-startC
		gen gr_country`i' = substr(grant1, startC, lenC)
		
	drop start* end? len? grant1
}
/*
local n_1 = `max_ngrants' - 1
forval i = 1/`n_1' {
	local k = `i' + 1
	forval j = `k'/`max_ngrants' {
		replace gr_agency`i' = gr_agency`j' ///
			if gr_agency`i' == "" & gr_agency`j' != ""
		replace gr_agency`j' = "" if gr_agency`j' == gr_agency`i'
		
		replace gr_country`i' = gr_country`j' ///
			if gr_country`i' == "" & gr_country`j' != ""
		replace gr_country`j' = "" if gr_country`j' == gr_country`i'
	}
}
*/
drop gr

*===============================================================================
} // end `grants'
*===============================================================================
	save clean_p`I', replace
	pause
} // end looping through temp files

*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
use clean_p1, clear
forval I = 2/13 {
	append using clean_p`I'
}
br
pause
*===============================================================================
* Save
if `save' == 1 {
*===============================================================================
drop *_raw
order pmid date pub_type pt_na journal journal_abbr journal_na ///
	affl country state_name state_abbr city zip cbsacode alt_cbsacode _merge ///
	nterms mesh* ngrants gr_a* gr_c* gr_na

forval i = 1/52 {
	local j = `i' + 1
	forval k = `j'/53 {
		replace mesh`i' = mesh`k' if mesh`i' == "" & mesh`k' != ""
		replace mesh`k' = "" if mesh`k' == mesh`i'
	}
}

forval i = 1/190 {
	local k = `i' + 1
	forval j = `k'/191 {
		replace gr_agency`i' = gr_agency`j' ///
			if gr_agency`i' == "" & gr_agency`j' != ""
		replace gr_agency`j' = "" if gr_agency`j' == gr_agency`i'
		
		replace gr_country`i' = gr_country`j' ///
			if gr_country`i' == "" & gr_country`j' != ""
		replace gr_country`j' = "" if gr_country`j' == gr_country`i'
	}
}

compress *
pause
drop mesh27-mesh53
drop gr_agency36-gr_agency191
drop gr_country5-gr_country191

save "pubmed_master.dta", replace
*===============================================================================
} // end `grants'
*===============================================================================

