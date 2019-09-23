/*
Extract other country names

*/
#delimit ;
local countries zzz "Afghanistan" "Argentina" "Aruba" "Australia" "Melbourne" "Sydney" "Perth"
			"Austria" "Bangladesh" "Belgium" "Brussels" "Botswana" "Brazil"
			"Bulgaria" "Burkina Faso" "Cameroon" "Toronto" "Montreal" "Ontario" "Vancouver" "Canada"
			"Chile" "Cambodia" "Beijing" "Shanghai" "China" "Colombia" "Congo" "Costa Rica"
			"Croatia" "Cuba" "Cyprus" "Czech Republic" "Prague" "Copenhagen" "Denmark"
			"Ecuador" "Egypt" "Ethiopia" "England" "Estonia" "Helsinki" "Finland"
			"France" "New Caledonia" "Paris" "Germany" "Berlin" "FRG" "FGR" "Heidelberg"
			"Gambia" "Gabon" "Ghana" "Greece" "Guatemala" "Haiti" "Honduras" 
			"Hong Kong" "Hungary" "Iceland" "India" "New Delhi" "Indonesia" "Iran" 
			"Iceland" "Ireland" "Dublin" "Israel" "Milan" "Rome" "Italy" "Italia"
			"Jamaica" "Japan" "Tokyo" "Jordan" "Nairobi" "Kenya" "Korea" "Seoul"
			"Lao PDR" "Latvia" "Lebanon" "Lithuania" "Madagascar" "Malawi" "Malaysia"
			"Mali" "Mexico" "Morocco" "Mozambique" "Myanmar" "Nepal" "Nicaragua" "Nigeria"
			"Amsterdam" "Netherland" "New Zealand" "Oslo" "Norway" "Oman" "Oxford" "Pakistan"
			"Papua New Guinea" "Guinea" /*i think diff from PNG*/ "Panama" "Peru" "Philippines"
			"Poland" "Portugal" "Qatar" "Romania" "Moscow" "Russia" "Rwanda" "Saudi Arabia"
			"Scotland" "Edinburgh" "Senegal" "Serbia" "Sierra Leone" "Singapore" "Slovenia"
			"Slovakia" "Spain" "South Africa" "Sri Lanka" "Sudan"
			"Sweden" "Stockholm" "Swedish" "Geneva" "Switzerland" "Switerland"
			"Syria" "Taiwan" "Tanzania" "Thailand" "Togo" "Trinidad and Tobago"
			"Tunisia" "Turkey" "Uganda" "United Arab Emirates" "Ukraine" "Uruguay"
			"UK" "London" "U.K." "Surrey" "Glasgow" "United Kingdom" "Venezuela"
			"Viet Nam" "Vietnam" "West Indies" "Wales" "Yemen" "Zaire" "Zambia" "Zimbabwe";
#delimit cr

foreach c of local countries {
		dis "`c'"
		replace country = "`c'" if strpos(affl, "`c'") > 0 & country == ""
		replace country = "`c'" if country != "" & strpos(affl, "`c'") > 0 & ///
							strpos(affl, "`c'") < strpos(affl, country)
	}

	replace country = "USA" if strpos(affl, "USA") > 0 & ///
						(country == "" | strpos(affl, country) > strpos(affl, "USA"))

	replace country = "Australia" if inlist(country, "Australia", "Melbourne", "Sydney", "Perth")
	replace country = "Belgium" if inlist(country, "Belgium", "Brussels")
	replace country = "Canada" if inlist(country, "Canada", "Toronto", "Montreal", "Ontario", "Vancouver")
	replace country = "China" if inlist(country, "China", "Beijing")
	replace country = "Czech Republic" if inlist(country, "Czech Republic", "Prague")
	replace country = "Denmark" if inlist(country, "Denmark", "Copenhagen")
	replace country = "Finland" if inlist(country, "Finland", "Helsinki")
	replace country = "France" if inlist(country, "France", "New Caledonia", "Paris")
	replace country = "Germany" if inlist(country, "Germany", "FRG", "FGR", "Heidelberg", "Berlin")
	replace country = "Italy" if inlist(country, "Italy", "Milan", "Italia", "Rome")
	replace country = "India" if inlist(country, "India", "New Delhi")
	replace country = "Ireland" if inlist(country, "Ireland", "Dublin")
	replace country = "Japan" if inlist(country, "Japan", "Tokyo")
	replace country = "Kenya" if inlist(country, "Kenya", "Nairobi")
	replace country = "South Korea" if inlist(country, "Korea", "Seoul")
	replace country = "Netherlands" if inlist(country, "Netherland", "Amsterdam")
	replace country = "Norway" if inlist(country, "Norway", "Oslo")
	replace country = "Russia" if inlist(country, "Russia", "Moscow")
	replace country = "Sweden" if inlist(country, "Sweden", "Stockholm", "Swedish")
	replace country = "Switzerland" if inlist(country, "Switzerland", "Geneva", "Switerland")
	replace country = "United Kingdom" if inlist(country, "UK", "U.K.", "England", "London", ///
										"Edinburgh", "Scotland", "Wales", "Surrey", "Glasgow")
	replace country = "Vietnam" if inlist(country, "Vietnam", "Viet Nam")

