/*
clean_msas_pubmed_preqin.do

(1) Opens QA Metadata file & cleans MSAs
(2) Opens Not QA 5% sample & cleans MSAs
(3) Opens VC data from Preqin and cleans MSAs

*/
clear all
cap log close
pause on



local qa 1
local notqa 0

