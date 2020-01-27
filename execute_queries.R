# Load package for web scraping
library(tidyverse)
library(rvest)

api_parse = function(query){
  
  search = URLencode(query)
  
  # Form URL using the term
  url = paste0('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=',
                search,
                '&tool=my_tool&email=my_email@example.com')
  # '&api_key=ae06e6619c472ede6b6d4ac4b5eadecdb209'

  # Query PubMed and save result
  xml = read_xml(url)
  
  # Print Count of Articles
  pub_count = xml %>% 
    xml_node('Count') %>% 
    xml_double() 

  Sys.sleep(runif(1,0.6,0.8))
  
  return(pub_count)
  
}

## --------------------------------------------------------------------
start_year = 1980

# set to econ or diseases:
group_term = "GBDlev2"

years = as.character(start_year:2018)
year_queries = paste0('(',years,'/01/01[PDAT] : ',years,'/12/31[PDAT])')

infile = paste0('GitHub/healthcare_trends/search_terms_',
			group_term,
			'_',
			as.character(start_year),
			'.txt')
queries_sub = read_tsv(file = infile)
	if (group_term == "all") {
		if (start_year == 1980) {queries_sub[6,2] = " "}
		if (start_year == 2005) {queries_sub[8,2] = " "}
	}
queries = rep(queries_sub$Query, each=length(year_queries))
query_names = rep(queries_sub$Query_Name, each=length(year_queries))

Q = data.frame(Query = queries, Query_Name = query_names)

Q$Query = rep(queries_sub$Query, each=length(year_queries))
if (group_term == "all" | group_term == "piecharts_notQA") {
	Q$Query = paste0(year_queries, ' ', Q$Query)
}
if (group_term != "all") {
	Q$Query = paste0(Q$Query,' AND ',year_queries)
}

pub_counts = sapply(X = Q$Query, FUN = api_parse)

pub_counts = unname(pub_counts)

data = data.frame(
  year = years,
  query_name = Q$Query_Name,
  pub_count = pub_counts
)

if (group_term == "diseases") {
	outfile = paste0('Amitabh/PubMed_Search_Results_byDisease_from',
				as.character(start_year),
				'.csv')
}
if (group_term == "diseases_clintr") {
	outfile = paste0('Amitabh/PubMed_Search_Results_CT_byDisease_from',
				as.character(start_year),
				'.csv')
}
if (group_term == "diseases_BVPW") {
	outfile = paste0('Amitabh/PubMed_Search_Results_byBVPW_from',
				as.character(start_year),
				'.csv')
}
if (group_term == "BVPW_ex_disease_cats") {
	outfile = paste0('Amitabh/PubMed_Search_Results_byBVPW_exDiseases_from',
				as.character(start_year),
				'.csv')
}
if (group_term == "econ") {
	outfile = paste0('Amitabh/PubMed_Search_Results_MedvsEcon_from',
				as.character(start_year),
				'.csv')
}
if (group_term == "health_econ_and_policy") {
	outfile = paste0('Amitabh/PubMed_Search_Results_HealthEconPolicy_from',
				as.character(start_year),
				'.csv')
}
if (group_term == "topGBDs") {
	outfile = paste0('Amitabh/PubMed_Search_Results_topGBDs_from',
				as.character(start_year),
				'.csv')
}
if (group_term == "topGBDs_clintr") {
	outfile = paste0('Amitabh/PubMed_Search_Results_CT_topGBDs_from',
				as.character(start_year),
				'.csv')
}
if (group_term == "GBDlev2") {
	outfile = paste0('Amitabh/PubMed_Search_Results_GBDlev2_from',
				as.character(start_year),
				'.csv')
}
if (group_term == "GBDlev2_notQA") {
	outfile = paste0('Amitabh/PubMed_Search_Results_GBDlev2_notQA_from',
				as.character(start_year),
				'.csv')
}
if (group_term == "GBDlev2_clintr") {
	outfile = paste0('Amitabh/PubMed_Search_Results_CT_GBDlev2_from',
				as.character(start_year),
				'.csv')
}
if (group_term == "GBDlev2_clintr_notQA") {
	outfile = paste0('Amitabh/PubMed_Search_Results_CT_GBDlev2_notQA_from',
				as.character(start_year),
				'.csv')
}
if (group_term == "all") {
	outfile = paste0('Amitabh/PubMed_Search_Results_all_from',
				as.character(start_year),
				'.csv')
}
if (group_term == "piecharts") {
	outfile = paste0('Amitabh/PubMed_Search_Results_forPies_from',
				as.character(start_year),
				'.csv')
}
if (group_term == "piecharts_notQA") {
	outfile = paste0('Amitabh/PubMed_Search_Results_forPies_notQA_from',
				as.character(start_year),
				'.csv')
}

write_csv(data, path = outfile)


