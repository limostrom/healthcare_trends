/*
Extract other country names

*/
#delimit ;
local countries zzz "Afghanistan" "Algeria" "Andorra" "Angola" "Argentina" "Buenos Aires"
			"Armenia" "Aruba"
			"Australia" "Adelaide" "Bermuda" "Brisbane" "Canberra" "Melbourne" "Perth" "Sydney" 
			"Austria" "Bangladesh" "Belgium" "Brussels" "Bruxelles" "Belarus" "Benin"
			"Botswana" "Brazil" "Brasil" "Rio " "SÃ£o Paulo" "Bulgaria" "Burkina Faso" "Cameroon" 
			"Canada" "Toronto" "Montreal" "Ontario" "Ottawa" "Vancouver" 
			"Chile" "Cambodia" "Phnom Penh" "Cameroon" "Cameroun" "Chad"
			"China" "Chinese" "Beijing" "Shanghai" "Urumchi" "Urumqi"
			"Colombia" "BogotÃ¡" "Congo" "Costa Rica"
			"Croatia" "Cuba" "Cyprus" "Czech Republic" "Prague"
			"Denmark" "Danish" "Aarhus" "Copenhagen" "Faroe Islands" "Lyngby"
			"Dominican Republic"
			"Ecuador" "Egypt" "Cairo" "Ethiopia" "Addis Ababa" "England" "Estonia" "Helsinki" "Finland"
			"France" "French Guiana" "New Caledonia" "Nogent" "Paris" "Strasbourg" "Vitry Sur Seine"
			"Fiji" "French Polynesia" "Gaza," "Gaza "
			"German" "Deutschland" "FRG" "FGR" "DDR"
				"Berlin" "Bochum" "Halle" "Hamburg" "Heidelberg" "Mainz" "Munich" "Ulm," "Ulm "
			"Gambia" "Banjul" "Gabon" "Ghana" "GHANA" "Greece" "Thessaloniki" "Guatemala" "Haiti" "Port-au-Prince"
			"Honduras" "Hong Kong" "Hungary" "Budapest" "Iceland" 
			"India" "Bangalore" "Bombay" "Calcutta" "Kolkata" "Mumbai" "New Delhi" "Tamilnadu" "Tamil Nadu"
			"Indonesia" "Iran" "Ireland" "Dublin" "Iraq" "Baghdad"
			"Israel" "Jerusalem" "Haifa" "Tel Aviv" "Tel Hashomer"
			"Italy" "Italia" "Milan" "Pavia" "Rome" "Ivory Coast" "Abidjan" "CÃ´te d'Ivoire"
			"Jamaica" "Jordan" "Japan" "Kanagawa" "Osaka" "Tokyo" 
			"Kazakhstan" "Kenya" "Kilifi" "Nairobi" "Korea" "Seoul" "Kuwait"
			"Lao PDR" "Laos" "Latvia" "Lebanon" "Liberia" "Libya" "Lithuania" "Luxembourg" "Macdeonia"
			"Madagascar" "Antananarivo" "Malawi" "Chilumba" "Malaysia" "Mali" "Mauritius" "Mexico" "MÃ©xico" "Guanajuato"
			"Moldova" "Mongolia" "Monaco" "Morocco" "Mozambique" "Myanmar" "Nepal" "Nicaragua" "Nigeria"
			"Netherland" "Amsterdam" "Nijmegen" "Rijswijk" "New Zealand" "Auckland" 
			"Norway" "Norwegian" "Oslo" "Bergen" "Trondheim" "Oman" "Pakistan"
			"Papua New Guinea" "Guinea" "Panama" "PanamÃ" "Peru" "Philippines"
			"Poland" "Portugal" "Qatar" "Romania" "Russia" "USSR" "Tatarstan" "Moscow"
			"Rwanda" "Samoa" "Saudi Arabia"
			"Scotland" "Edinburgh" "Dundee" "Senegal" "Dakar" "Serbia" "Sierra Leone"
			"Singapore" "Slovenia" "Slovakia" "Solomon Islands" "Somaliland"
			"Spain" "Barcelona" "Madrid" "South Africa" "Cape Town" "Johannesburg" "Medunsa"
			"Sri Lanka" "Sudan" "Khartoum" "Swaziland"
			"Sweden" "Stockholm" "Swedish" "AlbaNova" "Gothenburg" "Goteborg" "Solna" 
			"Switzerland" "Switerland" "Basel" "Berne" "Epalinges" "Geneva" "Lausanne" "Zurich" "Swiss"
			"Syria" "Taiwan" "Tanzania" "Dar es Salaam" "Thailand" "Bangkok" "Tibet" "Timor-Leste"
			"Togo" "Tonga" "Trinidad and Tobago" "Tunisia" "Turkey" "Uganda" "Entebbe" "Kampala" 
			"United Arab Emirates" "Ukraine" "Uruguay"
			"UK" "Alverstoke" "Belfast" "Buckinghamshire" "Cheshire" "Glasgow" "Harrow" "Hertfordshire"
			"Kent" "Leeds" "Leicester" "Liverpool" "London" "Newcastle" "Nottingham" "Sheffield"
			"Staffordshire" "Surrey" "Swansea" "Whitchurch" "U.K." "United Kingdom"
			"Uzbekistan" "Venezuela" "Caracas" "Viet Nam" "Vietnam" "West Indies" "Wales" "Cardiff"
			"West Bank" "Nablus" "Birzeit" "Ramallah" "Yemen" "Yugoslavia" "Zaire" "Zambia" 
			"Zimbabwe" "Harare";
#delimit cr

foreach c of local countries {
		dis "`c'"
		replace country = "`c'" if strpos(affl, "`c'") > 0 & country == ""
		replace country = "`c'" if country != "" & strpos(affl, "`c'") > 0 & ///
							strpos(affl, "`c'") < strpos(affl, country)
	}

	replace country = "USA" if strpos(affl, "USA") > 0 & ///
						(country == "" | strpos(affl, country) > strpos(affl, "USA"))
	replace country = "USA" if strpos(affl, "National Science Foundation") > 0 & country == ""
	replace country = "USA" if strpos(affl, "Guam") > 0 & country == ""

	replace country = "Argentina" if inlist(country, "Argentina", "Buenos Aires")
	replace country = "Australia" if inlist(country, "Australia", "Adelaide", ///
									"Brisbane", "Canberra", "Melbourne", "Perth", "Sydney")
	replace country = "Belgium" if inlist(country, "Belgium", "Brussels", "Bruxelles")
	replace country = "Brazil" if inlist(country, "Brazil", "Brasil", "Rio ", "SÃ£o Paulo")
	replace country = "Cambodia" if inlist(country, "Cambodia", "Phnom Penh")
	replace country = "Cameroon" if inlist(country, "Cameroon", "Cameroun")
	replace country = "Canada" if inlist(country, "Canada", "Toronto", "Montreal", "Ontario", ///
										"Ottawa", "Vancouver")
	replace country = "China" if inlist(country, "China", "Chinese", "Beijing", "Shanghai", ///
										"Urumchi", "Urumqi")
	replace country = "Colombia" if inlist(country, "Colombia", "BogotÃ¡")
	replace country = "Czech Republic" if inlist(country, "Czech Republic", "Prague")
	replace country = "Denmark" if inlist(country, "Denmark", "Danish", "Aarhus", ///
									"Copenhagen", "Faroe Islands", "Lyngby")
	replace country = "Egypt" if inlist(country, "Egypt", "Cairo")
	replace country = "Ethiopia" if inlist(country, "Ethiopia", "Addis Ababa")
	replace country = "Finland" if inlist(country, "Finland", "Helsinki")
	replace country = "France" if inlist(country, "France", "French Guiana", "New Caledonia", ///
									"Nogent", "Strasbourg", "Paris", "Vitry Sur Seine")
	replace country = "The Gambia" if inlist(country, "Gambia", "Banjul")
	replace country = "Gaza Strip" if inlist(country, "Gaza,", "Gaza ")
	replace country = "Germany" if inlist(country, "German", "Deutschland", "FRG", "FGR", "DDR") ///
									| inlist(country, "Berlin", "Bochum", "Halle", "Hamburg", ///
											"Heidelberg", "Mainz", "Munich", "Ulm,", "Ulm ")
	replace country = "Ghana" if inlist(country, "Ghana", "GHANA")
	replace country = "Greece" if inlist(country, "Greece", "Thessaloniki")
	replace country = "Haiti" if inlist(country, "Haiti", "Port-au-Prince")
	replace country = "Hungary" if inlist(country, "Hungary", "Budapest")
	replace country = "Italy" if inlist(country, "Italy", "Italia", "Milan", "Pavia", "Rome")
	replace country = "India" if inlist(country, "Bangalore", "Bombay", "Calcutta", "Kolkata", ///
										"Mumbai", "New Delhi", "Tamilnadu", "Tamil Nadu")
	replace country = "Iraq" if inlist(country, "Iraq", "Baghdad")
	replace country = "Ireland" if inlist(country, "Ireland", "Dublin")
	replace country = "Israel" if inlist(country, "Israel", "Jerusalem", "Haifa", ///
										"Tel Aviv", "Tel Hashomer")
	replace country = "Ivory Coast" if inlist(country, "Ivory Coast", "Abidjan", "CÃ´te d'Ivoire")
	replace country = "Japan" if inlist(country, "Japan", "Kanagawa", "Osaka", "Tokyo")
	replace country = "Kenya" if inlist(country, "Kenya", "Nairobi", "Kilifi")
	replace country = "Laos" if inlist(country, "Laos", "Lao PDR")
	replace country = "Madagascar" if inlist(country, "Madagascar", "Antananarivo")
	replace country = "Malawi" if inlist(country, "Malawi", "Chilumba")
	replace country = "Mexico" if inlist(country, "Mexico", "MÃ©xico", "Guanajuato")
	replace country = "Netherlands" if inlist(country, "Netherland", "Amsterdam", "Nijmegen", "Rijswijk")
	replace country = "New Zealand" if inlist(country, "New Zealand", "Auckland")
	replace country = "Niger" if country == "" & strpos(affl, "Niger") > 0 // separate because Nigeria
	replace country = "Norway" if inlist(country, "Norway", "Norwegian", "Oslo", "Bergen", "Trondheim")
	replace country = "Panama" if inlist(country, "Panama", "PanamÃ")
	replace country = "Russia" if inlist(country, "Russia", "USSR", "Tatarstan", "Moscow")
	replace country = "Senegal" if inlist(country, "Senegal", "Dakar")
	replace country = "South Africa" if inlist(country, "South Africa", "Cape Town", "Johannesburg", "Medunsa")
	replace country = "South Korea" if inlist(country, "Korea", "Seoul")
	replace country = "Spain" if inlist(country, "Spain", "Barcelona", "Madrid")
	replace country = "Sudan" if inlist(country, "Sudan", "Khartoum")
	replace country = "Sweden" if inlist(country, "Sweden", "Stockholm", "Solna", "Swedish")
	replace country = "Switzerland" if inlist(country, "Switzerland", "Switerland", "Swiss", ///
												"Basel", "Berne", "Epalinges", "Geneva", "Lausanne", "Zurich")
	replace country = "Tanzania" if inlist(country, "Tanzania", "Dar es Salaam")
	replace country = "Thailand" if inlist(country, "Thailand", "Bangkok")
	replace country = "Uganda" if inlist(country, "Uganda", "Entebbe", "Kampala")
	replace country = "United Kingdom" if inlist(country, "UK", "U.K.", "England", "Scotland", ///
										"Edinburgh", "Dundee", "Wales", "Cardiff", "Bermuda") ///
										| inlist(country, "Alverstoke", "Belfast", "Buckinghamshire", ///
										"Cheshire", "Glasgow", "Harrow", "Hertfordshire", "Kent", "Leeds") ///
										| inlist(country, "Leicester", "Liverpool", "London", "Newcastle", ///
										"Nottingham", "Sheffield", "Staffordshire", "Surrey") ///
										| inlist(country, "Swansea", "Whitchurch")
	replace country = "Vietnam" if inlist(country, "Vietnam", "Viet Nam")
	replace country = "West Bank" if inlist(country, "West Bank", "Nablus", "Birzeit", "Ramallah")
	replace country = "Zimbabwe" if inlist(country, "Zimbabwe", "Harare")

