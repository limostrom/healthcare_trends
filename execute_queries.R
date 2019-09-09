# Load package for web scraping
library(tidyverse)
library(rvest)

queries = read_tsv(file = 'search_terms_abbr.txt')

api_parse = function(query){
  
  search = URLencode(query)
  
  # Form URL using the term
  url = paste0('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=',search,'&tool=my_tool&email=my_email@example.com'
  )

  # Query PubMed and save result
  xml = read_xml(url)
  
  # Print Count of Articles
  pub_count = xml %>% 
    xml_node('Count') %>% 
    xml_double() 

  Sys.sleep(1)
  
  return(pub_count)
  
}

pub_counts = sapply(X = queries$Query, FUN = api_parse)
pub_counts = unname(pub_counts)

data = data.frame(
  query_name = queries$Query_Name,
  pub_count = pub_counts
)

write_csv(data, path = 'FILENAME HERE')

