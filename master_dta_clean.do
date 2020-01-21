/*
master_dta_clean.do

*/
/*
pause on

cd "C:\Users\lmostrom\Documents\Amitabh\Master_dta"


use raw_samp1pct.dta, clear

gen mesh_na = mesh == "NA"
tab mesh_na

split mesh, p("</MeshHeading>")
ren mesh mesh_raw

*reshape long mesh, i(pmid) j(termN)

forval x=1/53 {
	gen start = strpos(mesh`x', "MajorTopicYN=") + 17
	gen end = strpos(mesh`x', "</DescriptorName>")
	gen len = end-start
	replace mesh`x' = substr(mesh`x', start, len)
	drop start end len
}
drop if substr(mesh1, 7, 10) == "Geographic"
*/

levelsof mesh, local(terms)
local n=0
foreach term of local terms {
	local ++n
	dis `n'
}
dis `n'



*reshape long mesh, i(pmid) j(termN)