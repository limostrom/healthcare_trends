/*
prequin_import.do

Dataset acquired from Prequin (see README.txt)
*/

global repo "C:/Users/lmostrom/Documents/GitHub/healthcare_trends/"
global drop "C:/Users/lmostrom/Dropbox/Amitabh"

cap cd "$drop/VC_Deals/"

*=========================================================================
*							IMPORT
*=========================================================================
local filelist: dir "Data" files "Preqin_deals_export_*.xlsx"

local ii 1
foreach file of local filelist {
	import excel "Data/`file'", clear first case(lower)
	    if `ii' == 1 {
			tempfile deals
			save `deals', replace
		}
		if `ii' > 1 {
		    append using `deals'
			save `deals', replace
		}
	local ++ii
}

isid dealid // unique

gen dealyear = year(dealdate)
gen dealmonth = month(dealdate)
gen datem = ym(dealyear, dealmonth)

* Convert Deal Sizes to 2020 USD
preserve
	import delimited "Data/CPIMEDSL.csv", clear varn(1) case(upper)
		gen year = substr(DATE, 1, 4)
			destring year, replace
		gen month = substr(DATE, 6, 2)
			destring month, replace
		gen datem = ym(year, month)
			format %tm datem
			drop year month DATE
			
		gen CPIMEDSL2020 = CPIMEDSL if datem == tm(2020m1)
			ereplace CPIMEDSL2020 = max(CPIMEDSL2020)
		tempfile cpimed
		save `cpimed', replace
	
	import delimited "Data/PCEPILFE.csv", clear varn(1) case(upper)
		gen year = substr(DATE, 1, 4)
			destring year, replace
		gen month = substr(DATE, 6, 2)
			destring month, replace
		gen datem = ym(year, month)
			format %tm datem
			drop year month DATE
			
		gen PCEPILFE2020 = PCEPILFE if datem == tm(2020m1)
			ereplace PCEPILFE2020 = max(PCEPILFE2020)
		tempfile pce
		save `pce', replace
		
	import delimited "Data/CPIAUCSL.csv", clear varn(1) case(upper)
		gen year = substr(DATE, 1, 4)
			destring year, replace
		gen month = substr(DATE, 6, 2)
			destring month, replace
		gen datem = ym(year, month)
			format %tm datem
			drop year month DATE
			
		gen CPIAUCSL2020 = CPIAUCSL if datem == tm(2020m1)
			ereplace CPIAUCSL2020 = max(CPIAUCSL2020)
		tempfile cpiaucsl
		save `cpiaucsl', replace
restore

merge m:1 datem using `cpimed', nogen keep(1 3)
merge m:1 datem using `pce', nogen keep(1 3)
merge m:1 datem using `cpiaucsl', nogen keep(1 3)

gen dealsizeusdmn_raw = dealsizeusdmn

save "preqin_deals_2000_2019.dta", replace
*=========================================================================




