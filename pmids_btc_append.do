/*

*/


local filelist: dir "PubMed/PMIDs/BTC/" files "PMIDs_BTC_*.csv"

local i = 1
foreach file of local filelist {
	dis "`file'"
	import delimited pmid query_name using "PubMed/PMIDs/BTC/`file'", rowr(2:) clear
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
		local ++i
	}
}

use `full_pmids', clear

gen year = substr(query_name, -4, 4)
	destring year, replace
split query_name, p("_")
gen nih = substr(query_name2, 1, 3) == "NIH"
drop query_name query_name2
	ren query_name1 btc

replace pmid = pmid*1000 if inlist(btc, "total", "totalCTs")
duplicates tag pmid, gen(dup)
gen nothc = btc != "healthcare" if dup > 0
	bys pmid: egen tot_nothc = total(nothc)
	drop if dup & btc == "healthcare" & tot_nothc > 0
	drop dup
duplicates tag pmid, gen(dup)
gen clin = btc == "clinical" if dup > 0
	bys pmid: egen tot_clin = total(clin)
	drop if btc == "translational" & tot_clin > 0 & dup
	drop dup tot_clin clin tot_nothc nothc
bys pmid btc: egen minyr = min(year)
	drop if year > minyr
isid pmid
replace pmid = pmid/1000 if inlist(btc, "total", "totalCTs")

save "PubMed/Master_dta/pmids_bas_trans_clin_notQA.dta", replace





