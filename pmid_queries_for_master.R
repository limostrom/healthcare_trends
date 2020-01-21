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
print(N)
  # Return list of article IDs to scrape later
  pmid_list = xml %>% 
    xml_node('IdList')
  pmid_list = str_extract_all(pmid_list,"\\(?[0-9]+\\)?")[[1]]
	
  Sys.sleep(0.3)

  i = 5000
  while (i < N) {
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

    Sys.sleep(0.3)
  }

  

  return(pmid_list)
  
}

pull_affs = function(id) {
  
# test example: id = 22368089

# Form URL using the term
  url = paste0('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=',
			id,
		   '&retmode=xml&api_key=ae06e6619c472ede6b6d4ac4b5eadecdb209')

  # Query PubMed and save result
  #xml = read_xml(curl(url, handle = curl::new_handle("useragent" = "Mozilla/5.0")))
  xml = read_xml(url)

print(id)

	gr = xml %>%
	  xml_node('GrantList')
	  gr = as.character(gr)
 	  gr = gsub("\n", "", gr)

	pt = xml %>%
	  xml_node('PublicationTypeList')
	  pt = as.character(pt)
	  pt = gsub("\n", "", pt)

	journal = xml %>%
	  xml_node('Journal')
	  journal = as.character(journal)
	  journal = gsub("\n", "", journal)

	date = xml %>%
	  xml_node('DateCompleted')
	  date = as.character(date)
	  date = gsub("\n", "", date)

	output = c(date, journal, pt, gr)

  Sys.sleep(runif(1,0.4,0.6))

  return(output)
}
## --------------------------------------------------------------------
# Author affiliations only reliably show up from 1988 on
years = as.character(1988:2018)
year_queries = paste0('(',years,'/01/01[PDAT] : ',years,'/12/31[PDAT])')

#list of queries to run year by year
queries_sub = read_tsv(file = 'GitHub/healthcare_trends/search_terms_for_pmids_lifesci_QA.txt')
queries = rep(queries_sub$Query, each=length(year_queries))
query_names = rep(queries_sub$Query_Name, each=length(year_queries))

queries = paste0(year_queries, queries)
query_names = paste0(query_names, years)

#Run through scraping function to pull out PMIDs
PMIDs = sapply(X = queries, FUN = pull_pmids) %>%
	unname()
for (i in 1:length(query_names)) {
	outfile = paste0('Amitabh/PMIDs/1988-2018/PMIDs_1988_',
				query_names[i],
				'.csv')
	subset = data.frame(unlist(PMIDs[i]), rep(query_names[i], length(unlist(PMIDs[i]))))
	write_csv(subset, outfile)
}
PMIDs = 22368089
info = sapply(X = unlist(PMIDs), FUN = pull_affs)
master = data.frame(pmid = unlist(PMIDs), gr = info$gr, pt = info$pt,
				journal=info$journal, date = info$date)

write_csv(master, path = 'Amitabh/Master_1988_2018.csv')

