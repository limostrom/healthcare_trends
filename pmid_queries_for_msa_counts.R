# Load package for web scraping & cleaning strings
#install.packages("stringr")
library(tidyverse)
library(rvest)
library(stringr)

pull_pmids = function(query){
  
  search = URLencode(query)
  
  i = 0
  # Form URL using the term
  url = paste0('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&retmax=5000&retstart=',
                i,
		            '&term=',
		            search,
                '&tool=my_tool&email=my_email@example.com'
  )

  # Query PubMed and save result
  xml = read_xml(url)
  
  # Store total number of papers so you know when to stop looping
  N = xml %>%
    xml_node('Count') %>%
    xml_double()

  # Return list of article IDs to scrape later
  pmid_list = xml %>% 
    xml_node('IdList')
  pmid_list = str_extract_all(pmid_list,"\\(?[0-9]+\\)?")[[1]]
	
  Sys.sleep(0.2)

  i = 5000
  while (i < 5000) {
    # Form URL using the term
    url = paste0('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&retmax=5000&retstart=',
                i,
                '&term=',
                search,
                '&tool=my_tool&email=my_email@example.com')

    # Query PubMed and save result
    xml = read_xml(url)

    new_ids = xml %>%
      xml_node('IdList')
    new_ids = str_extract_all(new_ids,"\\(?[0-9]+\\)?")[[1]]


    i = i + 5000

    pmid_list = append(pmid_list, new_ids)

    Sys.sleep(0.2)
  }

  

  return(pmid_list)
  
}

pull_affs = function(id) {
  
# Form URL using the term
  url = paste0('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=',
			id,
		   '&retmode=xml')
  
  # Query PubMed and save result
  xml = read_xml(url)
  
  # Store total number of papers so you know when to stop looping
  affil = xml %>%
    xml_node('AffiliationInfo')
  #affil = str_extract_all(affil,"\\(?[0-9]+\\)?")[[1]]
  #affil = Filter(length(affil) == 5, affil)

  Sys.sleep(0.2)

  return(affil)
}
## --------------------------------------------------------------------
years = as.character(1980:2018)
year_queries = paste0('(',years,'/01/01[PDAT] : ',years,'/12/31[PDAT])')

#list of queries to run year by year
queries_sub = read_tsv(file = 'GitHub/healthcare_trends/search_terms_for_pmids.txt')
queries = rep(queries_sub$Query, each=length(year_queries))
query_names = rep(queries_sub$Query_Name, each=length(year_queries))

queries = paste0(year_queries, queries)
query_names = paste0(query_names, years)

#Run through scraping function to pull out PMIDs
PMIDs = sapply(X = queries, FUN = pull_pmids) %>%
	unname()
colnames(PMIDs) = query_names

#Must be data frame to write as CSV
PMIDs = as.data.frame(PMIDs)
write_csv(PMIDs, path = 'Amitabh/PMIDs_subset.csv')

#Must be vector to run through scraping function again
PMIDs = matrix(PMIDs) %>%
	unlist()

AuthAffs = sapply(X = PMIDs, FUN = pull_affs)
affs_list = data.frame(pmid = PMIDs, affl = AuthAffs)

write_csv(affs_list, path = 'Amitabh/AuthAffs_subset.csv')


