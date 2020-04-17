/*
check_mutually_exclusive.do

Codes that check if the lists of PMIDs are mutually exclusive by
merging them all together and verifying none match

*/
pause on
/*
*--- DISCIPLINE PIE CHARTS ---*
forval yr = 2005/2018 {
	dis "`yr'"
	foreach fund in "NIH" "Priv" {
		dis "`fund'"
		foreach group in "MandBCP1" "MandBCP2" "MandBCP3" "Bio" "Chem" "Phys" "Mech" {
			dis "`group'"
			import delimited "PMIDs/PieCharts/PMIDs_2005_`group'_`fund'`yr'.csv", clear varn(1)
			tempfile `group'_`fund'
			save ``group'_`fund'', replace
		}
	}
	
	use `MandBCP1_NIH', clear
		merge 1:1 unlistpmidsi using `MandBCP1_Priv'
			assert _merge != 3
			drop _merge
	foreach fund in "NIH" "Priv" {
		foreach group in "MandBCP2" "MandBCP3" "Bio" "Chem" "Phys" "Mech" {
			dis "`group' `fund'"
			merge 1:1 unlistpmidsi using ``group'_`fund'', force
				assert _merge != 3
				drop _merge
		}
	}

}
*/
*--- DRUGS & DEVICES PIE CHARTS ---*
cap cd "C:\Users\lmostrom\Dropbox\Amitabh\"
forval yr = 1992/2019 {
	dis "`yr'"
	foreach pt in "Pub" "CT" {
		dis "`pt'"
		foreach group in "drugs" "devices" "surgery" "healthcare" "treatment" ///
							"drugs-and-dev" "dev-and-surg" {
			dis "`group'"
			import delimited "PMIDs/PieCharts/PMIDs_drugs_devices_`group'_`pt'`yr'.csv", clear varn(1)

			if "`group'" == "drugs-and-dev" local group drugsdev
			if "`group'" == "dev-and-surg" local group devsurg
			tempfile `group'_`pt'
			save ``group'_`pt'', replace
		}
	}
	
	use `drugs_Pub', clear
	pause
		merge 1:1 count using `drugs_CT'
			assert _merge != 3
			drop _merge
	foreach pt in "Pub" "CT" {
		foreach group in "devices" "surgery" "healthcare" "treatment" ///
							"drugsdev" "devsurg" {
			dis "`group' `pt' `yr'"
			merge 1:1 count using ``group'_`pt'', force
				assert _merge != 3
				drop _merge
		}
	}

}