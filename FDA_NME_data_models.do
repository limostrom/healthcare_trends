/*

FDA_NME_data_models.do

The model would try to explain approval time for a drug (in days),
as a function of year fixed effects (separate models for NDA and BLA).
If a drug has multiple indications, we treat them as separate
observations but cluster on the drug. 

Next, we add controls for fast track, breakthrough and accelerated
approval and see if these year effects change
(still have separate models for NDA and BLA).


*/

cap log close
clear all
set more off
pause on

global repo "C:\Users\lmostrom\Documents\GitHub\healthcare_trends\"
global dropbox "C:\Users\lmostrom\Dropbox\Amitabh\FDA NME Data\"

cap cd "$dropbox"

*=========================================================================
* Read in dataset
* https://www.fda.gov/drugs/drug-approvals-and-databases/compilation-cder-new-molecular-entity-nme-drug-and-new-biologic-approvals
*=========================================================================
import delimited "Compilation of CDER NME and New Biologic Approvals 1985-2019.csv", ///
	varn(1) clear bindquote(strict)
		// some indications span multiple lines - bindquote strict keeps them together

ren ïproprietaryname drug_name

gen fda_receipt = date(fdareceiptdate, "MDY")
 	format %td fda_receipt
gen fda_approval = date(fdaapprovaldate, "MDY")
 	format %td fda_approval

gen days_to_approval = fda_approval - fda_receipt
gen application_year = year(fda_receipt)

ren acceleratedapproval accel
ren breakthroughtherapydesignation brkthru
ren fasttrackdesignation fast
ren applicationnumber1 app_no

assert abbreviatedindications == "" if approveduses != ""
assert approveduses == "" if abbreviatedindications != ""

gen bla = ndabla == "BLA"

gen uses = abbreviatedindications
	replace uses = approveduses if abbreviatedindications == ""

keep drug_name app_no bla days_to_approval application_year ///
		uses accel brkthru fast

gen byte indicationA = 1
expand 2 if strpos(uses, "[B]") > 0, gen(indicationB)
	replace indicationA = 0 if indicationB == 1
expand 2 if strpos(uses, "[C]") > 0 & indicationA, gen(indicationC)
	replace indicationA = 0 if indicationC == 1

foreach var in accel brkthru fast {
	gen orig = `var'
	tab `var'
	foreach abc in A B C {
		replace `var' = "Yes" if strpos(orig, "Yes (") > 0 ///
							& strpos(orig, "`abc'") > 0 & indication`abc'
		replace `var' = "No" if strpos(orig, "Yes (") > 0 ///
							& strpos(orig, "`abc'") == 0 & indication`abc'

	}
	drop orig
	gen `var'_cat = 0 if `var' == "No"
		replace `var'_cat = 1 if `var' == "Yes"
}

eststo reg1: reg days_to_approval ib0.bla ib2019.application_year, cluster(app_no)
local x = 2
local control_list ""
foreach control in accel brkthru fast {
	eststo reg`x': reg days_to_approval ib0.bla ib0.`control'_cat ///
							ib2019.application_year, cluster(app_no)
	local ++x
	local control_list "`control_list' ib0.`control'_cat"
}
eststo reg`x': reg days_to_approval ib0.bla `control_list' ///
							ib2019.application_year, cluster(app_no)

esttab reg? using basic_regs.csv, replace ///
		b se star(+ 0.10 * 0.05 ** 0.01 *** 0.001) mtitles(base accelerated breakthrough fast_track full)