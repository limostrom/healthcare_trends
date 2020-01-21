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