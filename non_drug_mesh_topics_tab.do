/*
non_drug_mesh_topics_tab.do

*/

clear all
set more off
pause on

cap cd "C:\Users\lmostrom\Dropbox\Amitabh\PubMed"
global repo "C:/Users/lmostrom/Documents/GitHub/healthcare_trends/"


*=========================================================================
* 
*=========================================================================
/*
local filelist: dir "PMIDs/PieCharts/" files "PMIDs_drugs_devices_*.csv"

local i = 1
foreach file of local filelist {
	import delimited /*pmid query_name*/ using "PMIDs/PieCharts/`file'", rowr(2:) clear
	dis "`file'"
	if _N > 0 {
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

ren unlistpmidsi pmid
ren repquery query_name
drop if v1 == "NA"
	destring v1, replace
replace pmid = v1 if pmid == .
replace query_name = v2 if query_name == ""
assert pmid != . & query_name != ""
	drop v1 v2
gen year = substr(query_name, -4, .)
	destring year, replace
isid pmid year
save `full_pmids', replace

use Master_dta/pubmed_master.dta, clear
	gen year = year(date)
	duplicates drop
	drop if year == .
	duplicates tag pmid year, gen(dup)
	drop if pmid == 30240725 & dup & gr_agency2 == ""
	drop if pmid == 23180166 & dup & cbsacode == .
	isid pmid year
	merge 1:1 pmid year using `full_pmids', keep(3) nogen

drop if substr(query_name, -6, 2) == "CT"
	split query_name, p("_")
	drop query_name query_name2
	ren query_name1 category

save "therapy_chem_bio_from_master.dta", replace
*/

use "therapy_chem_bio_from_master.dta", clear

foreach cat in "bio" "chem" "therapy" {
	preserve
		keep if category == "`cat'"
		keep pmid mesh* category
		drop mesh_na
		reshape long mesh, i(pmid category) j(termno)
		drop if mesh == ""
		fre mesh, descending t(50)
		if "`cat'" == "bio" {
			drop if inlist(mesh, "Disease Outbreaks", "Seasons", ///
				"Body Mass Index")
			gen group = "Models" if strpos(mesh, "Models,") > 0
			replace group = "Genetics" if ///
				inlist(substr(mesh, 1, 7), "Genes, ", "Genome,") ///
				| strpos(mesh, "Genetic") > 0 ///
				| strpos(mesh, "Gene ") > 0
			replace group = "Genetics" if group == "" ///
				& (strpos(mesh, "Chromosome") > 0 ///
				| strpos(mesh, "Mutation") > 0)
			replace group = "Psychology" if group == "" ///
				& (strpos(mesh, "Psych") > 0 ///
				| 
			replace group = "Evolution" if group == "" ///
				& (strpos(mesh, "Evolution") > 0 ///
				| strpos(mesh, "Phylogeny") > 0)
			replace group = "Microbiology" if group == "" ///
				& strpos(mesh, "Microbiology") > 0
			replace group = "Environment" if group == "" ///
				& (strpos(mesh, "Environment") > 0 ///
				| strpos(mesh, "Climate Change") > 0)
			replace group = "Ecosystem" if group == "" ///
				& (strpos(mesh, "Ecosystem") > 0 ///
				| strpos(mesh, "Biodiversity") > 0)
			replace group = "Computer-Assisted Biology" if group == "" ///
				& strpos(mesh, "Computer") > 0
			replace group = "Cells" if group == "" ///
				& strpos(mesh, "Cell ") > 0
			replace group = "Development" if group == "" ///
				& inlist(mesh, "Aging", "Child Development")
			replace group = "Cardiovascular System" if group == "" ///
				& (inlist(mesh, "Blood Pressure") ///
				| strpos(mesh, "Myocardial") > 0 ///
				| strpos(mesh, "Cardio") > 0)
			replace group = "Respiratory System" if group == "" ///
				& strpos(mesh, "Respirat") > 0
			replace group = "Adaptation" if group == "" ///
				& strpos(mesh, "Adaptation") > 0
			replace group = "Nutrition" if group == "" ///
				& inlist(mesh, "Diet")
			replace group = "Metabolism" if group == "" ///
				& strpos(mesh, "Metabolism") > 0
			replace group = "Viruses" if group == "" ///
				& (strpos(mesh, "Virus") > 0 /// 
				| strpos(mesh, "Viral") > 0)
			tab group, sort
		}
		if "`cat'" == "chem" {
			drop if inlist(mesh, "Mutation", "Apoptosis", "Phylogeny", ///
				"Oxidative Stress", "Light", "Software", "Algorithms") ///
				| strpos(lower(mesh), "gene") > 0 ///
				| strpos(mesh, "Cell") > 0 ///
				| strpos(mesh, "Virus") > 0 ///
				| strpos(lower(mesh), "polymorphism") > 0 ///
				| substr(mesh, 1, 7) == "Models," ///
				| substr(mesh, 1, 10) == "Evolution," ///
				| strpos(mesh, "Microbio") > 0
			gen group = "Proteins" if strpos(mesh, "Protein") > 0 ///
				| strpos(mesh, "protein") > 0
			replace group = "Proteins" if strpos(mesh, "Antibodies") > 0
			replace group = "Proteins" if strpos(mesh, "Transcription Factor") > 0
			replace group = "Nucleic Acids" if group == "" ///
				& (strpos(mesh, "DNA") > 0 | strpos(mesh, "RNA") > 0 ///
				| strpos(mesh, "Nucleic Acid") > 0)
			replace group = "Signal Transduction" if group == "" ///
				& mesh == "Signal Transduction"
			replace group = "Amino Acids" if group == "" ///
				& (strpos(mesh, "Amino") > 0 ///
				| strpos(mesh, "amine") > 0)
			tab group, sort
		}

		pause
	restore
}


*=========================================================================




