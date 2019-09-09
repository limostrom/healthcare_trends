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

years = as.character(1980:2018)
year_queries = paste0('(',years,'/01/01[PDAT] : ',years,'/12/31[PDAT])')

queries_sub = read_tsv(file = 'GitHub/healthcare_trends/search_terms.txt')
queries = rep(queries_sub$Query, each=length(year_queries))
query_names = rep(queries_sub$Query_Name, each=length(year_queries))

Q = data.frame(Query = queries, Query_Name = query_names)

Q$Query = rep(queries_sub$Query, each=length(year_queries))
Q$Query = paste0(Q$Query,' AND ',year_queries)

pub_counts = sapply(X = Q$Query[1:5], FUN = api_parse)

pub_counts = unname(pub_counts)

data = data.frame(
  year = years,
  query_name = Q$Query_Name,
  pub_count = pub_counts
)

write_csv(data, path = 'Amitabh/PubMed_Search_Results_byDisease.csv')

