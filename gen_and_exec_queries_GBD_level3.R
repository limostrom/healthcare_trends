# Load package for web scraping
library(tidyverse)
library(rvest)

api_parse = function(query){
  
  search = URLencode(query)
  
  # Form URL using the term
  url = paste0('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=',
                search,
                '&tool=my_tool&email=my_email@example.com',
		    '&api_key=ae06e6619c472ede6b6d4ac4b5eadecdb209'
  )

  # Query PubMed and save result
  xml = read_xml(url)
  
  # Print Count of Articles
  pub_count = xml %>% 
    xml_node('Count') %>% 
    xml_double() 

  Sys.sleep(runif(1,0.4,0.6))
  
  return(pub_count)
  
}

## --------------------------------------------------------------------
start_year = 1980

# set to econ or diseases:
group_term = "GBDlev3"

data = read_csv(file = "C:/Users/lmostrom/Documents/Amitabh/IHME_GBD_highSDI_lev3/IHME-GBD_2017_DATA-2619eabb-1.csv")
queries = levels(as.factor(data$cause_name))
	query_names = queries
queries = paste0("(", '"', queries, '"', "[All fields])")

if (group_term == "GBDlev3") {
	queries = paste0(queries,
				' AND ("N Engl J Med"[Journal] OR "Lancet"[Journal] OR "Lancet Respir Med"[Journal] OR "Lancet Public Health"[Journal] OR "Lancet Psychiatry"[Journal] OR "Lancet Planet Health"[Journal] OR "Lancet Oncol"[Journal] OR "Lancet Neurol"[Journal] OR "Lancet Infect Dis"[Journal] OR "Lancet Haematol"[Journal] OR "Lancet HIV"[Journal] OR "Lancet Glob Health"[Journal] OR "Lancet Gastroenterol Hepatol"[Journal] OR "Lancet Diabetes Endocrinol"[Journal] OR "Lancet Child Adolesc Health"[Journal] OR "Chem Rev"[Journal] OR "JAMA"[Journal] OR "J Am Med Assoc"[Journal] OR "Nat Rev Cancer"[Journal] OR "Nat Rev Genet"[Journal] OR "Nat Rev Immunol"[Journal] OR "Nat Rev Mol Cell Biol"[Journal] OR "Nature"[Journal] OR "Science"[Journal] OR "Chem Soc Rev"[Journal] OR "Nat Mater"[Journal] OR "Cell"[Journal])')	
}
if (group_term == "GBDlev3_clintr") {
	queries = paste0(queries,
				' AND ("Clinical Trial, Phase II" [Publication Type] OR "Clinical Trial, Phase III" [Publication Type])')	
}

if (start_year == 1980) {
	names_ext = c("_nih", "_notnih")
		names_ext = rep(names_ext, length(queries))
	queries_ext = c(' AND (NIH[gr] OR "research support, n i h, extramural"[Publication Type] OR "research support, n i h, intramural"[Publication Type])',
				' NOT (NIH[gr] OR "research support, n i h, extramural"[Publication Type] OR "research support, n i h, intramural"[Publication Type])')
		queries_ext = rep(queries_ext, length(queries))
	queries = rep(queries, each=2)
		queries = paste0(queries, queries_ext)
	query_names = rep(query_names, each=2)
		query_names = paste0(query_names, names_ext)		
}
if (start_year == 2005) {
	names_ext = c("_nih", "_pub", "_priv")
		names_ext = rep(names_ext, length(queries))
	queries_ext1 = c('',
				' AND ("Research Support, American Recovery and Reinvestment Act" [Publication Type] OR "Research Support, U.S. Gov\'t, Non-P.H.S." [Publication Type] OR "Research Support, U.S. Gov\'t, P.H.S." [Publication Type])',
				' NOT ("Research Support, American Recovery and Reinvestment Act" [Publication Type] OR "Research Support, U.S. Gov\'t, Non-P.H.S." [Publication Type] OR "Research Support, U.S. Gov\'t, P.H.S." [Publication Type])')
		queries_ext1 = rep(queries_ext1, length(queries))
	queries_ext2 = c(' AND (NIH[gr] OR "research support, n i h, extramural"[Publication Type] OR "research support, n i h, intramural"[Publication Type])',
				' NOT (NIH[gr] OR "research support, n i h, extramural"[Publication Type] OR "research support, n i h, intramural"[Publication Type])',
				' NOT (NIH[gr] OR "research support, n i h, extramural"[Publication Type] OR "research support, n i h, intramural"[Publication Type])')
		queries_ext2 = rep(queries_ext2, length(queries))
	
	queries = rep(queries, each=3)
		queries = paste0(queries, queries_ext1, queries_ext2)
	query_names = rep(query_names, each=3)
		query_names = paste0(query_names, names_ext)
}

years = as.character(start_year:2018)
year_queries = paste0('(',years,'/01/01[PDAT] : ',years,'/12/31[PDAT])')

queries = rep(queries, each=length(year_queries))
query_names = rep(query_names, each=length(year_queries))

Q = data.frame(Query = queries, Query_Name = query_names)

Q$Query = paste0(Q$Query,' AND ',year_queries)

pub_counts = sapply(X = Q$Query, FUN = api_parse)

pub_counts = unname(pub_counts)

data = data.frame(
  year = years,
  query_name = Q$Query_Name,
  pub_count = pub_counts
)

outfile = paste0('Amitabh/PubMed_Search_Results_',
				group_term,
				as.character(start_year),
				'.csv')

write_csv(data, path = outfile)


