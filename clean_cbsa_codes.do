/*
Clean the CBSA codes into MSAs by city and state


*/

import excel "US_Census_CBSAs_9-2018.xls", clear cellrange(A3:E1918) first

ren *, lower

keep if metropolitanmicropolitan == "Metropolitan Statistical Area"
	drop metropolitan*

split cbsatitle, gen(cbsa) p(", ")
ren cbsa1 cities
ren cbsa2 states
	split states, gen(state) p("-")

egen tag_city_cbsa = tag(cities cbsacode)
	keep if tag_city_cbsa
	drop states

reshape long state, i(cbsacode cities) j(j)
	drop if state == ""
	drop j

split cities, gen(city) p("-")

reshape long city, i(cbsacode cities state) j(j)
	drop if city == ""
	drop j

keep cbsacode city state
isid city state

drop if city == "California"
replace city = "Honolulu" if city == "Urban Honolulu"

local state_names zzz "Alabama" "Alaska" "Arizona" "Arkansas" "California" "Colorado" "Connecticut" ///
						"Delaware" "Florida" "Georgia" "Hawaii" "Idaho" "Illinois" "Indiana" "Iowa" ///
						"Kansas" "Kentucky" "Louisiana" "Maine" "Maryland" "Massachusetts" "Michigan" ///
						"Minnesota" "Mississippi" "Missouri" "Montana" "Nebraska" "Nevada" ///
						"New Hampshire" "New Jersey" "New Mexico" "New York" "North Carolina" ///
						"North Dakota" "Ohio" "Oklahoma" "Oregon" "Pennsylvania" "Rhode Island" ///
						"South Carolina" "South Dakota" "Tennessee" "Texas" "Utah" "Vermont" ///
						"Virginia" "Washington" "West Virginia" "Wisconsin" "Wyoming" "Puerto Rico"

levelsof state, local(state_abbrs)
levelsof city, local(city_names)

ren state state_abbr

save CBSA_city_state_clean.dta, replace