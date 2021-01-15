/*
preqin_geo_plots.do

1. Plots by industry of VC deals with VCs or start-ups from one of the top 10 MSAs
2. Plots related to the VC and start-up being based in the same MSA

*/
clear all
cap log close
pause on

*Keep codes that reshape long VC cities
	* reshape wide states
	* merge with census cbsacodes to figure out which city-state combos make sense
*Keep US investors only
*Reshape long again portfolio cities (almost always only 1 anyway, if not always)
*merge with census cbsacodes on portfolio cities
*collapse (max) on whether same MSA by deal
* collapse (sum) and (count) to determine % deals in same MSA by:
	* (1) top MSAs
	* (2) by industry
	* (3) by funding stage

global repo "C:/Users/lmostrom/Documents/GitHub/healthcare_trends/"
global drop "C:/Users/lmostrom/Dropbox/Amitabh"

cap cd "$drop/VC_Deals/"	

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
*===============================================================================
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

gen stagesort = 1 if stagegrp == "Seed & Angel"
	replace stagesort = 2 if stagegrp == "Series A & B"
	replace stagesort = 3 if stagegrp == "Expansion"
	replace stagesort = 4 if stagegrp == "Late Stage"
	
	/*------------------------------------------------------------------------
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
*			 TOP 10 PORTFOLIO & INVESTING MSAs BY INDUSTRY 
*===============================================================================

foreach firm in /*"Inv"*/ "Pf" {
	
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
				replace `varname'msa = "Denver-Boulder" if strpos(`state', "CO") > 0 ///
					& `varname'city == "Denver"
				replace `varname'msa = "Denver-Boulder" if strpos(`state', "CO") > 0 ///
					& `varname'city == "Boulder"
				replace `varname'msa = "Durham" if strpos(`state', "NC") > 0 ///
					& `varname'city == "Chapel Hill"
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
			gen drugs = inlist(primaryindustry, "Biotechnology", "Pharmaceuticals")
			bys drugs: egen vc_drugs_dollars = total(dealsizeusdmn)
				replace vc_drugs_dollars = . if drugs == 0
			keep if top10
			/*gen dealdecade = int(dealyear/10)*10
				tostring dealdecade, replace
				replace dealdecade = dealdecade + "s"*/
			replace primaryindustry = subinstr(subinstr(primaryindustry, " ", "", .), "&","",.)
			collapse (sum) deal_vol = dealsizeusdmn (max) vc_tot_dollars vc_drugs_dollars, ///
						by(`varname'`grpvar' primaryindustry /*dealdecade*/) fast
				gen sh_deal_vol = deal_vol/vc_tot_dollars*100
				gen sh_drugs = deal_vol/vc_drugs_dollars*100
				replace deal_vol = deal_vol/1000
				drop vc_drugs_dollars
			replace primaryindustry = "MedicalDevices" if primaryindustry == "MedicalDevicesEquipment"
			reshape wide deal_vol sh_deal_vol sh_drugs, i(`varname'`grpvar' /*dealdecade*/) j(primaryindustry) string
				lab var deal_volBiotech "Biotechnology"
				lab var deal_volHealthcare "Healthcare"
				lab var deal_volHealthcareIT "Healthcare IT"
				lab var deal_volMedicalDev "Medical Devices"
				lab var deal_volPharma "Pharmaceuticals"
				lab var sh_deal_volBiotech "Biotechnology"
				lab var sh_drugsBiotech "Biotechnology"
				lab var sh_deal_volHealthcare "Healthcare"
				lab var sh_deal_volHealthcareIT "Healthcare IT"
				lab var sh_deal_volMedicalDev "Medical Devices"
				lab var sh_deal_volPharma "Pharmaceuticals"
				lab var sh_drugsPharma "Pharmaceuticals"
			egen tot_vol = rowtotal(deal_vol*)
			egen drugs_vol = rowtotal(deal_volB deal_volP)
			bys `varname'`grpvar': egen tot = total(tot_vol)
			bys `varname'`grpvar': egen tot_drugs = total(drugs_vol)
			
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
			
			egen rowtot_sh = rowtotal(sh_deal_vol*)
			egen tot_sh = total(rowtot_sh)
			local Vpct: dis tot_sh
			local Vpct = round(`Vpct', 1)
			
			* Graph by Share of VC Dollars
			graph bar (asis) sh_deal_volB sh_deal_volP sh_deal_volM sh_deal_volH*,  ///
				stack /*over(dealdecade, sort(dealdecade) lab(angle(60)))*/ ///
					over(`varname'`grpvar',  sort(tot)  descending) ///
				title("Industry Breakdown of VC Funding Recipient Firms") ///
				subtitle("Top MSAs account for `Vpct'% of VC Dollars in US Healthcare") ///
				legend(symx(small) symy(small) r(1)) yti("Share of VC Dollars in Healthcare (%)" " ") ///
				bar(1, col(green)) bar(2, col(cranberry)) bar(3, col(purple)) ///
										bar(4, col(dkorange)) bar(5, col(gs7))
			graph export "Output/`price'/top10_bars_`firm'`loc_abbr'_%_byInd.png", ///
				replace as(png) wid(1800) hei(700)
				
			egen rowtot_drugs = rowtotal(sh_drugsB sh_drugsP)
			egen drug_totsh = total(rowtot_drugs)
			local Dpct: dis drug_totsh
			local Dpct = round(`Dpct', 1)
			
			* Graph by Share of VC Dollars in Drugs
			graph bar (asis) sh_drugsB sh_drugsP,  ///
				stack over(`varname'`grpvar',  sort(tot_drugs)  descending) ///
				title("Breakdown of VC-Backed Drugs Start-Ups") ///
				subtitle("Top MSAs account for `Dpct'% of VC Dollars in Drugs") ///
				legend(symx(small) symy(small) r(1)) yti("Share of VC Dollars in Drugs (%)" " ") ///
				bar(1, col(green)) bar(2, col(cranberry))
			graph export "Output/`price'/top10_bars_`firm'`loc_abbr'_%_Drugs.png", ///
				replace as(png) wid(1800) hei(700)
		restore // -------------------------------------------------------------------
		sdf
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

* Plots of VC & PF Company in Same MSA
use `dealset', clear
drop if stage == "Grants"

preserve
	keep if investorcity != ""
	keep if portfoliocompanycountry == "US"
	collapse (sum) dealsizeusdmn
	local V: dis dealsizeusdmn // total VC $s going to US start-ups
restore

keep if portfoliocompanycountry == "US"


split investorcity, p(", ")
	drop investorcity
reshape long investorcity, i(dealid dealsizeusdmn investorstate) j(cityno)
	drop if investorcity == ""

replace investorcity = "Boston" if strpos(investorstate, "MA") > 0 ///
	& inlist(investorcity, "Cambridge", "Waltham", "Boston")
replace investorcity = "Boston" if strpos(investorstate, "MA") > 0 ///
	& strpos(investorstate, "KY") == 0 & investorcity == "Lexington"
*Bay Area all going to be consolidated later anyway
replace investorcity = "San Francisco" if strpos(investorstate, "CA") > 0 ///
	& (inlist(investorcity, "Menlo Park", "Palo Alto", ///
		"San Mateo", "Portola Valley", "San Jose", "Santa Clara", "Mountain View") ///
	| inlist(investorcity, "Redwood City", "South San Francisco", ///
		"Berkeley", "Emeryville", "Sunnyvale", "Fremont"))
replace investorcity = "Los Angeles" if strpos(investorstate, "CA") > 0 ///
	& inlist(investorcity, "Irvine", "Santa Monica", "Orange", "Pasadena")
replace investorcity = "New York" if strpos(investorstate, "NJ") > 0 ///
	& inlist(investorcity, "New Brunswick")
replace investorcity = "San Diego" if strpos(investorstate, "CA") > 0 ///
	& inlist(investorcity, "La Jolla")
replace investorcity = "Houston" if strpos(investorstate, "TX") > 0 ///
	& inlist(investorcity, "The Woodlands")
replace investorcity = "Philadelphia" if strpos(investorstate, "PA") > 0 ///
	& inlist(investorcity, "Conshohocken")
replace investorcity = "Ann Arbor" if strpos(investorstate, "MI") > 0 ///
	& inlist(investorcity, "Ann Arbour")
	

replace investorstate = subinstr(investorstate, " ", "", .)
split investorstate, p(",") gen(state_abbr)
	drop investorstate

ren investorcity city
gen msa = .
gen state = ""
foreach var of varlist state_abbr* {
	local ii = substr("`var'", 11, .)
	dis "`ii'"
	ren state_abbr`ii' state_abbr
	merge m:1 city state_abbr using "../PubMed/MSA_city_state_clean.dta", ///
			keep(1 3) keepus(cbsacode) nogen
		destring cbsacode, replace
		ren cbsacode cbsacode`ii'
		replace msa = cbsacode`ii' if cbsacode`ii' != .
		replace state = state_abbr if cbsacode`ii' != .
	ren state_abbr state_abbr`ii'
}

*fre msa // about 80% matched to CBSA codes
ren city inv_city
ren state inv_state
ren msa inv_msa
	replace inv_msa = 41860 if inv_msa == 41940 // Bay Area (SF + SJ)
drop state_abbr* cbsacode*

* Now clean portfolio company MSAs
ren portfoliocompanycity city
ren portfoliocompanystate state_abbr
replace city = "Boston" if state_abbr == "MA" ///
	& inlist(city, "Cambridge", "Waltham", "Lexington")
*Bay Area all going to be consolidated later anyway
replace city = "San Francisco" if state_abbr == "CA" ///
	& (inlist(city, "Menlo Park", "Palo Alto", ///
		"San Mateo", "Portola Valley", "San Jose", "Santa Clara", "Mountain View") ///
	| inlist(city, "Redwood City", "South San Francisco", ///
		"Berkeley", "Emeryville", "Sunnyvale", "Fremont"))
replace city = "Los Angeles" if state_abbr == "CA" ///
	& inlist(city, "Irvine", "Santa Monica", "Orange", "Pasadena")
replace city = "New York" if state_abbr == "NJ" ///
	& inlist(city, "New Brunswick")
replace state_abbr = "NY" if state_abbr == "NJ" ///
	& city == "New York"
replace city = "San Diego" if state_abbr == "CA" ///
	& inlist(city, "La Jolla")
replace city = "Houston" if state_abbr == "TX" ///
	& inlist(city, "The Woodlands")
replace city = "Philadelphia" if state_abbr == "PA" ///
	& inlist(city, "Conshohocken")
replace city = "Ann Arbor" if state_abbr == "MI" ///
	& inlist(city, "Ann Arbour")

merge m:1 city state_abbr using "../PubMed/MSA_city_state_clean.dta", ///
			keep(1 3) keepus(cbsacode) nogen
		destring cbsacode, replace
ren cbsacode pf_msa
	replace pf_msa = 41860 if pf_msa == 41940 // Bay Area (SF + SJ)
ren city pf_city
ren state_abbr pf_state

sort dealid inv_msa pf_msa
br dealid pf_msa inv_msa
gen same_msa = pf_msa == inv_msa
collapse (max) same_msa (first) dealsizeusdmn primaryindustry stagegrp stagesort pf_msa pf_city, by(dealid)

preserve
	collapse (count) n_deals = dealid ///
			 (sum) deal_vol = dealsizeusdmn, ///
		by(pf_msa pf_city) fast
	drop if pf_msa == .
	egen msa_vol_rank = rank(deal_vol), field
	keep if msa_vol_rank <= 10
	levelsof pf_city, local(cities_list) sep(", ")
	keep pf_msa msa_vol_rank
	tempfile top10msas
	save `top10msas', replace
restore

preserve // --- Bar Plots by Stage Group ---------------------------------------
	collapse (count) n_deals = dealid ///
			 (sum) deal_vol = dealsizeusdmn, ///
		by(stagegrp stagesort same_msa pf_msa) fast
	merge m:1 pf_msa using `top10msas', gen(top10)
	collapse (sum) n_deals deal_vol, by(stagegrp stagesort same_msa top10)
	gen sh_deal_vol = deal_vol/`V'*100
		lab var sh_deal_vol "% of total VC $s invested in US start-ups"
	drop if inlist(stagegrp, "", "Unspecified")
	reshape wide n_deals deal_vol sh_deal_vol, i(stagegrp stagesort top10) j(same_msa)
		lab var n_deals0 "Not in Same MSA"
		lab var n_deals1 "VC & Firm in Same MSA"
		lab var deal_vol0 "Not in Same MSA"
		lab var deal_vol1 "VC & Firm in Same MSA"
		lab var sh_deal_vol0 "Not in Same MSA"
		lab var sh_deal_vol1 "VC & Firm in Same MSA"
		
	lab def merges 1 "Other MSAs" 3 "Top 10 MSA"
	lab val top10 merges
	
	#delimit ;
	graph bar (asis) sh_deal_vol1 sh_deal_vol0, stack
		over(top10, descending lab(angle(45))) over(stagegrp, sort(stagesort))
		bar(1, col(navy)) bar(2, col(gs10))
		yti("Share of VC Dollars in US Start-Ups" "(% of 2020 USD)")
		legend(pos(12)) note("Top 10 MSAs: `cities_list'");
	graph export "Output/`price'/sameMSA_stacked_bystage_bytop10.png", replace as(png) wid(1200) hei(700);
	
	collapse (sum) n_deals? deal_vol? sh_deal_vol?, by(stagegrp stagesort);
		lab var sh_deal_vol0 "Not in Same MSA";
		lab var sh_deal_vol1 "VC & Firm in Same MSA";
	graph bar (asis) sh_deal_vol1 sh_deal_vol0, stack
		over(stagegrp, sort(stagesort))
		bar(1, col(navy)) bar(2, col(gs10))
		yti("Share of VC Dollars in US Start-Ups" "(% of 2020 USD)")
		legend(pos(12));
	graph export "Output/`price'/sameMSA_stacked_bystage.png", replace as(png) wid(1200) hei(700);
	
	
	#delimit cr
restore // ---------------------------------------------------------------------

preserve // --- Bar Plots by Primary Industry ---------------------------------------
	collapse (count) n_deals = dealid ///
			 (sum) deal_vol = dealsizeusdmn, ///
		by(primaryindustry same_msa pf_msa) fast
	merge m:1 pf_msa using `top10msas', gen(top10)
	collapse (sum) n_deals deal_vol, by(primaryindustry same_msa top10)
	gen sh_deal_vol = deal_vol/`V'*100
		lab var sh_deal_vol "% of total VC $s invested in US start-ups"
	reshape wide n_deals deal_vol sh_deal_vol, i(primaryindustry top10) j(same_msa)
		lab var sh_deal_vol0 "Not in Same MSA"
		lab var sh_deal_vol1 "VC & Firm in Same MSA"
		
	lab def merges 1 "Other MSAs" 3 "Top 10 MSA"
	lab val top10 merges
	
	gen indsort = 1 if primaryindustry == "Biotechnology"
	replace indsort = 2 if primaryindustry == "Pharmaceuticals"
	replace primaryindustry = "Medical Devices" if primaryindustry == "Medical Devices & Equipment"
	replace indsort = 3 if primaryindustry == "Medical Devices"
	replace indsort = 4 if primaryindustry == "Healthcare"
	replace indsort = 5 if primaryindustry == "Healthcare IT"
	
	#delimit ;
	graph bar (asis) sh_deal_vol1 sh_deal_vol0, stack
		over(top10, descending lab(angle(45))) over(primaryindustry, sort(indsort))
		bar(1, col(navy)) bar(2, col(gs10))
		yti("Share of VC Dollars in US Start-Ups" "(% of 2020 USD)")
		legend(pos(12)) note("Top 10 MSAs: `cities_list'");
	graph export "Output/`price'/sameMSA_stacked_byind_bytop10.png", replace as(png) wid(1200) hei(700);
	
	collapse (sum) n_deals? deal_vol? sh_deal_vol?, by(primaryindustry indsort);
		lab var sh_deal_vol0 "Not in Same MSA";
		lab var sh_deal_vol1 "VC & Firm in Same MSA";
	graph bar (asis) sh_deal_vol1 sh_deal_vol0, stack
		over(primaryindustry, sort(indsort))
		bar(1, col(navy)) bar(2, col(gs10))
		yti("Share of VC Dollars in US Start-Ups" "(% of 2020 USD)")
		legend(pos(12));
	graph export "Output/`price'/sameMSA_stacked_byind.png", replace as(png) wid(1200) hei(700);
		
	#delimit cr
restore // ---------------------------------------------------------------------
preserve // --- Bar Plots by Start-Up MSA --------------------------------------
	merge m:1 pf_msa using `top10msas', gen(top10)
		keep if top10 == 3
	bys pf_msa: ereplace pf_city = mode(pf_city)
	collapse (count) n_deals = dealid (sum) deal_vol = dealsizeusdmn ///
			 (first) pf_city, ///
		by(same_msa pf_msa msa_vol_rank) fast
	gen sh_deal_vol = deal_vol/`V'*100
		lab var sh_deal_vol "% of total VC $s invested in US start-ups"
	reshape wide n_deals deal_vol sh_deal_vol, i(pf_msa pf_city msa_vol_rank) j(same_msa)
		lab var sh_deal_vol0 "Not in Same MSA"
		lab var sh_deal_vol1 "VC & Firm in Same MSA"
		
	replace pf_city = "Bay Area" if pf_city == "San Francisco"
	replace pf_city = "Greater Boston" if pf_city == "Boston"
	
	#delimit ;
	graph bar (asis) sh_deal_vol1 sh_deal_vol0, stack
		over(pf_city, sort(msa_vol_rank) lab(angle(45)))
		bar(1, col(navy)) bar(2, col(gs10))
		yti("Share of VC Dollars in US Start-Ups" "(% of 2020 USD)")
		legend(pos(12));
	graph export "Output/`price'/sameMSA_stacked_byMSA.png", replace as(png) wid(1200) hei(700);
	#delimit cr
	
restore // ---------------------------------------------------------------------



	
*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
} // end CPIMEDSL/PCEPILFE loop
*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

