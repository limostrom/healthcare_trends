#-----------------------------------------------------------------------
# Scrape PMIDs from PubMed for:                                        |
#    (1) All journal articles from the top 7 journals                  |
#    (2) All journal articles by BTC groups (any journal)              |
#-----------------------------------------------------------------------

# Load package for web scraping & cleaning strings
#install.packages("stringr")
#install.packages("rvest")
#install.packages("tidyverse")

library(tidyverse)
library(rvest)
library(stringr)

################################### FUNCTIONS ###################################
pull_pmids = function(query){
  
  search = URLencode(query)
  
  i = 0
  # Form URL using the term
  url = paste0('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&retmax=5000&retstart=',
                i,
		            '&term=',
		            search,
                '&tool=my_tool&email=my_email@example.com',
		    '&api_key=ae06e6619c472ede6b6d4ac4b5eadecdb209'
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
	
  Sys.sleep(0.5)

  i = 5000
  while (i < N) {
    # Form URL using the term
    url = paste0('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&retmax=5000&retstart=',
                i,
                '&term=',
                search,
                '&tool=my_tool&email=my_email@example.com',
		    '&api_key=ae06e6619c472ede6b6d4ac4b5eadecdb209'
)

    # Query PubMed and save result
    xml = read_xml(url)

    new_ids = xml %>%
      xml_node('IdList')
    new_ids = str_extract_all(new_ids,"\\(?[0-9]+\\)?")[[1]]


    i = i + 5000

    pmid_list = append(pmid_list, new_ids)

    Sys.sleep(0.5)
    #Sys.sleep(runif(1,1,1.2))
  }

  

  return(pmid_list)
  
}
#----------------------------------------------------------------------------------
pull_pmids_samp5 = function(query){
  
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

  print(length(pmid_list))
  print(round(length(pmid_list)*0.05))
  pmid_list = sample(pmid_list, round(length(pmid_list)*0.05), replace=FALSE)
  print(length(pmid_list))

  return(pmid_list)
  
}

################ SCRAPE PMIDs WE ACTUALLY NEED #####################################
# (1) ---------------------------------------------------------------------------------------------
#     All journal articles from top 7 journals (NEJM, JAMA, Lancet, BMJ, Nature, Science, and Cell)

# Author affiliations only reliably show up from 1988 on
years = as.character(1980:2019)
year_queries = paste0('(',years,'/01/01[PDAT] : ',years,'/12/31[PDAT])')

#list of queries to run year by year
queries_sub = read_tsv(file = 'GitHub/healthcare_trends/search_terms_cell_nat_sci.txt')
	
queries = rep(queries_sub$Query, each=length(year_queries))
query_names = rep(queries_sub$Query_Name, each=length(year_queries))

# add  ' AND ' after pulling all PMIDs
queries = paste0(year_queries, ' AND ', queries)
query_names = paste0(query_names, years)

#Run through scraping function to pull out PMIDs
PMIDs = sapply(X = queries[321], FUN = pull_pmids) %>%
	unname()
for (i in 1:length(query_names)) {
	outfile = paste0('../Dropbox/Amitabh/PubMed/PMIDs/QA/PMIDs_all_',
				query_names[i],
				'.csv')
	subset = data.frame(unlist(PMIDs[i]), rep(query_names[i], length(unlist(PMIDs[i]))))
	write_csv(subset, outfile)
}

# (2) --------------------------------------------------------------------------------------------
#     All journal articles by Basic, Translational, Clinical, and Trials groups (any journal)

# Author affiliations only reliably show up from 1988 on
years = as.character(1980:2019)
year_queries = paste0('(',years,'/01/01[PDAT] : ',years,'/12/31[PDAT])')

#list of queries to run year by year
queries_sub = read_tsv(file = 'GitHub/healthcare_trends/search_terms_BTC_notQA_1980.txt')
	
queries = rep(queries_sub$Query, each=length(year_queries))
query_names = rep(queries_sub$Query_Name, each=length(year_queries))

# add  ' AND ' after pulling all PMIDs
queries = paste0(year_queries, ' AND ', queries)
query_names = paste0(query_names, years)

#Run through scraping function to pull out PMIDs
PMIDs = sapply(X = queries, FUN = pull_pmids) %>%
	unname()
for (i in 1:length(query_names)) {
	outfile = paste0('../Dropbox/Amitabh/PubMed/PMIDs/BTC/PMIDs_BTC_',
				query_names[i],
				'.csv')
	subset = data.frame(unlist(PMIDs[i]), rep(query_names[i], length(unlist(PMIDs[i]))))
	write_csv(subset, outfile)
}