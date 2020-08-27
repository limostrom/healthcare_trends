/*
merge_drugs_devices_QA_list.do

*/

*============================================================================
if `drugs_and_devices' == 1 {
*============================================================================
/*
local filelist: dir "PubMed/PMIDs/PieCharts/" files "PMIDs_drugs_devices_*.csv"

local i = 1
foreach file of local filelist {
	import delimited pmid query_name using "PubMed/PMIDs/PieCharts/`file'", rowr(2:) clear
	dis "`file'"
	if _N > 0 {
		tostring pmid, replace // might already be string
		drop if pmid == "NA"
		destring pmid, replace

		if `i' == 1 {
			tempfile dd_pmids
			save `dd_pmids', replace 
		}
		if `i' > 1 {
			append using `dd_pmids'
			save `dd_pmids', replace
		}
		local ++i
	}
}

use `dd_pmids', clear
	gen year = substr(query_name, -4, 4)
		destring year, replace
	ren query_name ddcat
save `dd_pmids', replace
save "PubMed/Master_dta/pmids_drugs_devices.dta", replace
*/
} // ------------------------------------------------------------------------
*============================================================================
local filelist: dir "PubMed/PMIDs/QA/" files "PMIDs_all_TotalQA_????.csv"

local i = 1
foreach file of local filelist {
	import delimited pmid query_name using "PubMed/PMIDs/QA/`file'", rowr(2:) clear
	dis "`file'"
	if _N > 0 {
		tostring pmid, replace // might already be string
		drop if pmid == "NA"
		destring pmid, replace

		if `i' == 1 {
			tempfile qa_pmids
			save `qa_pmids', replace 
		}
		if `i' > 1 {
			append using `qa_pmids'
			save `qa_pmids', replace
		}
		local ++i
	}
}
use `qa_pmids', clear
	gen year = substr(query_name, -4, 4)
		destring year, replace
save `qa_pmids', replace
*============================================================================
/*
local filelist: dir "PubMed/PMIDs/Funding/" files "PMIDs_all_4grpsCorporation????.csv"

local i = 1
foreach file of local filelist {
	import delimited pmid query_name using "PubMed/PMIDs/Funding/`file'", rowr(2:) clear
	dis "`file'"
	if _N > 0 {
		tostring pmid, replace // might already be string
		drop if pmid == "NA"
		destring pmid, replace

		if `i' == 1 {
			tempfile corp_pmids
			save `corp_pmids', replace 
		}
		if `i' > 1 {
			append using `corp_pmids'
			save `corp_pmids', replace
		}
		local ++i
	}
}
use `corp_pmids', clear
	gen year = substr(query_name, -4, 4)
		destring year, replace
save `corp_pmids', replace
*============================================================================
local filelist: dir "PubMed/PMIDs/Funding/" files "PMIDs_all_4grpsNIH????.csv"

local i = 1
foreach file of local filelist {
	import delimited pmid query_name using "PubMed/PMIDs/Funding/`file'", rowr(2:) clear
	dis "`file'"
	if _N > 0 {
		tostring pmid, replace // might already be string
		drop if pmid == "NA"
		destring pmid, replace

		if `i' == 1 {
			tempfile nih_pmids
			save `nih_pmids', replace 
		}
		if `i' > 1 {
			append using `nih_pmids'
			save `nih_pmids', replace
		}
		local ++i
	}
}
use `nih_pmids', clear
	gen year = substr(query_name, -4, 4)
		destring year, replace
save `nih_pmids', replace
*/
*============================================================================