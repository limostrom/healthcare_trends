/*
prequin_import.do

Dataset acquired from Prequin (see README.txt)
*/

clear all
set more off
pause on

local tables 0
local plots 1
local guess_stage 0
local investor_tab 0


global repo "C:/Users/lmostrom/Documents/GitHub/healthcare_trends/"
global drop "C:/Users/lmostrom/Dropbox/Amitabh"

cap cd "$drop/VC_Deals/Data"

import excel "PreqinVentureDeals_20200323160505.xlsx", ///
	clear cellra(A14:W36128) first case(lower)

isid venture_id // unique

keep if vcindustryclassification == "Healthcare"
gen dealyear = year(dealdate)

replace primaryindustry = "Biotechnology" ///
	if inlist(primaryindustry, "Biomedical", "Life Sciences", "Medical Technologies")
	/*-------------------------------------------------------------------------
		tab primaryindustry if strpos(subindustries, "Biopolymer") > 0
			// overwhelmingly biotech and pharmaceuticals
		tab primaryindustry if strpos(subindustries, "Medical Diagnostics") > 0
			// overwhelmingly biotech, healthcare, and medical instruments
	---------------------------------------------------------------------------
		keep if primaryindustry == "Healthcare"
		keep subindustries
		split subindustries, p(", ") gen(sub)
			drop subindustries
			gen id = _n
		reshape long sub, i(id) j(termno)
			drop if sub == ""
			tab sub, sort
	-------------------------------------------------------------------------*/

gen stagegrp = "Seed & Angel" if inlist(stage, "Angel", "Seed")
	replace stagegrp = "Series A & B" if ///
						inlist(stage, "Series A/Round 1", "Series B/Round 2")
	replace stagegrp = "Expansion" if inlist(stage, "Venture Debt", "Add-on", ///
			"Series C/Round 3", "Series D/Round 4", "Growth Capital/Expansion")
	replace stagegrp = "Late Stage" if inlist(stage, "Merger", "PIPE", ///
			"Pre-IPO", "Secondary Stock Purchase") | ///
			inlist(stage, "Series E/Round 5", "Series F/Round 6", "Series G/Round 7", ///
						"Series H/Round 8", "Series I/Round 9", "Series J/Round 10")
	replace stagegrp = "Unspecified" if stage == "Unspecified Round"

	/*-------------------------------------------------------------------------
	*** Grants???
		Seed & Angel: combine Seed and Angel
		Series A & B: combine series A + B
		Expansion: combine venture debt+series C+series D + add-on+growth expansion
		Late Stage: PIPE, Series E, F, Merger, pre-ipo,
						G, H, I, J, secondary stock purchase
	-------------------------------------------------------------------------*/
	
keep if inrange(dealyear, 2000, 2019)
pause
tempfile dealset
save `dealset', replace
	
cap mkdir ../Output
	cap mkdir ../Output/raw
	
*=========================================================================
*							TABLES
if `tables' == 1 {
*=========================================================================
local N: dis _N
*----------------------
* PRIMARY INDUSTRY
*----------------------
preserve
	collapse (count) n_deals = venture_id ///
			 (sum) vol_deals = dealsizeusdmn, by(primaryindustry) fast
	egen tot_deals =  sum(n_deals)
		assert tot_deals == `N'
		gen n_deals_pct = n_deals/tot_deals
	egen tot_vol = sum(vol_deals)
		gen vol_deals_pct = vol_deals/tot_vol

	keep primaryindustry n_deals n_deals_pct vol_deals vol_deals_pct
	order primaryindustry n_deals n_deals_pct vol_deals vol_deals_pct
	gsort -n_deals

	export excel "../Output/summ_stats.xlsx", ///
		keepcellfmt sheet("TabInds_raw", replace) first(var) cell(A2)
restore

*-----------
* STAGES
*-----------
preserve
	drop if stagegrp == ""
	collapse (count) n_deals = venture_id ///
			 (sum) vol_deals = dealsizeusdmn, by(stagegrp) fast
	egen tot_deals =  sum(n_deals)
		assert tot_deals == `N' - 1371 // Grants
		gen n_deals_pct = n_deals/tot_deals
	egen tot_vol = sum(vol_deals)
		gen vol_deals_pct = vol_deals/tot_vol

	keep stagegrp n_deals n_deals_pct vol_deals vol_deals_pct
	order stagegrp n_deals n_deals_pct vol_deals vol_deals_pct
	sort stagegrp

	export excel "../Output/summ_stats.xlsx", ///
		keepcellfmt sheet("TabStage_raw", replace) first(var) cell(A2)
		
	replace stagegrp = "" if stagegrp == "Unspecified"
	
restore

*-------------
* LOCATION
*-------------
preserve
	collapse (count) n_deals = venture_id ///
			 (sum) vol_deals = dealsizeusdmn, by(location) fast
	egen tot_deals =  sum(n_deals)
		assert tot_deals == `N'
		gen n_deals_pct = n_deals/tot_deals
	egen tot_vol = sum(vol_deals)
		gen vol_deals_pct = vol_deals/tot_vol

	keep location n_deals n_deals_pct vol_deals vol_deals_pct
	order location n_deals n_deals_pct vol_deals vol_deals_pct
	gsort -n_deals

	export excel "../Output/summ_stats.xlsx", ///
		keepcellfmt sheet("TabCtry_raw", replace) first(var) cell(A2)
restore
preserve
	keep if location == "US"
		local N_US: dis _N
	collapse (count) n_deals = venture_id ///
			 (sum) vol_deals = dealsizeusdmn, by(state) fast
	egen tot_deals =  sum(n_deals)
		assert tot_deals == `N_US'
		gen n_deals_pct = n_deals/tot_deals
	egen tot_vol = sum(vol_deals)
		gen vol_deals_pct = vol_deals/tot_vol

	keep state n_deals n_deals_pct vol_deals vol_deals_pct
	order state n_deals n_deals_pct vol_deals vol_deals_pct
	gsort -n_deals

	export excel "../Output/summ_stats.xlsx", ///
		keepcellfmt sheet("TabState_raw", replace) first(var) cell(A2)
restore
} // end `tables'
*=========================================================================
*							PLOTS
if `plots' == 1 {
*=========================================================================
*------------------ OVERALL -----------------------------------------------
preserve // total deals and volumes over time

#delimit ;
collapse (count) n_deals = venture_id
		 (sum) tot_deals = dealsizeusdmn
		 (mean) avg_deal = dealsizeusdmn avg_totfund = totalknownfundingusdmn
	, by(dealyear) fast;
replace tot_deals = tot_deals/1000; // $ Billions;

tsset dealyear;
tw (tsline n_deals, lc(midblue) lp(l) yaxis(1))
   (tsline tot_deals, lc(dkgreen) lp(_) yaxis(2)),
 legend(order(1 "Number of VC Deals" 2 "Total VC Volume") r(1))
 title("Venture Capital Deals") xti("")
 yti("Number of Deals", axis(1)) yti("Total Volume ($ Billions)", axis(2));  
graph export "../Output/ts_tot_deals.png", replace as(png) wid(1200) hei(700);

tw (tsline avg_deal, lc(cranberry) lp(l))
   (tsline avg_totfun, lc(black) lp(_)),
 legend(order(1 "Avg. VC Deal" 2 "Avg. Total Known Funding") r(1))
 title("Venture Capital Deals") yti("($ Millions)") xti("");
graph export "../Output/ts_avg_deals.png", replace as(png) wid(1200) hei(700);

#delimit cr

restore // ---------------------------
preserve // NIH grants only

keep if stage == "Grant" & strpos(investor, "National Institutes of Health") > 0

#delimit ;
collapse (count) n_deals = venture_id
		 (sum) tot_deals = dealsizeusdmn
		 (mean) avg_deal = dealsizeusdmn avg_totfund = totalknownfundingusdmn
	, by(dealyear) fast;

tsset dealyear;
tw (tsline n_deals, lc(midblue) lp(l) yaxis(1))
   (tsline tot_deals, lc(dkgreen) lp(_) yaxis(2)),
 legend(order(1 "Number of Grants" 2 "Total Grant Volume") r(1))
 title("NIH Grants to Start-Ups") xti("")
 yti("Number of Grants", axis(1)) yti("Total Volume ($ Millions)", axis(2));  
graph export "../Output/ts_nih_grants.png", replace as(png) wid(1200) hei(700);

#delimit cr

restore
*----------------- BY INDUSTRY --------------------------------------------
preserve

#delimit ;
collapse (count) n_deals = venture_id
		 (sum) tot_deals = dealsizeusdmn
	, by(primaryindustry dealyear) fast;
replace tot_deals = tot_deals/1000; // $ Billions;

sort dealyear primaryindustry;
tw (line n_deals dealyear if primaryindustry == "Medical Devices", lc(eltblue) lp(l))
   (line n_deals dealyear if primaryindustry == "Healthcare", lc(purple) lp(-))
   (line n_deals dealyear if primaryindustry == "Healthcare IT", lc(gs7) lp(_))
   (line n_deals dealyear if primaryindustry == "Medical Instruments", lc(dkorange) lp(-))
   (line n_deals dealyear if primaryindustry == "Pharmaceuticals", lc(cranberry) lp(_))
   (line n_deals dealyear if primaryindustry == "Biotechnology", lc(green) lp(l)),
 legend(order(2 "Healthcare" 1 "Medical Devices" 3 "Healthcare IT"
			  4 "Medical Instruments" 5 "Pharmaceuticals" 6 "Biotechnology")
		colfirst r(2))
 title("Venture Capital Deals by Industry") yti("Number of Deals" " ") xti("");
graph export "../Output/ts_n_deals_ByInd.png", replace as(png) wid(1200) hei(700);

tw (line tot_deals dealyear if primaryindustry == "Medical Devices", lc(eltblue) lp(l))
   (line tot_deals dealyear if primaryindustry == "Healthcare", lc(purple) lp(-))
   (line tot_deals dealyear if primaryindustry == "Healthcare IT", lc(gs7) lp(_))
   (line tot_deals dealyear if primaryindustry == "Medical Instruments", lc(dkorange) lp(-))
   (line tot_deals dealyear if primaryindustry == "Pharmaceuticals", lc(cranberry) lp(_))
   (line tot_deals dealyear if primaryindustry == "Biotechnology", lc(green) lp(l)),
 legend(order(2 "Healthcare" 1 "Medical Devices" 3 "Healthcare IT"
			  4 "Medical Instruments" 5 "Pharmaceuticals" 6 "Biotechnology")
		colfirst r(2))
 title("Venture Capital Deals by Industry") yti("Total Deal Volume ($ Billions)" " ") xti("");
graph export "../Output/ts_deal_vol_ByInd.png", replace as(png) wid(1200) hei(700);

#delimit cr

restore // ---------------------------
preserve // NIH grants only

keep if stage == "Grant" & strpos(investor, "National Institutes of Health") > 0

#delimit ;
collapse (count) n_deals = venture_id
		 (sum) tot_deals = dealsizeusdmn
	, by(primaryindustry dealyear) fast;

sort dealyear primaryindustry;
tw (line n_deals dealyear if primaryindustry == "Medical Devices", lc(eltblue) lp(l))
   (line n_deals dealyear if primaryindustry == "Healthcare", lc(purple) lp(-))
   (line n_deals dealyear if primaryindustry == "Healthcare IT", lc(gs7) lp(_))
   (line n_deals dealyear if primaryindustry == "Medical Instruments", lc(dkorange) lp(-))
   (line n_deals dealyear if primaryindustry == "Pharmaceuticals", lc(cranberry) lp(_))
   (line n_deals dealyear if primaryindustry == "Biotechnology", lc(green) lp(l)),
 legend(order(2 "Healthcare" 1 "Medical Devices" 3 "Healthcare IT"
			  4 "Medical Instruments" 5 "Pharmaceuticals" 6 "Biotechnology")
		colfirst r(2))
 title("NIH Grants to Start-Ups by Industry") yti("Number of Grants" " ") xti("");
graph export "../Output/ts_n_nih grants_ByInd.png", replace as(png) wid(1200) hei(700);

tw (line tot_deals dealyear if primaryindustry == "Medical Devices", lc(eltblue) lp(l))
   (line tot_deals dealyear if primaryindustry == "Healthcare", lc(purple) lp(-))
   (line tot_deals dealyear if primaryindustry == "Healthcare IT", lc(gs7) lp(_))
   (line tot_deals dealyear if primaryindustry == "Medical Instruments", lc(dkorange) lp(-))
   (line tot_deals dealyear if primaryindustry == "Pharmaceuticals", lc(cranberry) lp(_))
   (line tot_deals dealyear if primaryindustry == "Biotechnology", lc(green) lp(l)),
 legend(order(2 "Healthcare" 1 "Medical Devices" 3 "Healthcare IT"
			  4 "Medical Instruments" 5 "Pharmaceuticals" 6 "Biotechnology")
		colfirst r(2))
 title("NIH Grants to Start-Ups by Industry") yti("Total Grant Volume ($ Millions)" " ") xti("");
graph export "../Output/ts_nih_grant_vol_ByInd.png", replace as(png) wid(1200) hei(700);

#delimit cr

restore
*---------- FUNDING STAGES BY INDUSTRY AND YEAR --------------------------------

drop if stagegrp == ""
replace stagegrp = subinstr(stagegrp, " ", "", .)
replace stagegrp = subinstr(stagegrp, "&", "", .)
collapse (count) n_deals = venture_id, by(primaryindustry stagegrp dealyear) fast

levelsof primaryindustry, local(inds)

foreach ind of local inds {
		preserve
		keep if primaryindustry == "`ind'"
		replace n_deals = 0 if n_deals == .
		reshape wide n_deals, i(dealyear) j(stagegrp) string
		* For stacked area plots
			gen n_adj_SeedAngel = n_dealsSeedAngel
			gen n_adj_SeriesAB = n_dealsSeedAngel + n_dealsSeriesAB
			gen n_adj_Expansion = n_dealsSeedAngel + n_dealsSeriesAB ///
									+ n_dealsExpansion
			gen n_adj_LateStage = n_dealsSeedAngel + n_dealsSeriesAB ///
									+ n_dealsExpansion + n_dealsLateStage
			gen n_adj_Unspecified = n_dealsSeedAngel + n_dealsSeriesAB ///
									+ n_dealsExpansion + n_dealsLateStage + n_dealsUnspecified
		sort dealyear		
		#delimit ;
		tw (area n_adj_LateStage dealyear, col(green))
		   (area n_adj_Expansion dealyear, col(dkorange))
		   (area n_adj_SeriesAB dealyear, col(edkblue))
		   (area n_adj_SeedAngel dealyear, col(maroon)),
		 legend(order(4 "Seed & Angel" 3 "Series A & B" 2 "Expansion" 1 "Late Stage")
				r(1) symy(small) symx(small))
		 ti("Venture Capital Deals by Funding Stage" "`ind'")
		 yti("Number of Deals" " ") xti("");
		graph export "../Output/ts_deals_by_stage-`ind'.png", replace as(png) wid(1200);
		
		tw (area n_adj_Unspecified dealyear, col(gs8))
		   (area n_adj_LateStage dealyear, col(green))
		   (area n_adj_Expansion dealyear, col(dkorange))
		   (area n_adj_SeriesAB dealyear, col(edkblue))
		   (area n_adj_SeedAngel dealyear, col(maroon)),
		 legend(order(5 "Seed & Angel" 4 "Series A & B" 3 "Expansion" 2 "Late Stage"
						1 "Unspecified") r(1) symy(small) symx(small))
		 ti("Venture Capital Deals by Funding Stage" "`ind'")
		 yti("Number of Deals" " ") xti("");
		graph export "../Output/ts_deals_by_stage_wUn-`ind'.png", replace as(png) wid(1200) hei(700);
		#delimit cr
		restore
}

replace n_deals = 0 if n_deals == .
collapse (sum) n_deals, by(stagegrp dealyear) fast
reshape wide n_deals, i(dealyear) j(stagegrp) string
* For stacked area plots
	gen n_adj_SeedAngel = n_dealsSeedAngel
	gen n_adj_SeriesAB = n_dealsSeedAngel + n_dealsSeriesAB
	gen n_adj_Expansion = n_dealsSeedAngel + n_dealsSeriesAB ///
							+ n_dealsExpansion
	gen n_adj_LateStage = n_dealsSeedAngel + n_dealsSeriesAB ///
							+ n_dealsExpansion + n_dealsLateStage
	gen n_adj_Unspecified = n_dealsSeedAngel + n_dealsSeriesAB ///
							+ n_dealsExpansion + n_dealsLateStage + n_dealsUnspecified
sort dealyear
#delimit ;
tw (area n_adj_LateStage dealyear, col(green))
   (area n_adj_Expansion dealyear, col(dkorange))
   (area n_adj_SeriesAB dealyear, col(edkblue))
   (area n_adj_SeedAngel dealyear, col(maroon)),
 legend(order(4 "Seed & Angel" 3 "Series A & B" 2 "Expansion" 1 "Late Stage")
				r(1) symy(small) symx(small))
 ti("Venture Capital Deals by Funding Stage" "All Industries")
 yti("Number of Deals" " ") xti("");
graph export "../Output/ts_deals_by_stage-All.png", replace as(png) wid(1200) hei(700);

tw (area n_adj_Unspecified dealyear, col(gs8))
   (area n_adj_LateStage dealyear, col(green))
   (area n_adj_Expansion dealyear, col(dkorange))
   (area n_adj_SeriesAB dealyear, col(edkblue))
   (area n_adj_SeedAngel dealyear, col(maroon)),
 legend(order(5 "Seed & Angel" 4 "Series A & B" 3 "Expansion" 2 "Late Stage"
				1 "Unspecified") r(1) symy(small) symx(small))
 ti("Venture Capital Deals by Funding Stage" "All Industries")
 yti("Number of Deals" " ") xti("");
graph export "../Output/ts_deals_by_stage_wUn-All.png", replace as(png) wid(1200) hei(700);
#delimit cr

*---------- INDUSTRY DISTRIBUTION OF NIH GRANTS TO START-UPS -------------------
use `dealset', clear

cap mkdir "../Output/gphs/"

keep if stage == "Grant" & strpos(investor, "National Institutes of Health") > 0
local N: dis _N

collapse (count) n_deals = venture_id (sum) deal_vol = dealsizeusdmn ///
	, by(primaryindustry) fast

#delimit ;
graph pie n_deals, over(primaryindustry)
	pl(1 percent, c(white) format(%9.3g) size(medium))
	pl(2 percent, c(white) format(%9.3g) size(medium))
	pl(3 percent, c(white) format(%9.3g) size(medium))
	pl(4 percent, c(white) format(%9.3g) size(medium) gap(small))
	pl(5 percent, c(white) format(%9.3g) size(medium))
	pl(6 percent, c(white) format(%9.3g) size(medium))
	title("NIH Grants to Start-Ups") legend(colfirst)
	subtitle("Share by Number of Grants" "`N' Grants Total")
	pie(1, c(green)) pie(2, c(sienna)) pie(3, c(dkorange))
	pie(4, c(edkblue)) pie(5, c(eltblue)) pie(6, c(cranberry));
graph save "../Output/gphs/nih_grants_pie.gph", replace;
graph export "../Output/nih_grants_pie.png", replace as(png);

graph pie deal_vol, over(primaryindustry)
	pl(1 percent, c(white) format(%9.3g) size(medium))
	pl(2 percent, c(white) format(%9.3g) size(medium))
	pl(3 percent, c(white) format(%9.3g) size(medium))
	pl(4 percent, c(white) format(%9.3g) size(medium) gap(small))
	pl(5 percent, c(white) format(%9.3g) size(medium))
	pl(6 percent, c(white) format(%9.3g) size(medium))
	title("NIH Grants to Start-Ups") legend(colfirst)
	subtitle("Share by Grant Volume ($)" "`N' Grants Total")
	pie(1, c(green)) pie(2, c(sienna)) pie(3, c(dkorange))
	pie(4, c(edkblue)) pie(5, c(eltblue)) pie(6, c(cranberry));
graph save "../Output/gphs/nih_grant_vol_pie.gph", replace;
graph export "../Output/nih_grant_vol_pie.png", replace as(png);
#delimit cr

grc1leg "../Output/gphs/nih_grants_pie.gph" ///
		"../Output/gphs/nih_grant_vol_pie.gph", r(1)
graph export "../Output/nih_grant_pies_combined.png", replace as(png)

} // end `plots'
*=========================================================================
*						GUESS MISSING FUNDING STAGE
if `guess_stage' == 1 {
*=========================================================================
/* ---------------------- USING INDUSTRY AND YEAR -------------------------
drop if stagegrp == ""
replace stagegrp = subinstr(stagegrp, " ", "", .)
collapse (count) n_deals = venture_id, by(primaryindustry stagegrp dealyear) fast
keep if inrange(dealyear, 1990, 2019)

levelsof primaryindustry, local(inds)

foreach ind of local inds {
	preserve
	keep if primaryindustry == "`ind'"
	replace n_deals = 0 if n_deals == .
	reshape wide n_deals, i(dealyear) j(stagegrp) string
	* For stacked area plots
		gen n_adj_Early = n_dealsEarly
		gen n_adj_EarlySeed = n_dealsEarly + n_dealsEarlySeed
		gen n_adj_Expansion = n_dealsEarly + n_dealsEarlySeed ///
								+ n_dealsExpansion
		gen n_adj_LateStage = n_dealsEarly + n_dealsEarlySeed ///
								+ n_dealsExpansion + n_dealsLateStage
	sort dealyear							
	*------------------------------------------------
	if "`ind'" == "Biotechnology" local ind_abbr "B"
	if "`ind'" == "Pharmaceuticals" local ind_abbr "P"
	if "`ind'" == "Healthcare" local ind_abbr "HC"
	if "`ind'" == "Healthcare IT" local ind_abbr "HCIT"
	if "`ind'" == "Medical Devices" local ind_abbr "MD"
	if "`ind'" == "Medical Instruments" local ind_abbr "MI"
	
	foreach st in "Early" "EarlySeed" "Expansion" "LateStage" {
		gen csh_`st' = n_adj_`st'/n_adj_LateStage
	}
	gen cut0 = 0
		ren csh_Early cut1
		ren csh_EarlySeed cut2
		ren csh_Expansion cut3
		ren csh_LateStage cut4
		drop if cut4 == .
		assert cut4 == 1
		
	order dealyear cut0 cut1 cut2 cut3 cut4
	sort dealyear
		local minyr`ind_abbr': dis dealyear
	mkmat dealyear cut?, mat(mat`ind_abbr') obs
	matlist mat`ind_abbr'
	restore
}

use `dealset', clear

gen guess_stagegrp = ""
set seed 123
gen rand = runiform()

foreach ind of local inds {
	if "`ind'" == "Biotechnology" local ind_abbr "B"
	if "`ind'" == "Pharmaceuticals" local ind_abbr "P"
	if "`ind'" == "Healthcare" local ind_abbr "HC"
	if "`ind'" == "Healthcare IT" local ind_abbr "HCIT"
	if "`ind'" == "Medical Devices" local ind_abbr "MD"
	if "`ind'" == "Medical Instruments" local ind_abbr "MI"

	local Y = rowsof(mat`ind_abbr')
	forval y = 1/`Y' {
		forval j = 3/6 { // matrix columns
			local j_1 = `j' - 1
			
			replace guess_stagegrp = "`j'" if stagegrp == "" ///
				& inrange(rand, mat`ind_abbr'[`y',`j_1'], mat`ind_abbr'[`y',`j']) ///
				& primaryindustry == "`ind'" & dealyear == mat`ind_abbr'[`y',1]
			dis "`ind'"
			matlist matB[`y',`j_1']
			matlist matB[`y',`j']
			
		} // `j'
	} // `y'
	
} // `ind'

replace guess_stagegrp = "Early" if guess_stagegrp == "3"
replace guess_stagegrp = "Early Seed" if guess_stagegrp == "4"
replace guess_stagegrp = "Expansion" if guess_stagegrp == "5"
replace guess_stagegrp = "Late Stage" if guess_stagegrp == "6"

pause

*------------------------------------------------------------------------------*/

* ------------------------- USING PERCENTILE BINS ------------------------------

drop if stagegrp == ""
replace stagegrp = subinstr(stagegrp, " ", "", .)
xtile pctl_bin = dealsizeusdmn, n(20)

collapse (count) n_deals = venture_id, by(stagegrp pctl_bin) fast

preserve
	replace n_deals = 0 if n_deals == .
	reshape wide n_deals, i(pctl_bin) j(stagegrp) string
	* For stacked area plots
		gen n_adj_Early = n_dealsEarly
		gen n_adj_EarlySeed = n_dealsEarly + n_dealsEarlySeed
		gen n_adj_Expansion = n_dealsEarly + n_dealsEarlySeed ///
								+ n_dealsExpansion
		gen n_adj_LateStage = n_dealsEarly + n_dealsEarlySeed ///
								+ n_dealsExpansion + n_dealsLateStage
	sort pctl_bin							
	
	foreach st in "Early" "EarlySeed" "Expansion" "LateStage" {
		gen csh_`st' = n_adj_`st'/n_adj_LateStage
	}
	gen cut0 = 0
		ren csh_Early cut1
		ren csh_EarlySeed cut2
		ren csh_Expansion cut3
		ren csh_LateStage cut4
		drop if cut4 == .
		assert cut4 == 1
		
	order pctl_bin cut0 cut1 cut2 cut3 cut4
	sort pctl_bin
	mkmat pctl_bin cut?, mat(matPct) obs
	matlist matPct
restore

use `dealset', clear
xtile pctl_bin = dealsizeusdmn, n(20)

gen guess_stagegrp = ""
set seed 123
gen rand = runiform()

local P = rowsof(matPct)
forval p = 1/`P' {
		forval j = 3/6 { // matrix columns
			local j_1 = `j' - 1
			
			replace guess_stagegrp = "`j'" if stagegrp == "" ///
				& inrange(rand, matPct[`p',`j_1'], matPct[`p',`j']) ///
				& pctl_bin == matPct[`p',1]
			dis "`p'"
			matlist matPct[`p',`j_1']
			matlist matPct[`p',`j']
			
		} // `j'
} // `p'

replace guess_stagegrp = "Seed & Angel" if guess_stagegrp == "3"
replace guess_stagegrp = "Series A & B" if guess_stagegrp == "4"
replace guess_stagegrp = "Expansion" if guess_stagegrp == "5"
replace guess_stagegrp = "Late Stage" if guess_stagegrp == "6"

pause

*--------------------------------------------------------------------------------/

} // end `guess_stage'
*=========================================================================
*					TAB INVESTORS TO 
if `investor_tab' == 1 {
*=========================================================================

use `dealset', clear

replace stagegrp = "Grant" if stage == "Grant"

split investors, p(", ") gen(investor)
	drop investors
	keep venture_id stagegrp investor*
reshape long investor, i(venture_id stagegrp) j(i)
	drop if investor == ""

collapse (count) n = venture_id, by(investor stagegrp) fast
	replace stagegrp = subinstr(stagegrp, " ", "", .)
	replace stagegrp = subinstr(stagegrp, "&", "", .)
reshape wide n, i(investor) j(stagegrp) string

} // end `investor_tab'