/*
preqin_tables_plots

*/

local save_msa_dta 0 // sum VC $s by MSA-Year for Cirrus to merge w/ patent data

local tables 0
local plots 0
local plots_byloc 1
local plots_topinv 0

*local guess_stage 0 // don't use
*local investor_tab 0 // don't use



*=========================================================================
*						SAVING MSA DATASET
if `save_msa_dta' == 1 {
*=========================================================================
use dealid dealyear dealsizeusdmn CPIAUCSL2020 CPIAUCSL ///
	industryclassification primaryindustry ///
	portfoliocompanycountry portfoliocompanystate portfoliocompanycity ///
	using "preqin_deals_2000_2019.dta", clear
keep if industryclassification == "Healthcare"

replace primaryindustry = "Biotechnology" if primaryindustry == "Biopolymers"
replace primaryindustry = "Healthcare" if primaryindustry == "Healthcare Specialists"

keep if strpos(portfoliocompanycountry, "US") > 0

include "$repo/preqin_foreign_states_countries.do"

/*
egen n_cities = noccur(portfoliocompanycity), string(",")
			replace n_cities = n_cities + 1 if portfoliocompanycity != ""
			replace dealsizeusdmn = dealsizeusdmn/n_cities

			
foreach city of local foreign_cities {
	replace portfoliocompanycity = subinstr(portfoliocompanycity, ", `city'", "", .) ///
		if portfoliocompanycountry != "US"
	replace portfoliocompanycity = subinstr(portfoliocompanycity, "`city', ", "", .) ///
		if portfoliocompanycountry != "US"
}
foreach state of local foreign_states {
	replace portfoliocompanystate = subinstr(portfoliocompanystate, ", `state'", "", .) ///
		if portfoliocompanycountry != "US"
	replace portfoliocompanystate = subinstr(portfoliocompanystate, "`state', ", "", .) ///
		if portfoliocompanycountry != "US"
}
*/
ren portfoliocompanycity city
*reshape long city, i(dealid dealsizeusdmn portfoliocompanystate) j(cityno)
	*drop if city == ""
	replace city = "Ann Arbor" if city == "Ann Arbour"
	replace city = "Palo Alto" if city == "Menlo Park"
	replace city = "San Diego" if city == "La Jolla"
	replace city = "San Mateo" if city == "Portola Valley"
	replace city = "Philadelphia" if city == "Conshohocken"
ren portfoliocompanystate state_abbr
	replace city = "Boston" if city == "Lexington" & state == "MA"

/*
forval ii = 1/9 {
	ren state_abbr`ii' state_abbr
	merge m:1 city state_abbr using "../PubMed/MSA_city_state_clean.dta", ///
			keep(1 3) keepus(cbsacode) nogen
		destring cbsacode, replace
		ren cbsacode cbsacode`ii'
		replace msa = cbsacode`ii' if cityno == `ii'
	ren state_abbr state_abbr`ii'
}
*/
/*
gen state_abbr = ""
forval ii = 1/9 {
	replace state_abbr = state_abbr`ii' if cityno == `ii' & msa != .
}

bys city: ereplace state_abbr = mode(state_abbr)
	replace state_abbr = "" if !inlist(state_abbr, state_abbr1, state_abbr2, ///
			state_abbr3, state_abbr4, state_abbr5, state_abbr6, ///
			state_abbr7, state_abbr8, state_abbr9)
*/
	merge m:1 city state_abbr using "../PubMed/MSA_city_state_clean.dta", ///
			keep(1 3) keepus(cbsacode) nogen
	destring cbsacode, replace
	*replace msa = cbsacode if msa == .


bys cbsacode: egen mode_city = mode(city), minmode
	replace mode_city = "Boston" if mode_city == "Cambridge" & state == "MA"
	replace mode_city = "Los Angeles" if mode_city == "Irvine" & state == "CA"
	replace mode_city = "San Jose" if mode_city == "Palo Alto" & state == "CA"
bys cbsacode: egen mode_state = mode(state_abbr), minmode
replace mode_city = "" if cbsacode == .
replace mode_state = "" if cbsacode == .

gen dealsize_na = dealsizeusdmn == .
tab dealsize_na

replace dealsizeusdmn = 0 if dealsizeusdmn == .

gen dealsizeusdmn_raw = dealsizeusdmn
	drop dealsizeusdmn
gen dealsizeusdmn_2020 = dealsizeusdmn_raw*CPIAUCSL2020/CPIAUCSL

			
foreach dollars in "raw" "2020" {
	bys dealyear industryclass cbsacode: egen deals_`dollars'USDmnHealthcare = total(dealsizeusdmn_`dollars')
	foreach ind in "Biotechnology" "Pharmaceuticals" {
		bys dealyear primaryindustry cbsacode: ///
			egen deals_`dollars'USDmn`ind' = total(dealsizeusdmn_`dollars') ///
				if primaryindustry == "`ind'"
		bys dealyear cbsacode: ereplace deals_`dollars'USDmn`ind' = max(deals_`dollars'USDmn`ind')
		replace deals_`dollars'USDmn`ind' = 0 if deals_`dollars'USDmn`ind' == .
	}
}

sort dealyear cbsacode primaryindustry

collapse (last) deals_*USDmn* city = mode_city state = mode_state, by(cbsacode dealyear)

reshape long deals_rawUSDmn deals_2020USDmn, i(cbsacode city state dealyear) j(class) string
sort dealyear city state
order dealyear cbsacode city state
save "Data/deals_pfcomp_byMSA.dta", replace
outsheet using "Data/deals_pfcomp_byMSA.csv", comma replace
sdf // just to force stop codes here
}

*=========================================================================


*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
* Try converting to 2020 USD with both the medical expenses CPI and regular PCE
foreach price in /*"" "CPIMEDSL" "PCEPILFE"*/ "CPIAUCSL" {
    use "preqin_deals_2000_2019.dta", clear
	if "`price'" == "" {
		replace dealsizeusdmn = dealsizeusdmn_raw
		local unit_pref "$"
	}
	else {
	    replace dealsizeusdmn = dealsizeusdmn_raw*`price'2020/`price'
		local unit_pref "2020 USD in"
	}
	cap mkdir Output/`price'
*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
*------------------------------------------
keep if industryclassification == "Healthcare"

replace primaryindustry = "Biotechnology" if primaryindustry == "Biopolymers"
replace primaryindustry = "Healthcare" if primaryindustry == "Healthcare Specialists"
	/*-------------------------------------------------------------------------
		* Run this to investigate subindustries by primaryindustry
			* see Data/README.txt for notes
		keep if primaryindustry == "Healthcare IT"
		keep subindustries
		split subindustries, p(", ") gen(sub)
			drop subindustries
			gen id = _n
		reshape long sub, i(id) j(termno)
			drop if sub == ""
			tab sub, sort
			pause
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

gen venture_id = dealid
	drop dealid
	egen dealid = group(venture_id)
	
tempfile dealset
save `dealset', replace
	
cap mkdir Output
	cap mkdir Output/raw
	
*===============================================================================
*							TABLES
if `tables' == 1 {
*===============================================================================
drop if stage == "Grant"
assert industryclassification == "Healthcare"
local N: dis _N
*----------------------
* PRIMARY INDUSTRY
*----------------------
preserve
	collapse (count) n_deals = dealid ///
			 (sum) vol_deals = dealsizeusdmn, by(primaryindustry) fast
	egen tot_deals =  sum(n_deals)
		assert tot_deals == `N'
		gen n_deals_pct = n_deals/tot_deals
	egen tot_vol = sum(vol_deals)
		gen vol_deals_pct = vol_deals/tot_vol

	keep primaryindustry n_deals n_deals_pct vol_deals vol_deals_pct
	order primaryindustry n_deals n_deals_pct vol_deals vol_deals_pct
	gsort -vol_deals

	export excel "Output/`price'/summ_stats.xlsx", ///
		keepcellfmt sheet("TabInds_raw", replace) first(var) cell(A2)
restore

*-----------
* STAGES
*-----------
preserve // -- Not Healthcare
	use "preqin_deals_2000_2019.dta", clear
	if "`price'" == "" replace dealsizeusdmn = dealsizeusdmn_raw
	else replace dealsizeusdmn = dealsizeusdmn_raw*`price'2020/`price'
		gen venture_id = dealid
		drop dealid
		egen dealid = group(venture_id)
		
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
	
	drop if stagegrp == ""
	collapse (count) n_dealsOther = dealid ///
			 (sum) vol_dealsOther = dealsizeusdmn, by(stagegrp) fast
	egen tot_dealsOther = sum(n_dealsOther)
		gen n_dealsO_pct = n_dealsO/tot_dealsO
	egen tot_volOther = sum(vol_dealsOther)
		gen vol_dealsO_pct = vol_deals/tot_volO
		
	keep stagegrp n_dealsOther n_dealsO_pct vol_dealsOther vol_dealsO_pct
	tempfile other_stats
	save `other_stats', replace
	
restore
preserve // -- Healthcare, Grouped Stages
	drop if stagegrp == ""
	collapse (count) n_deals = dealid ///
			 (sum) vol_deals = dealsizeusdmn, by(stagegrp) fast
	egen tot_deals =  sum(n_deals)
		assert tot_deals == `N'
		gen n_deals_pct = n_deals/tot_deals
	egen tot_vol = sum(vol_deals)
		gen vol_deals_pct = vol_deals/tot_vol

	keep stagegrp n_deals n_deals_pct vol_deals vol_deals_pct
	
	merge 1:1 stagegrp using `other_stats', nogen keepus(n_*O* vol_*O*)

	order stagegrp n_deals n_deals_pct vol_deals vol_deals_pct ///
					n_dealsOther n_dealsO_pct vol_dealsOther vol_dealsO_pct
	sort stagegrp
	
	export excel "Output/`price'/summ_stats.xlsx", ///
		keepcellfmt sheet("TabStage_raw", replace) first(var) cell(A2)
		
	replace stagegrp = "" if stagegrp == "Unspecified"
	
restore
preserve // -- Healthcare, All Stages
	collapse (count) n_deals = dealid ///
			 (sum) vol_deals = dealsizeusdmn, by(stage) fast
	egen tot_deals =  sum(n_deals)
		gen n_deals_pct = n_deals/tot_deals
	egen tot_vol = sum(vol_deals)
		gen vol_deals_pct = vol_deals/tot_vol

	keep stage n_deals n_deals_pct vol_deals vol_deals_pct

	order stage n_deals n_deals_pct vol_deals vol_deals_pct
	sort stage
	
	export excel "Output/`price'/summ_stats.xlsx", ///
		keepcellfmt sheet("TabStageAll_raw", replace) first(var) cell(A2)
restore
*-------------
* LOCATION
*-------------
foreach firm in "Inv" "Pf" {
	
	if "`firm'" == "Inv" local varname "investor"
	if "`firm'" == "Pf" local varname "portfoliocompany"
	
	foreach loc_abbr in "Ctry" "City" {
		
		if "`loc_abbr'" == "Ctry" {
			local loc "country"
			local state ""
		}
		if "`loc_abbr'" == "City" {
			local loc "city"
			local state "`varname'state"
		}
		
		preserve
			keep if `varname'`loc' != ""
			if "`loc_abbr'" == "City" keep if strpos(`varname'country, "US") > 0
			collapse (sum) dealsizeusdmn
			local V: dis dealsizeusdmn
		restore
		
		preserve
		
			if "`loc_abbr'" == "City" keep if strpos(`varname'country, "US") > 0
			
			egen n_`firm'`loc_abbr' = noccur(`varname'`loc'), string(",")
				replace n_`firm'`loc_abbr' = n_`firm'`loc_abbr' + 1 ///
					if `varname'`loc' != ""
				replace dealsizeusdmn = dealsizeusdmn/n_`firm'`loc_abbr'
			split `varname'`loc', p(", ")
				drop `varname'`loc'
			reshape long `varname'`loc', i(dealid dealsizeusdmn `state') j(`loc'no)
				drop `loc'no
				drop if `varname'`loc' == ""
				if "`loc_abbr'" == "City" {
					drop if inlist(`varname'city, "London", "Shanghai", "Basel", "Beijing", ///
						"Hong Kong", "Paris", "Singapore", "Munich", "Toronto")
					* --- By MSA City Groupings ---*
					replace `varname'city = "Boston" if strpos(`state', "MA") > 0 ///
						& inlist(`varname'city, "Cambridge", "Waltham", "Boston")
					replace `varname'city = "Boston" if strpos(`state', "MA") > 0 ///
						& strpos(`state', "KY") == 0 & `varname'city == "Lexington"
					replace `varname'city = "Bay Area" if strpos(`state', "CA") > 0 ///
						& (inlist(`varname'city, "San Francisco", "Menlo Park", "Palo Alto", ///
							"San Mateo", "San Jose", "Santa Clara", "Mountain View") ///
						| inlist(`varname'city, "Redwood City", "South San Francisco", ///
							"Berkeley", "Emeryville", "Sunnyvale", "Fremont"))
					replace `varname'city = "Los Angeles" if strpos(`state', "CA") > 0 ///
						& inlist(`varname'city, "Irvine", "Santa Monica", "Orange", "Pasadena")
					replace `varname'city = "New York" if strpos(`state', "NJ") > 0 ///
						& inlist(`varname'city, "New Brunswick")
					replace `varname'city = "San Diego" if strpos(`state', "CA") > 0 ///
						& inlist(`varname'city, "La Jolla")
					replace `varname'city = "Houston" if strpos(`state', "TX") > 0 ///
						& inlist(`varname'city, "The Woodlands")
					replace `varname'city = "Washington, DC" if strpos(`state', "DC") > 0 ///
						& inlist(`varname'city, "Washington")
					replace `varname'city = "Washington, DC" if strpos(`state', "MD") > 0 ///
						& inlist(`varname'city, "Bethesda")
					replace `varname'city = "Washington, DC" if strpos(`state', "VA") > 0 ///
						& inlist(`varname'city, "Alexandria", "Arlington", "Reston")
					replace `varname'city = "Lexington, KY" if strpos(`state', "KY") > 0 ///
						& `varname'city == "Lexington"
				}
				else {
					replace `varname'`loc' = "Hong Kong SAR" if `varname'`loc' == "Hong Kong SAR - China"
				}
			
			collapse (count) n_deals = dealid ///
					 (sum) vol_deals = dealsizeusdmn, by(`varname'`loc') fast
			egen tot_deals =  sum(n_deals)
				gen n_deals_pct = n_deals/tot_deals
			egen tot_vol = sum(vol_deals)
				gen vol_deals_pct = vol_deals/tot_vol

			keep `varname'`loc' n_deals n_deals_pct vol_deals vol_deals_pct
			order `varname'`loc' n_deals n_deals_pct vol_deals vol_deals_pct
			gsort -vol_deals

			export excel "Output/`price'/summ_stats.xlsx", ///
				keepcellfmt sheet("Tab`firm'`loc_abbr'_raw", replace) first(var) cell(A2)
		restore
	} // country and city loop
} // investor and portfolio company loop

*-------------
* VC Firms
*-------------
use `dealset', clear

ren investorsbuyersfirms investors
	replace investors = subinstr(investors, ", Inc", " Inc", .)
	replace investors = subinstr(investors, ", Ltd", " Ltd", .)

egen n_investors = noccur(investors), string(",")
	replace n_investors = n_investors + 1 ///
		if investors != ""
	replace dealsizeusdmn = dealsizeusdmn/n_investors
split investors, p(", ")
	drop investors
reshape long investors, i(dealid dealsizeusdmn) j(inv_no)
	drop inv_no
	ren investors investor
	drop if investor == ""

	collapse (count) n_deals = dealid ///
			 (sum) vol_deals = dealsizeusdmn, by(investor) fast
	egen tot_deals =  sum(n_deals)
		gen n_deals_pct = n_deals/tot_deals
	egen tot_vol = sum(vol_deals)
		gen vol_deals_pct = vol_deals/tot_vol

	keep investor n_deals n_deals_pct vol_deals vol_deals_pct
	order investor n_deals n_deals_pct vol_deals vol_deals_pct
	gsort -vol_deals

	export excel "Output/`price'/summ_stats.xlsx", ///
		keepcellfmt sheet("TabVCs_raw", replace) first(var) cell(A2)

} // end `tables'
*===============================================================================
*							PLOTS
if `plots' == 1 {
*===============================================================================
*---------------- HEALTHCARE SHARE OF TOTAL VC ---------------------------------
preserve
	use "preqin_deals_2000_2019.dta", clear
	if "`price'" == "" replace dealsizeusdmn = dealsizeusdmn_raw
	else replace dealsizeusdmn = dealsizeusdmn_raw*`price'2020/`price'
	
	drop if stage == "Grant"
	
	ren industryclassification indclass
	collapse (sum) deal_vol = dealsizeusdmn, by(dealyear indclass) fast
	bys dealyear: egen tot_deals = total(deal_vol)
		drop if indclass != "Healthcare"
		gen sh_hc = deal_vol/tot_deals*100
		replace deal_vol = deal_vol/1000
			lab var deal_vol "(`unit_pref' Billions)"
		replace tot_deals = tot_deals/1000
			lab var tot_deals "(`unit_pref' Billions)"
		sort dealyear
		br
		pause
	tsset dealyear
	#delimit ;
		tw (tsline sh_hc, lc(blue) lp(l)),
			title("Healthcare Share of" "Venture Capital Invested")
			xti("") aspect(1)
			yti("Share of Total VC Investments (%)" " ") ylab(0(20)100)
			name(sh_health, replace);
		graph export "Output/`price'/ts_sh_healthcare.png", replace as(png);
	
		tw (tsline deal_vol, lc(blue) lp(l))
		   (tsline tot_deals, lc(black) lp(_)),
		  legend(order(1 "Healthcare Deals" 2 "All VC Deals") r(1) symx(medium))
		  title("VC Investment Volumes") aspect(1)
		  yti("Total Investment" "(`unit_pref' Billions)" " ") ylab(, format(%9.0g)) xti("")
		  name(hc_vs_tot, replace);
		graph export "Output/`price'/ts_health_and_tot_vol.png", replace as(png);
		
		graph combine hc_vs_tot sh_health, r(1);
		graph export "Output/`price'/ts_health_vs_tot_combined.png",
											replace as(png) wid(1200) hei(700);
	#delimit cr
			
restore
preserve // -- Healthcare Avg Deal vs Non-Healthcare Avg Deal
	use "preqin_deals_2000_2019.dta", clear
	if "`price'" == "" replace dealsizeusdmn = dealsizeusdmn_raw
	else replace dealsizeusdmn = dealsizeusdmn_raw*`price'2020/`price'
	drop if stage == "Grant"
	
	gen hc = industryclassification == "Healthcare"
	
	collapse (mean) avg_dealsize = dealsizeusdmn ///
			 (sd) sd_dealsize = dealsizeusdmn, by(dealyear hc)
	
	gen dealsize_lb = avg_dealsize - (2*sd_dealsize)
	gen dealsize_ub = avg_dealsize + (2*sd_dealsize)
	
	#delimit ;
	tw (line avg_dealsize dealyear if hc == 1, lc(blue) lp(l))
	   (line avg_dealsize dealyear if hc == 0, lc(black) lp(l)),
	 legend(order(1 "Avg. Healthcare Deal" 2 "Avg. Non-Healthcare Deal") r(1))
	 title("Average Size of VC Deals") yti("(`unit_pref' Millions)") xti("")
	 xlab(2000(5)2020) ylab(, format(%9.0f)) name(avg_deals, replace);
	graph export "Output/`price'/ts_avg_deals.png", replace as(png) wid(1200) hei(700);
	
	tw (line dealsize_lb dealyear if hc == 0, lc(gs10) lp(-))
	   (line dealsize_ub dealyear if hc == 0, lc(gs10) lp(-))
	   (line dealsize_lb dealyear if hc == 1, lc(eltblue) lp(-))
	   (line dealsize_ub dealyear if hc == 1, lc(eltblue) lp(-))
	   (line avg_dealsize dealyear if hc == 1, lc(blue) lp(l))
	   (line avg_dealsize dealyear if hc == 0, lc(black) lp(l)),
	 legend(order(5 "Avg. Healthcare Deal" 6 "Avg. Non-Healthcare Deal" 1 "95% Confidence Interval") r(2))
	 title("Average Size of VC Deals") yti("(`unit_pref' Millions)") xti("")
	 xlab(2000(5)2020);
	graph export "Output/`price'/ts_avg_deals_w95CI.png", replace as(png) wid(1200) hei(700);
	#delimit cr
restore

*----------------------- OVERALL -----------------------------------------------
preserve // total deals and volumes over time

drop if stage == "Grant"

#delimit ;
collapse (count) n_deals = dealid
		 (sum) tot_deals = dealsizeusdmn
		 (mean) avg_deal = dealsizeusdmn
	, by(dealyear) fast;
replace tot_deals = tot_deals/1000; // $ Billions;

tsset dealyear;
tw (tsline n_deals, lc(midblue) lp(l) yaxis(1))
   (tsline tot_deals, lc(dkgreen) lp(_) yaxis(2)),
 legend(order(1 "Number of VC Deals" 2 "Total VC Volume") r(1))
 title("Healthcare Deals") name(hc_deals)
 xlab(2000(5)2020) xti("")  ylab(, format(%9.0f) axis(2))
 yti("Number of Deals", axis(1)) yti("Total Volume" "(`unit_pref' Billions)", axis(2));  
graph export "Output/`price'/ts_tot_deals.png", replace as(png) wid(1200) hei(700);
#delimit cr

graph combine hc_deals avg_deals, r(1)
graph export "Output/`price'/ts_avg_and_tot_hc_deals_combined.png", ///
												replace as(png) wid(1400) hei(700)

restore // ---------------------------
preserve // NIH grants only

keep if stage == "Grant" & strpos(investorsbuyersfirms, "National Institutes of Health") > 0

#delimit ;
collapse (count) n_deals = dealid
		 (sum) tot_deals = dealsizeusdmn
		 (mean) avg_deal = dealsizeusdmn
	, by(dealyear) fast;

tsset dealyear;
tw (tsline n_deals, lc(midblue) lp(l) yaxis(1))
   (tsline tot_deals, lc(dkgreen) lp(_) yaxis(2)),
 legend(order(1 "Number of Grants" 2 "Total Grant Volume") r(1))
 title("NIH Grants to Start-Ups") xti("")
 xlab(2000(5)2020)
 yti("Number of Grants", axis(1)) yti("Total Volume" "(`unit_pref' Millions)", axis(2));  
graph export "Output/`price'/ts_nih_grants.png", replace as(png) wid(1200) hei(700);

#delimit cr

restore
*---------------------- BY INDUSTRY --------------------------------------------
preserve

drop if stage == "Grant"

#delimit ;
collapse (count) n_deals = dealid
		 (sum) tot_deals = dealsizeusdmn
	, by(primaryindustry dealyear) fast;
replace tot_deals = tot_deals/1000; // $ Billions;

bys dealyear: egen drugs_n = total(n_deals) 
						if inlist(primaryindustry, "Biotechnology", "Pharmaceuticals");
bys dealyear: egen drugs_tot = total(tot_deals) 
						if inlist(primaryindustry, "Biotechnology", "Pharmaceuticals");

bys dealyear: egen infrastructure_n = total(n_deals) 
						if inlist(primaryindustry, "Healthcare", "Healthcare IT");
bys dealyear: egen infrastructure_tot = total(tot_deals) 
						if inlist(primaryindustry, "Healthcare", "Healthcare IT");
						
sort dealyear primaryindustry;
tw (line n_deals dealyear if primaryindustry == "Healthcare", lc(purple) lp(-))
   (line n_deals dealyear if primaryindustry == "Healthcare IT", lc(gs7) lp(_))
   (line n_deals dealyear if primaryindustry == "Medical Devices & Equipment", lc(dkorange) lp(-))
   (line n_deals dealyear if primaryindustry == "Pharmaceuticals", lc(cranberry) lp(_))
   (line n_deals dealyear if primaryindustry == "Biotechnology", lc(green) lp(l)),
 legend(order(1 "Healthcare" 2 "Healthcare IT" 3 "Medical Devices & Equipment"
			  4 "Pharmaceuticals" 5 "Biotechnology")
		colfirst r(2) symy(small) symx(vlarge))
 title("Healthcare Deals by Industry") yti("Number of Deals" " ") xti("")
 xlab(2000(5)2020);
graph export "Output/`price'/ts_n_deals_ByInd.png", replace as(png) wid(1200) hei(700);

tw (line n_deals dealyear if primaryindustry == "Healthcare", lc(purple) lp(-))
   (line n_deals dealyear if primaryindustry == "Healthcare IT", lc(gs7) lp(_))
   (line n_deals dealyear if primaryindustry == "Medical Devices & Equipment", lc(dkorange) lp(-))
   (line n_deals dealyear if primaryindustry == "Pharmaceuticals", lc(cranberry) lp(_))
   (line n_deals dealyear if primaryindustry == "Biotechnology", lc(green) lp(l))
   (line drugs_n dealyear if primaryindustry == "Biotechnology", lc(red) lp(l)),
 legend(order(1 "Healthcare" 2 "Healthcare IT" 3 "Medical Devices & Equipment"
			  4 "Pharmaceuticals" 5 "Biotechnology" 6 "Drugs*")
		colfirst r(2) symy(small) symx(vlarge))
 title("Healthcare Deals by Industry") yti("Number of Deals" " ") xti("")
 xlab(2000(5)2020)
 caption("* The Drugs line was derived by adding Biotechnology deals and Pharmaceuticals deals");
graph export "Output/ts_n_deals_ByInd_+drugs.png", replace as(png) wid(1200) hei(700);

tw (line tot_deals dealyear if primaryindustry == "Healthcare", lc(purple) lp(-))
   (line tot_deals dealyear if primaryindustry == "Healthcare IT", lc(gs7) lp(_))
   (line tot_deals dealyear if primaryindustry == "Medical Devices & Equipment", lc(dkorange) lp(-))
   (line tot_deals dealyear if primaryindustry == "Pharmaceuticals", lc(cranberry) lp(_))
   (line tot_deals dealyear if primaryindustry == "Biotechnology", lc(green) lp(l)),
 legend(order(1 "Healthcare" 2 "Healthcare IT" 3 "Medical Devices & Equipment"
			  4 "Pharmaceuticals" 5 "Biotechnology")
		colfirst r(2) symy(small) symx(vlarge))
 title("Healthcare Deals by Industry") yti("Total Deal Volume" "(`unit_pref' Billions)" " ") xti("")
 xlab(2000(5)2020)  name(inds5, replace);
graph export "Output/`price'/ts_deal_vol_ByInd.png", replace as(png) wid(1200) hei(700);

tw (line tot_deals dealyear if primaryindustry == "Healthcare", lc(purple) lp(-))
   (line tot_deals dealyear if primaryindustry == "Healthcare IT", lc(gs7) lp(_))
   (line tot_deals dealyear if primaryindustry == "Medical Devices & Equipment", lc(dkorange) lp(-))
   (line tot_deals dealyear if primaryindustry == "Pharmaceuticals", lc(cranberry) lp(_))
   (line tot_deals dealyear if primaryindustry == "Biotechnology", lc(green) lp(l))
   (line drugs_tot dealyear if primaryindustry == "Biotechnology", lc(red) lp(l)),
 legend(order(1 "Healthcare" 2 "Healthcare IT" 3 "Medical Devices & Equipment"
			  4 "Pharmaceuticals" 5 "Biotechnology" 6 "Drugs*")
		colfirst r(2) symy(small) symx(vlarge))
 title("Healthcare Deals by Industry") yti("Total Deal Volume" "(`unit_pref' Billions)" " ") xti("")
 xlab(2000(5)2020) ylab(,format(%9.0f))
 caption("* The Drugs line was derived by adding Biotechnology deals and Pharmaceuticals deals");
graph export "Output/`price'/ts_deal_vol_ByInd_+drugs.png", replace as(png) wid(1200) hei(700);

tw (line tot_deals dealyear if primaryindustry == "Medical Devices & Equipment", lc(dkorange) lp(l))
   (line infrastructure_tot dealyear if primaryindustry == "Healthcare", lc(purple) lp(l))
   (line drugs_tot dealyear if primaryindustry == "Biotechnology", lc(red) lp(l)),
 legend(order(2 "Healthcare Infrastructure" 1 "Medical Devices & Equipment" 3 "Drugs")
		colfirst r(1) symy(small) symx(vlarge))
 title("Healthcare Deals by Industry") yti("Total Deal Volume" "(`unit_pref' Billions)" " ") xti("")
 xlab(2000(5)2020)  name(inds3, replace)
 caption("The Drugs line was derived by adding Biotechnology deals and Pharmaceuticals deals"
			"The Infrastructure line was derived by adding Healthcare deals and Healthcare IT deals");
graph export "Output/`price'/ts_deal_vol_ByInd_drugs_devices_hc.png", replace as(png) wid(1200) hei(700);

graph combine inds5 inds3, c(1);
graph export "Output/`price'/ts_deal_vol_combined_ind5_ind3.png", replace as(png) hei(1400) wid(1200);

#delimit cr

restore // ---------------------------
/*preserve // NIH grants only

keep if stage == "Grant" & strpos(investorsbuyersfirms, "National Institutes of Health") > 0

#delimit ;
collapse (count) n_deals = dealid
		 (sum) tot_deals = dealsizeusdmn
	, by(primaryindustry dealyear) fast;

bys dealyear: egen drugs_n = total(n_deals) 
						if inlist(primaryindustry, "Biotechnology", "Pharmaceuticals");
bys dealyear: egen drugs_tot = total(tot_deals) 
						if inlist(primaryindustry, "Biotechnology", "Pharmaceuticals");

bys dealyear: egen infrastructure_n = total(n_deals) 
						if inlist(primaryindustry, "Healthcare", "Healthcare IT");
bys dealyear: egen infrastructure_tot = total(tot_deals) 
						if inlist(primaryindustry, "Healthcare", "Healthcare IT");

sort dealyear primaryindustry;
tw (line n_deals dealyear if primaryindustry == "Healthcare", lc(purple) lp(-))
   (line n_deals dealyear if primaryindustry == "Healthcare IT", lc(gs7) lp(_))
   (line n_deals dealyear if primaryindustry == "Medical Devices & Equipment", lc(dkorange) lp(-))
   (line n_deals dealyear if primaryindustry == "Pharmaceuticals", lc(cranberry) lp(_))
   (line n_deals dealyear if primaryindustry == "Biotechnology", lc(green) lp(l)),
 legend(order(1 "Healthcare" 2 "Healthcare IT" 3 "Medical Devices & Equipment"
			  4 "Pharmaceuticals" 5 "Biotechnology")
		colfirst r(2) symy(small) symx(vlarge))
 title("NIH Grants to Start-Ups by Industry") yti("Number of Grants" " ") xti("")
 xlab(2000(5)2020);
graph export "Output/`price'/ts_n_nih grants_ByInd.png", replace as(png) wid(1200) hei(700);

tw (line n_deals dealyear if primaryindustry == "Healthcare", lc(purple) lp(-))
   (line n_deals dealyear if primaryindustry == "Healthcare IT", lc(gs7) lp(_))
   (line n_deals dealyear if primaryindustry == "Medical Devices & Equipment", lc(dkorange) lp(-))
   (line n_deals dealyear if primaryindustry == "Pharmaceuticals", lc(cranberry) lp(_))
   (line n_deals dealyear if primaryindustry == "Biotechnology", lc(green) lp(l))
   (line drugs_n dealyear if primaryindustry == "Biotechnology", lc(red) lp(l)),
 legend(order(1 "Healthcare" 2 "Healthcare IT" 3 "Medical Devices & Equipment"
			  4 "Pharmaceuticals" 5 "Biotechnology" 6 "Drugs*")
		colfirst r(2) symy(small) symx(vlarge))
 title("NIH Grants to Start-Ups by Industry") yti("Number of Grants" " ") xti("")
 xlab(2000(5)2020)
 caption("* The Drugs line was derived by adding Biotechnology deals and Pharmaceuticals deals");
graph export "Output/`price'/ts_n_nih grants_ByInd_+drugs.png", replace as(png) wid(1200) hei(700);

tw (line tot_deals dealyear if primaryindustry == "Healthcare", lc(purple) lp(-))
   (line tot_deals dealyear if primaryindustry == "Healthcare IT", lc(gs7) lp(_))
   (line tot_deals dealyear if primaryindustry == "Medical Devices & Equipment", lc(dkorange) lp(-))
   (line tot_deals dealyear if primaryindustry == "Pharmaceuticals", lc(cranberry) lp(_))
   (line tot_deals dealyear if primaryindustry == "Biotechnology", lc(green) lp(l)),
 legend(order(1 "Healthcare" 2 "Healthcare IT" 3 "Medical Devices & Equipment"
			  4 "Pharmaceuticals" 5 "Biotechnology")
		colfirst r(2))
 title("NIH Grants to Start-Ups by Industry") yti("Total Grant Volume" "(`unit_pref' Millions)" " ") xti("")
 xlab(2000(5)2020);
graph export "Output/`price'/ts_nih_grant_vol_ByInd.png", replace as(png) wid(1200) hei(700);

tw (line tot_deals dealyear if primaryindustry == "Healthcare", lc(purple) lp(-))
   (line tot_deals dealyear if primaryindustry == "Healthcare IT", lc(gs7) lp(_))
   (line tot_deals dealyear if primaryindustry == "Medical Devices & Equipment", lc(dkorange) lp(-))
   (line tot_deals dealyear if primaryindustry == "Pharmaceuticals", lc(cranberry) lp(_))
   (line tot_deals dealyear if primaryindustry == "Biotechnology", lc(green) lp(l))
   (line drugs_tot dealyear if primaryindustry == "Biotechnology", lc(red) lp(l))
 legend(order(1 "Healthcare" 2 "Healthcare IT" 3 "Medical Devices & Equipment"
			  4 "Pharmaceuticals" 5 "Biotechnology" 6 "Drugs*")
		colfirst r(2))
 title("NIH Grants to Start-Ups by Industry") yti("Total Grant Volume" "(`unit_pref' Millions)" " ") xti("")
 xlab(2000(5)2020)
 caption("* The Drugs line was derived by adding Biotechnology deals and Pharmaceuticals deals");
graph export "Output/`price'/ts_nih_grant_vol_ByInd_+drugs.png", replace as(png) wid(1200) hei(700);

#delimit cr

restore*/

*---------- FUNDING STAGES BY INDUSTRY AND YEAR --------------------------------

drop if stagegrp == ""
replace stagegrp = subinstr(stagegrp, " ", "", .)
replace stagegrp = subinstr(stagegrp, "&", "", .)
collapse (count) n_deals = dealid (sum) vol_deals = dealsizeusdmn ///
	, by(primaryindustry stagegrp dealyear) fast

replace vol_deals = vol_deals/1000
	lab var vol_deals "Deal Volume (`unit_pref' Billions)"

replace n_deals = 0 if n_deals == .
replace vol_deals = 0 if vol_deals == .

levelsof primaryindustry, local(inds)

foreach nvol in /*"n"*/ "vol" {

	if "`nvol'" == "vol" local yvar "Volume of Deals" "(`unit_pref' Billions)"
	if "`nvol'" == "n" local yvar "Number of Deals"

	foreach ind of local inds {
		preserve
		keep if primaryindustry == "`ind'"
		keep `nvol'_deals dealyear stagegrp
		replace `nvol'_deals = 0 if `nvol'_deals == .
		reshape wide `nvol'_deals, i(dealyear) j(stagegrp) string
			foreach stage in "SeedAngel" "SeriesAB" "Expansion" "LateStage" {
				replace `nvol'_deals`stage' = 0 if `nvol'_deals`stage' == .
			}
		* For stacked area plots
			gen `nvol'_adj_SeedAngel = `nvol'_dealsSeedAngel
			gen `nvol'_adj_SeriesAB = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB
			gen `nvol'_adj_Expansion = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB ///
									+ `nvol'_dealsExpansion
			gen `nvol'_adj_LateStage = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB ///
									+ `nvol'_dealsExpansion + `nvol'_dealsLateStage
			gen `nvol'_adj_Unspecified = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB ///
									+ `nvol'_dealsExpansion + `nvol'_dealsLateStage ///
									+ `nvol'_dealsUnspecified
		sort dealyear		
		#delimit ;
		tw (area `nvol'_adj_LateStage dealyear, col(green))
		   (area `nvol'_adj_Expansion dealyear, col(dkorange))
		   (area `nvol'_adj_SeriesAB dealyear, col(edkblue))
		   (area `nvol'_adj_SeedAngel dealyear, col(maroon)),
		 legend(order(4 "Seed & Angel" 3 "Series A & B" 2 "Expansion" 1 "Late Stage")
				r(1) symy(small) symx(small))
		 ti("Venture Capital Deals by Funding Stage" "`ind'")
		 yti("`yvar'" " ") xti("");
		graph export "Output/`price'/ts_`nvol'deals_by_stage-`ind'.png", replace as(png) wid(1200);
		
		tw (area `nvol'_adj_Unspecified dealyear, col(gs8))
		   (area `nvol'_adj_LateStage dealyear, col(green))
		   (area `nvol'_adj_Expansion dealyear, col(dkorange))
		   (area `nvol'_adj_SeriesAB dealyear, col(edkblue))
		   (area `nvol'_adj_SeedAngel dealyear, col(maroon)),
		 legend(order(5 "Seed & Angel" 4 "Series A & B" 3 "Expansion" 2 "Late Stage"
						1 "Unspecified") r(1) symy(small) symx(small))
		 ti("Venture Capital Deals by Funding Stage" "`ind'")
		 yti("`yvar'" " ") xti("")
		 xlab(2000(5)2020);
		graph export "Output/`price'/ts_`nvol'deals_by_stage_wUn-`ind'.png", replace as(png) wid(1200) hei(700);
		#delimit cr

		*----------------------------------------------------------------------
		* Inflating Deal Volumes to account for unspecified funding stage deals
		if "`nvol'" == "vol" {
		*----------------------------------------------------------------------
			foreach stage in "SeedAngel" "SeriesAB" "Expansion" "LateStage" {
				replace vol_deals`stage' = vol_deals`stage'*(vol_adj_Un/vol_adj_Late)
			} // end stage loop

			* For stacked area plots
				gen `nvol'_infl_SeedAngel = `nvol'_dealsSeedAngel
				gen `nvol'_infl_SeriesAB = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB
				gen `nvol'_infl_Expansion = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB ///
										+ `nvol'_dealsExpansion
				gen `nvol'_infl_LateStage = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB ///
										+ `nvol'_dealsExpansion + `nvol'_dealsLateStage

			assert round(vol_infl_LateStage,2) == round(vol_adj_Unspecified,2)

			sort dealyear		
			#delimit ;
			tw (area `nvol'_infl_LateStage dealyear, col(green))
			   (area `nvol'_infl_Expansion dealyear, col(dkorange))
			   (area `nvol'_infl_SeriesAB dealyear, col(edkblue))
			   (area `nvol'_infl_SeedAngel dealyear, col(maroon)),
			 legend(order(4 "Seed & Angel" 3 "Series A & B" 2 "Expansion" 1 "Late Stage")
					r(1) symy(small) symx(small))
			 ti("Venture Capital Deals by Funding Stage" "`ind'")
			 yti("`yvar'" " ") xti("")
			 xlab(2000(5)2020);
			graph export "Output/`price'/ts_`nvol'deals_infl_by_stage-`ind'.png", replace as(png) wid(1200);
			#delimit cr
		} // end inflated deal volumes
		*----------------------------------------------------------------------

		restore
	} // end industry loop
	
		preserve // DRUGS = BIOTECH + PHARMA ------------------------------------
		keep if inlist(primaryindustry, "Biotechnology", "Pharmaceuticals")
			collapse (sum) `nvol'_deals, by(dealyear stagegrp) fast
		keep `nvol'_deals dealyear stagegrp
		replace `nvol'_deals = 0 if `nvol'_deals == .
		reshape wide `nvol'_deals, i(dealyear) j(stagegrp) string
			foreach stage in "SeedAngel" "SeriesAB" "Expansion" "LateStage" {
				replace `nvol'_deals`stage' = 0 if `nvol'_deals`stage' == .
			}
		* For stacked area plots
			gen `nvol'_adj_SeedAngel = `nvol'_dealsSeedAngel
			gen `nvol'_adj_SeriesAB = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB
			gen `nvol'_adj_Expansion = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB ///
									+ `nvol'_dealsExpansion
			gen `nvol'_adj_LateStage = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB ///
									+ `nvol'_dealsExpansion + `nvol'_dealsLateStage
			gen `nvol'_adj_Unspecified = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB ///
									+ `nvol'_dealsExpansion + `nvol'_dealsLateStage ///
									+ `nvol'_dealsUnspecified
		sort dealyear		
		#delimit ;
		tw (area `nvol'_adj_LateStage dealyear, col(green))
		   (area `nvol'_adj_Expansion dealyear, col(dkorange))
		   (area `nvol'_adj_SeriesAB dealyear, col(edkblue))
		   (area `nvol'_adj_SeedAngel dealyear, col(maroon)),
		 legend(order(4 "Seed & Angel" 3 "Series A & B" 2 "Expansion" 1 "Late Stage")
				r(1) symy(small) symx(small))
		 ti("Venture Capital Deals by Funding Stage" "Drugs")
		 yti("`yvar'" " ") xti("")
		 note("Deals in either the biotechnology or pharmaceuticals industries are included here, due to significant overlap");
		graph export "Output/`price'/ts_`nvol'deals_by_stage-Drugs.png", replace as(png) wid(1200);
		
		tw (area `nvol'_adj_Unspecified dealyear, col(gs8))
		   (area `nvol'_adj_LateStage dealyear, col(green))
		   (area `nvol'_adj_Expansion dealyear, col(dkorange))
		   (area `nvol'_adj_SeriesAB dealyear, col(edkblue))
		   (area `nvol'_adj_SeedAngel dealyear, col(maroon)),
		 legend(order(5 "Seed & Angel" 4 "Series A & B" 3 "Expansion" 2 "Late Stage"
						1 "Unspecified") r(1) symy(small) symx(small))
		 ti("Venture Capital Deals by Funding Stage" "Drugs")
		 yti("`yvar'" " ") xti("") xlab(2000(5)2020)
		 note("Deals in either the biotechnology or pharmaceuticals industries are included here, due to significant overlap");
		graph export "Output/`price'/ts_`nvol'deals_by_stage_wUn-Drugs.png", replace as(png) wid(1200) hei(700);
		#delimit cr

		*----------------------------------------------------------------------
		* Inflating Deal Volumes to account for unspecified funding stage deals
		if "`nvol'" == "vol" {
		*----------------------------------------------------------------------
			foreach stage in "SeedAngel" "SeriesAB" "Expansion" "LateStage" {
				replace vol_deals`stage' = vol_deals`stage'*(vol_adj_Un/vol_adj_Late)
			} // end stage loop

			* For stacked area plots
				gen `nvol'_infl_SeedAngel = `nvol'_dealsSeedAngel
				gen `nvol'_infl_SeriesAB = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB
				gen `nvol'_infl_Expansion = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB ///
										+ `nvol'_dealsExpansion
				gen `nvol'_infl_LateStage = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB ///
										+ `nvol'_dealsExpansion + `nvol'_dealsLateStage

			assert round(vol_infl_LateStage,2) == round(vol_adj_Unspecified,2)

			sort dealyear		
			#delimit ;
			tw (area `nvol'_infl_LateStage dealyear, col(green))
			   (area `nvol'_infl_Expansion dealyear, col(dkorange))
			   (area `nvol'_infl_SeriesAB dealyear, col(edkblue))
			   (area `nvol'_infl_SeedAngel dealyear, col(maroon)),
			 legend(order(4 "Seed & Angel" 3 "Series A & B" 2 "Expansion" 1 "Late Stage")
					r(1) symy(small) symx(small))
			 ti("Venture Capital Deals by Funding Stage" "Drugs")
			 yti("`yvar'" " ") xti("") xlab(2000(5)2020)
			note("Deals in either the biotechnology or pharmaceuticals industries are included here, due to significant overlap");
			graph export "Output/`price'/ts_`nvol'deals_infl_by_stage-Drugs.png", replace as(png) wid(1200);
			#delimit cr
		} // end inflated deal volumes
		*----------------------------------------------------------------------

		restore
} //end number/volume of deals loop

replace n_deals = 0 if n_deals == .
replace vol_deals = 0 if vol_deals == .
collapse (sum) n_deals vol_deals, by(stagegrp dealyear) fast
reshape wide n_deals vol_deals, i(dealyear) j(stagegrp) string

foreach nvol in /*"n"*/ "vol" {
	* For stacked area plots
		gen `nvol'_adj_SeedAngel = `nvol'_dealsSeedAngel
		gen `nvol'_adj_SeriesAB = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB
		gen `nvol'_adj_Expansion = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB ///
								+ `nvol'_dealsExpansion
		gen `nvol'_adj_LateStage = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB ///
								+ `nvol'_dealsExpansion + `nvol'_dealsLateStage
		gen `nvol'_adj_Unspecified = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB ///
								+ `nvol'_dealsExpansion + `nvol'_dealsLateStage ///
								+ `nvol'_dealsUnspecified
	sort dealyear
	#delimit ;
	tw (area `nvol'_adj_LateStage dealyear, col(green))
	   (area `nvol'_adj_Expansion dealyear, col(dkorange))
	   (area `nvol'_adj_SeriesAB dealyear, col(edkblue))
	   (area `nvol'_adj_SeedAngel dealyear, col(maroon)),
	 legend(order(4 "Seed & Angel" 3 "Series A & B" 2 "Expansion" 1 "Late Stage")
					r(1) symy(small) symx(small))
	 ti("Venture Capital Deals by Funding Stage" "All Industries")
	 yti("`yvar'" " ") xti("")
	 xlab(2000(5)2020);
	graph export "Output/`price'/ts_`nvol'deals_by_stage-All.png", replace as(png) wid(1200) hei(700);

	tw (area `nvol'_adj_Unspecified dealyear, col(gs8))
	   (area `nvol'_adj_LateStage dealyear, col(green))
	   (area `nvol'_adj_Expansion dealyear, col(dkorange))
	   (area `nvol'_adj_SeriesAB dealyear, col(edkblue))
	   (area `nvol'_adj_SeedAngel dealyear, col(maroon)),
	 legend(order(5 "Seed & Angel" 4 "Series A & B" 3 "Expansion" 2 "Late Stage"
					1 "Unspecified") r(1) symy(small) symx(small))
	 ti("Venture Capital Deals by Funding Stage" "All Industries")
	 yti("`yvar'" " ") xti("")
	 xlab(2000(5)2020);
	graph export "Output/`price'/ts_`nvol'deals_by_stage_wUn-All.png", replace as(png) wid(1200) hei(700);
	#delimit cr

		*----------------------------------------------------------------------
		* Inflating Deal Volumes to account for unspecified funding stage deals
		if "`nvol'" == "vol" {
		*----------------------------------------------------------------------
			foreach stage in "SeedAngel" "SeriesAB" "Expansion" "LateStage" {
				replace vol_deals`stage' = vol_deals`stage'*(vol_adj_Un/vol_adj_Late)
			} // end stage loop

			* For stacked area plots
				gen `nvol'_infl_SeedAngel = `nvol'_dealsSeedAngel
				gen `nvol'_infl_SeriesAB = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB
				gen `nvol'_infl_Expansion = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB ///
										+ `nvol'_dealsExpansion
				gen `nvol'_infl_LateStage = `nvol'_dealsSeedAngel + `nvol'_dealsSeriesAB ///
										+ `nvol'_dealsExpansion + `nvol'_dealsLateStage

			assert round(vol_infl_LateStage,2) == round(vol_adj_Unspecified,2)

			sort dealyear		
			#delimit ;
			tw (area `nvol'_infl_LateStage dealyear, col(green))
			   (area `nvol'_infl_Expansion dealyear, col(dkorange))
			   (area `nvol'_infl_SeriesAB dealyear, col(edkblue))
			   (area `nvol'_infl_SeedAngel dealyear, col(maroon)),
			 legend(order(4 "Seed & Angel" 3 "Series A & B" 2 "Expansion" 1 "Late Stage")
					r(1) symy(small) symx(small))
			 ti("Venture Capital Deals by Funding Stage" "All Industries")
			 yti("`yvar'" " ") xti("")
			 xlab(2000(5)2020);
			graph export "Output/`price'/ts_`nvol'deals_infl_by_stage-All.png", replace as(png) wid(1200);
			#delimit cr
		} // end inflated deal volumes
		*----------------------------------------------------------------------
} // end number/volume of deals loop

*---------- INDUSTRY DISTRIBUTION OF NIH GRANTS TO START-UPS -------------------
use `dealset', clear

cap mkdir "Output/`price'/gphs/"

keep if stage == "Grant" & strpos(investorsbuyersfirms, "National Institutes of Health") > 0
local N: dis _N
preserve
	collapse (sum) dealsizeusdmn
	replace deals = round(deals,1)
	local V: dis dealsizeusdmn
restore

collapse (count) n_deals = dealid (sum) deal_vol = dealsizeusdmn ///
	, by(primaryindustry) fast

#delimit ;
graph pie n_deals, over(primaryindustry)
	pl(1 percent, c(white) format(%9.3g) size(medium))
	pl(2 percent, c(white) format(%9.3g) size(medium))
	pl(3 percent, c(white) format(%9.3g) size(medium))
	pl(4 percent, c(white) format(%9.3g) size(medium) gap(small))
	pl(5 percent, c(white) format(%9.3g) size(medium))
	title("NIH Grants to Start-Ups") legend(colfirst)
	subtitle("Share by Number of Grants" "`N' Grants Total")
	pie(1, c(green)) pie(2, c(purple)) pie(3, c(gs7))
	pie(4, c(dkorange)) pie(5, c(cranberry));
graph save "Output/`price'/gphs/nih_grants_pie.gph", replace;
graph export "Output/`price'/nih_grants_pie.png", replace as(png);

graph pie deal_vol, over(primaryindustry)
	pl(1 percent, c(white) format(%9.3g) size(medium))
	pl(2 percent, c(white) format(%9.3g) size(medium))
	pl(3 percent, c(white) format(%9.3g) size(medium))
	pl(4 percent, c(white) format(%9.3g) size(medium) gap(small))
	pl(5 percent, c(white) format(%9.3g) size(medium))
	title("NIH Grants to Start-Ups") legend(colfirst)
	subtitle("Share by Grant Volume" "$`V' Million in Grants Total")
	pie(1, c(green)) pie(2, c(purple)) pie(3, c(gs7))
	pie(4, c(dkorange)) pie(5, c(cranberry));
graph save "Output/`price'/gphs/nih_grant_vol_pie.gph", replace;
graph export "Output/`price'/nih_grant_vol_pie.png", replace as(png);
#delimit cr

grc1leg "Output/`price'/gphs/nih_grants_pie.gph" ///
		"Output/`price'/gphs/nih_grant_vol_pie.gph", r(1)
graph export "Output/`price'/nih_grant_pies_combined.png", replace as(png)
} // end `plots'
*=========================================================================
*			 TOP 10 PORTFOLIO & INVESTING MSAs BY INDUSTRY 
if `plots_byloc' == 1 {
*=========================================================================

foreach firm in "Inv" "Pf" {
	
	if "`firm'" == "Inv" {
		local varname "investor"
		local titleA "Top 10 Investing"
	}
	if "`firm'" == "Pf" {
		local varname "portfoliocompany"
		local titleA "Top 10 Innovating"
	}
	
	local Varname = proper("`varname'")
	
	foreach loc_abbr in /*"Ctry"*/ "City" {
		
		use `dealset', clear
		drop if stage == "Grants"

		if "`loc_abbr'" == "Ctry" {
			local loc "country"
			local state ""
			local titleB "Countries"
		}
		if "`loc_abbr'" == "City" {
			local loc "city"
			local state "`varname'state"
			local titleB "MSAs"
		}
		
		local Loc = proper("`loc'")
		
		preserve
			keep if `varname'`loc' != ""
			if "`loc_abbr'" == "City" keep if strpos(`varname'country, "US") > 0
			collapse (sum) dealsizeusdmn
			local V: dis dealsizeusdmn
		restore
		
		if "`loc_abbr'" == "City" keep if strpos(`varname'country, "US") > 0
		
		egen n_`firm'`loc_abbr' = noccur(`varname'`loc'), string(",")
			replace n_`firm'`loc_abbr' = n_`firm'`loc_abbr' + 1 ///
				if `varname'`loc' != ""
			replace dealsizeusdmn = dealsizeusdmn/n_`firm'`loc_abbr'
		split `varname'`loc', p(", ")
			drop `varname'`loc'
		reshape long `varname'`loc', i(dealid dealsizeusdmn `state') j(`loc'no)
			drop `loc'no
			drop if `varname'`loc' == ""
			pause
			if "`loc_abbr'" == "City" {
				drop if inlist(`varname'city, "London", "Shanghai", "Basel", "Beijing", ///
					"Hong Kong", "Paris", "Singapore", "Munich", "Toronto")
				* --- By MSA City Groupings ---*
				gen `varname'msa = "Boston" if strpos(`state', "MA") > 0 ///
					& inlist(`varname'city, "Cambridge", "Waltham", "Boston")
				replace `varname'msa = "Boston" if strpos(`state', "MA") > 0 ///
					& strpos(`state', "KY") == 0 & `varname'city == "Lexington"
				replace `varname'msa = "Bay Area" if strpos(`state', "CA") > 0 ///
					& (inlist(`varname'city, "San Francisco", "Menlo Park", "Palo Alto", ///
						"San Mateo", "San Jose", "Santa Clara", "Mountain View") ///
					| inlist(`varname'city, "Redwood City", "South San Francisco", ///
						"Berkeley", "Emeryville", "Sunnyvale", "fremont"))
				replace `varname'msa = "Los Angeles" if strpos(`state', "CA") > 0 ///
					& inlist(`varname'city, "Irvine", "Santa Monica", "Orange", "Pasadena")
				replace `varname'msa = "New York" if strpos(`state', "NJ") > 0 ///
					& inlist(`varname'city, "New Brunswick")
				replace `varname'msa = "San Diego" if strpos(`state', "CA") > 0 ///
					& inlist(`varname'city, "La Jolla")
				replace `varname'msa = "Houston" if strpos(`state', "TX") > 0 ///
					& inlist(`varname'city, "The Woodlands")
				replace `varname'msa = "Washington, DC" if strpos(`state', "DC") > 0 ///
					& inlist(`varname'city, "Washington")
				replace `varname'msa = "Washington, DC" if strpos(`state', "MD") > 0 ///
					& inlist(`varname'city, "Bethesda")
				replace `varname'msa = "Washington, DC" if strpos(`state', "VA") > 0 ///
					& inlist(`varname'city, "Alexandria", "Arlington", "Reston")
				replace `varname'msa = "Lexington, KY" if strpos(`state', "KY") > 0 ///
					& `varname'city == "Lexington"
				replace `varname'msa = `varname'city if `varname'msa == ""
			}
			else {
				replace `varname'`loc' = "Hong Kong SAR" if `varname'`loc' == "Hong Kong SAR - China"
			}
		
		if "`loc_abbr'" == "City" {
			local grpvar "msa"
			local Loc "MSA"
		}
		if "`loc_abbr'" == "Ctry" local grpvar "`loc'"
		
		keep dealid dealyear primaryindustry dealsizeusdmn `varname'`grpvar'
		
		preserve
			collapse (sum) vol_deals_`grpvar' = dealsizeusdmn, by(`varname'`grpvar') fast
			egen `grpvar'_rank = rank(vol_deals_`grpvar'), field
			keep if `grpvar'_rank <= 10
			gsort -vol_deals_`grpvar'
			levelsof `varname'`grpvar' , local(list_top10) clean s(", ")

			tempfile top10
			save `top10', replace
		restore
		
		bys `varname'`grpvar': egen vol_deals_`grpvar' = total(dealsizeusdmn)
		bys `varname'`grpvar' dealyear: egen vol_deals_`grpvar'_yr = total(dealsizeusdmn)
		bys `varname'`grpvar' primaryindustry: egen vol_deals_`grpvar'_ind = total(dealsizeusdmn)
		
		merge m:1 `varname'`grpvar' using `top10', gen(top10) assert(1 3)
			replace top10 = 0 if top10 == 1
			replace top10 = 1 if top10 == 3
		
		if "`loc_abbr'" == "City" local sub "(US Only)"
		else local sub ""
		
		* Stacked Bar Plots ----------------------------------------------------------
		preserve
			egen vc_tot_dollars = total(dealsizeusdmn)
			keep if top10
			/*gen dealdecade = int(dealyear/10)*10
				tostring dealdecade, replace
				replace dealdecade = dealdecade + "s"*/
			replace primaryindustry = subinstr(subinstr(primaryindustry, " ", "", .), "&","",.)
			collapse (sum) deal_vol = dealsizeusdmn (max) vc_tot_dollars, ///
						by(`varname'`grpvar' primaryindustry /*dealdecade*/) fast
				gen sh_deal_vol = deal_vol/vc_tot_dollars*100
				replace deal_vol = deal_vol/1000
			replace primaryindustry = "MedicalDevices" if primaryindustry == "MedicalDevicesEquipment"
			reshape wide deal_vol sh_deal_vol, i(`varname'`grpvar' /*dealdecade*/) j(primaryindustry) string
				lab var deal_volBiotech "Biotechnology"
				lab var deal_volHealthcare "Healthcare"
				lab var deal_volHealthcareIT "Healthcare IT"
				lab var deal_volMedicalDev "Medical Devices"
				lab var deal_volPharma "Pharmaceuticals"
				lab var sh_deal_volBiotech "Biotechnology"
				lab var sh_deal_volHealthcare "Healthcare"
				lab var sh_deal_volHealthcareIT "Healthcare IT"
				lab var sh_deal_volMedicalDev "Medical Devices"
				lab var sh_deal_volPharma "Pharmaceuticals"
			egen tot_vol = rowtotal(deal_vol*)
			bys `varname'`grpvar': egen tot = total(tot_vol)
			
			* Graph by Dollars
			graph bar (asis) deal_volB deal_volP deal_volM deal_volH*,  ///
				stack /*over(dealdecade, sort(dealdecade) lab(angle(60)))*/ ///
					over(`varname'`grpvar',  sort(tot)  descending) ///
				title("Industry Breakdown of VC Funding Recipient Firms") ///
				legend(symx(small) symy(small) r(1)) yti("Deal Volume (`unit_pref' Billions)" " ") ///
				bar(1, col(green)) bar(2, col(cranberry)) bar(3, col(purple)) ///
										bar(4, col(dkorange)) bar(5, col(gs7))
			graph export "Output/`price'/top10_bars_`firm'`loc_abbr'_byInd.png", ///
				replace as(png) wid(1800) hei(700)
				
			* Graph by Share of VC Dollars
			graph bar (asis) sh_deal_volB sh_deal_volP sh_deal_volM sh_deal_volH*,  ///
				stack /*over(dealdecade, sort(dealdecade) lab(angle(60)))*/ ///
					over(`varname'`grpvar',  sort(tot)  descending) ///
				title("Industry Breakdown of VC Funding Recipient Firms") ///
				legend(symx(small) symy(small) r(1)) yti("Share of VC Dollars in Healthcare (%)" " ") ///
				bar(1, col(green)) bar(2, col(cranberry)) bar(3, col(purple)) ///
										bar(4, col(dkorange)) bar(5, col(gs7))
			graph export "Output/`price'/top10_bars_`firm'`loc_abbr'_%_byInd.png", ///
				replace as(png) wid(1800) hei(700)
		restore // -------------------------------------------------------------------
		
		* HHI Plots -----------------------------------------------------------------------------
		preserve
			bys primaryindustry dealyear: egen tot_vol = total(dealsizeusdmn)
			keep if top10
			collapse (sum) deal_vol = dealsizeusdmn (last) tot_vol, ///
									by(`varname'`grpvar' primaryindustry dealyear) fast
				gen sh_deal_vol = deal_vol/tot_vol*100
				gen sq_sh_deal_vol = sh_deal_vol^2
			collapse (sum) hhi = sq_sh_deal_vol sh_deal_vol, by(primaryindustry dealyear) fast
			assert inrange(hhi, 0, 10000)
			
			#delimit ;
			tw (line hhi dealyear if primaryindustry == "Healthcare", lc(purple) lp(-))
			   (line hhi dealyear if primaryindustry == "Healthcare IT", lc(gs7) lp(_))
			   (line hhi dealyear if primaryindustry == "Medical Devices & Equipment", lc(dkorange) lp(-))
			   (line hhi dealyear if primaryindustry == "Pharmaceuticals", lc(cranberry) lp(_))
			   (line hhi dealyear if primaryindustry == "Biotechnology", lc(green) lp(l)),
			 legend(order(1 "Healthcare" 2 "Healthcare IT" 3 "Medical Devices & Equipment"
						  4 "Pharmaceuticals" 5 "Biotechnology")
					colfirst r(2) symy(small) symx(vlarge))
			 title("Geographic Concentration of Funding" "by Industry") yti("HHI-10" " ") xti("")
			 xlab(2000(5)2020);
			graph export "Output/`price'/ts_hhi_by`firm'`loc_abbr'_ByInd.png", replace as(png) wid(1200) hei(700);
			
			tw (line sh_deal_vol dealyear if primaryindustry == "Healthcare", lc(purple) lp(-))
			   (line sh_deal_vol dealyear if primaryindustry == "Healthcare IT", lc(gs7) lp(_))
			   (line sh_deal_vol dealyear if primaryindustry == "Medical Devices & Equipment", lc(dkorange) lp(-))
			   (line sh_deal_vol dealyear if primaryindustry == "Pharmaceuticals", lc(cranberry) lp(_))
			   (line sh_deal_vol dealyear if primaryindustry == "Biotechnology", lc(green) lp(l)),
			 legend(order(1 "Healthcare" 2 "Healthcare IT" 3 "Medical Devices & Equipment"
						  4 "Pharmaceuticals" 5 "Biotechnology")
					colfirst r(2) symy(small) symx(vlarge))
			 title("Geographic Concentration of Funding" "by Industry")
			 yti("Share of Investments from" "`titleA' `titleB'" " ") xti("") xlab(2000(5)2020);
			graph export "Output/`price'/ts_sh_top10_by`firm'`loc_abbr'_ByInd.png", replace as(png) wid(1200) hei(700);
			#delimit cr
		restore // ------------------------------------------------------------------------------
		
		levelsof primaryindustry, local(inds)
		
		* Stacked Area Plots of Top 10 vs Other Over Time & By Industry -------------------------------
		collapse (sum) deal_vol = dealsizeusdmn, by(top10 dealyear primaryindustry) fast
			reshape wide deal_vol, i(dealyear primaryindustry) j(top10)
				forval yn = 0/1 {
				replace deal_vol`yn' = deal_vol`yn'/1000
				lab var deal_vol`yn' "$ Billions"
			}
			gen tot_vol = deal_vol0 + deal_vol1
			
		
		foreach ind of local inds {
			local ind_filename = subinstr("`ind'", " ", "", .)
			local ind_filename = subinstr("`ind_filename'", "&", "", .)
			
			#delimit ;
			tw (area tot_vol dealyear if primaryindustry == "`ind'", col(gs8))
			   (area deal_vol1 dealyear if primaryindustry == "`ind'", col(maroon)),
			 legend(order(2 "Top 10 `Loc'" 1 "Other `Loc'") r(1) symy(small) symx(small))
			 title("Coverage of `titleA' `titleB'" "by Industry") subti("`ind'" "`sub'")
			 yti("Deal Volume" "(`unit_pref' Billions)") xti("")
			 note("Top 10: `list_top10'", span);
			graph export "Output/`price'/top10_stacked_`firm'`loc_abbr'-`ind_filename'.png",
										replace as(png) wid(1200) hei(700);
			#delimit cr
		}
		
		drop tot_vol
		reshape long deal_vol, i(dealyear primaryindustry) j(top10)
		
		* Stacked Area Plots of Top 10 vs Other Over Time ---------------------------------------------
		collapse (sum) deal_vol, by(top10 dealyear) fast
			reshape wide deal_vol, i(dealyear) j(top10)
			gen tot_vol = deal_vol0 + deal_vol1
		
		#delimit ;
		tw (area tot_vol dealyear, col(gs8))
		   (area deal_vol1 dealyear, col(maroon)),
		 legend(order(2 "Top 10 `Loc'" 1 "Other `Loc'") r(1) symy(small) symx(small))
		 title("Coverage of `titleA' `titleB'") subti("`sub'")
		 yti("Deal Volume (2020 USD in Billions)") xti("")
		 note("Top 10: `list_top10'", span);
		graph export "Output/`price'/top10_stacked_`firm'`loc_abbr'-All.png", replace as(png) wid(1200) hei(700);
		#delimit cr

	} // country / city loop
} // investor / portfolio loop


} // end `plots_byloc'

*=========================================================================
*					TOP 10 VENTURE CAPITALISTS BY INDUSTRY 
if `plots_topinv' == 1 {
*=========================================================================
use `dealset', clear

ren investorsbuyersfirms investors
	replace investors = subinstr(investors, ", Inc", " Inc", .)
	replace investors = subinstr(investors, ", Ltd", " Ltd", .)

egen n_investors = noccur(investors), string(",")
	replace n_investors = n_investors + 1 ///
		if investors != ""
	replace dealsizeusdmn = dealsizeusdmn/n_investors
split investors, p(", ")
	drop investors
reshape long investors, i(dealid dealsizeusdmn) j(inv_no)
	drop inv_no
	ren investors investor
	drop if investor == ""

keep dealid dealyear primaryindustry dealsizeusdmn investor

preserve
	collapse (sum) vol_deals = dealsizeusdmn, by(investor) fast
	egen inv_rank = rank(vol_deals), field
	keep if inv_rank <= 10
	gsort -vol_deals
	levelsof investor if _n <= 5, local(list_top10a) clean s(", ")
		local list_top10a "`list_top10a',"
	levelsof investor if _n > 5, local(list_top10b) clean s(", ")	
	
	tempfile top10
	save `top10', replace
restore

bys investor: egen vol_deals = total(dealsizeusdmn)

merge m:1 investor using `top10', gen(top10) assert(1 3)
	replace top10 = 0 if top10 == 1
	replace top10 = 1 if top10 == 3
	
	gen investor_fullname = investor
	replace investor = "New Enterprise" if investor == "New Enterprise Associates" // MD
	replace investor = "OrbiMed" if investor == "OrbiMed Advisors" // NYC
	replace investor = "Versant" if investor == "Versant Ventures" // Bay
	replace investor = "Domain" if investor == "Domain Associates" // Princeton NJ
	replace investor = "MPM" if investor == "MPM Capital" // Cambridge/Bay Area
	replace investor = "Novartis" if investor == "Novartis Venture Fund" // Switzerland
	replace investor = "ARCH" if investor == "ARCH Venture Partners" // Chicago
	replace investor = "Deerfield" if investor == "Deerfield Management" // NYC
	replace investor = "Kleiner Perkins" if investor == "Kleiner Perkins Caufield & Byers" // Bay
	replace investor = "SB" if investor == "SB Investment Advisers" // Bay Area

* Stacked Bar Plots ----------------------------------------------------------
preserve
	keep if top10
	gen dealdecade = int(dealyear/10)*10
		tostring dealdecade, replace
		replace dealdecade = dealdecade + "s"
	replace primaryindustry = subinstr(subinstr(primaryindustry, " ", "", .), "&","",.)
	collapse (sum) deal_vol = dealsizeusdmn, by(investor primaryindustry dealdecade) fast
		replace deal_vol = deal_vol/1000
	reshape wide deal_vol, i(investor dealdecade) j(primaryindustry) string
		lab var deal_volBiotech "Biotechnology"
		lab var deal_volHealthcare "Healthcare"
		lab var deal_volHealthcareIT "Healthcare IT"
		lab var deal_volMedicalDev "Medical Devices"
		lab var deal_volPharma "Pharmaceuticals"
	egen tot_vol = rowtotal(deal_vol*)
	bys investor: egen tot = total(tot_vol)
	graph bar (asis) deal_volB deal_volP deal_volM deal_volH* ///
		, stack over(dealdecade, sort(dealdecade) lab(angle(60))) over(investor,  sort(tot)  descending) ///
		title("Industry Breakdown of Investments by Top VCs") ///
		legend(symx(small) symy(small) r(1)) yti("Deal Volume" "(`unit_pref' Billions)" " ") ///
		bar(1, col(green)) bar(2, col(cranberry)) bar(3, col(purple)) bar(4, col(gs7)) bar(5, col(dkorange))
	graph export "Output/`price'/top10_investors_bars_byInd.png", replace as(png) wid(1800) hei(700)
restore // -------------------------------------------------------------------

* HHI Plots -----------------------------------------------------------------------------
preserve
	bys primaryindustry dealyear: egen tot_vol = total(dealsizeusdmn)
	keep if top10
	collapse (sum) deal_vol = dealsizeusdmn (last) tot_vol, ///
							by(investor primaryindustry dealyear) fast
		gen sh_deal_vol = deal_vol/tot_vol*100
		gen sq_sh_deal_vol = sh_deal_vol^2
	collapse (sum) hhi = sq_sh_deal_vol, by(primaryindustry dealyear) fast
	assert inrange(hhi, 0, 10000)
	
	#delimit ;
	tw (line hhi dealyear if primaryindustry == "Healthcare", lc(purple) lp(-))
	   (line hhi dealyear if primaryindustry == "Healthcare IT", lc(gs7) lp(_))
	   (line hhi dealyear if primaryindustry == "Medical Devices & Equipment", lc(dkorange) lp(-))
	   (line hhi dealyear if primaryindustry == "Pharmaceuticals", lc(cranberry) lp(_))
	   (line hhi dealyear if primaryindustry == "Biotechnology", lc(green) lp(l)),
	 legend(order(1 "Healthcare" 2 "Healthcare IT" 3 "Medical Devices & Equipment"
				  4 "Pharmaceuticals" 5 "Biotechnology")
			colfirst r(2) symy(small) symx(vlarge))
	 title("Concentration of Funding Among Investors" "by Industry") yti("HHI-10" " ") xti("")
	 xlab(2000(5)2020);
	graph export "Output/`price'/ts_hhi_byInvestor_ByInd.png", replace as(png) wid(1200) hei(700);
	#delimit cr
restore // ------------------------------------------------------------------------------

levelsof primaryindustry, local(inds)

* Stacked Area Plots of Top 10 vs Other Over Time & By Industry -------------------------------
collapse (sum) deal_vol = dealsizeusdmn, by(top10 dealyear primaryindustry) fast
	reshape wide deal_vol, i(dealyear primaryindustry) j(top10)
		forval yn = 0/1 {
		replace deal_vol`yn' = deal_vol`yn'/1000
		lab var deal_vol`yn' "$ Billions"
	}
	gen tot_vol = deal_vol0 + deal_vol1

foreach ind of local inds {
	local ind_filename = subinstr("`ind'", " ", "", .)
	local ind_filename = subinstr("`ind_filename'", "&", "", .)
	
	#delimit ;
	tw (area tot_vol dealyear if primaryindustry == "`ind'", col(gs8))
	   (area deal_vol1 dealyear if primaryindustry == "`ind'", col(maroon)),
	 legend(order(2 "Top 10 `Loc'" 1 "Other `Loc'") r(1) symy(small) symx(small))
	 title("Concentration of Funding Among Investors") subti("`ind'")
	 yti("Deal Volume" "(`unit_pref' Billions)") xti("")
	 note("Top 10: `list_top10a'" "`list_top10b'", span);
	graph export "Output/`price'/top10_investors_stacked-`ind_filename'.png", replace as(png) wid(1200) hei(700);
	#delimit cr
}

drop tot_vol
reshape long deal_vol, i(dealyear primaryindustry) j(top10)

* Stacked Area Plots of Top 10 vs Other Over Time ---------------------------------------------
collapse (sum) deal_vol, by(top10 dealyear) fast
	reshape wide deal_vol, i(dealyear) j(top10)
	gen tot_vol = deal_vol0 + deal_vol1

#delimit ;
tw (area tot_vol dealyear, col(gs8))
   (area deal_vol1 dealyear, col(maroon)),
 legend(order(2 "Top 10 `Loc'" 1 "Other `Loc'") r(1) symy(small) symx(small))
 title("Concentration of Funding Among Investors") subti("`sub'")
 yti("Deal Volume" "(`unit_pref' Billions)") xti("")
 note("Top 10: `list_top10a'" "`list_top10b'", span);
graph export "Output/`price'/top10_investors_stacked-All.png", replace as(png) wid(1200) hei(700);
#delimit cr



} // end `plots_topinv'

*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
} // end CPIMEDSL/PCEPILFE loop
*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


/* ---- Guess Missing Funding Stage & Investor Tab of Grants No Long Used ----
*=========================================================================
*						GUESS MISSING FUNDING STAGE
if `guess_stage' == 1 {
*=========================================================================
/* ---------------------- USING INDUSTRY AND YEAR -------------------------
drop if stagegrp == ""
replace stagegrp = subinstr(stagegrp, " ", "", .)
collapse (count) n_deals = dealid, by(primaryindustry stagegrp dealyear) fast
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

collapse (count) n_deals = dealid, by(stagegrp pctl_bin) fast

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
*					TAB INVESTORS THAT MADE GRANTS
if `investor_tab' == 1 {
*=========================================================================

use `dealset', clear

replace stagegrp = "Grant" if stage == "Grant"

split investors, p(", ") gen(investor)
	drop investors
	keep dealid stagegrp investor*
reshape long investor, i(dealid stagegrp) j(i)
	drop if investor == ""

collapse (count) n = dealid, by(investor stagegrp) fast
	replace stagegrp = subinstr(stagegrp, " ", "", .)
	replace stagegrp = subinstr(stagegrp, "&", "", .)
reshape wide n, i(investor) j(stagegrp) string

} // end `investor_tab'
*/