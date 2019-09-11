# Load package for web scraping
library(tidyverse)
library(rvest)

api_parse = function(query){
  
  search = URLencode(query)
  
  # Form URL using the term
  url = paste0('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=',
                search,
                '&tool=my_tool&email=my_email@example.com'
  )

  # Query PubMed and save result
  xml = read_xml(url)
  
  # Print Count of Articles
  pub_count = xml %>% 
    xml_node('Count') %>% 
    xml_double() 

  Sys.sleep(0.5)
  
  return(pub_count)
  
}

## --------------------------------------------------------------------
start_year = 2005

# set to econ or diseases:
group_term = "diseases"

years = as.character(start_year:2018)
year_queries = paste0('(',years,'/01/01[PDAT] : ',years,'/12/31[PDAT])')

infile = paste0('GitHub/healthcare_trends/search_terms_',
			group_term,
			'_',
			as.character(start_year),
			'.txt')
queries_sub = read_tsv(file = infile)
queries = rep(queries_sub$Query, each=length(year_queries))
query_names = rep(queries_sub$Query_Name, each=length(year_queries))

Q = data.frame(Query = queries, Query_Name = query_names)

Q$Query = rep(queries_sub$Query, each=length(year_queries))
Q$Query = paste0(Q$Query,' AND ',year_queries)

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
if (group_term == "econ") {
	outfile = paste0('Amitabh/PubMed_Search_Results_MedvsEcon_from',
				as.character(start_year),
				'.csv')
}
write_csv(data, path = outfile)



