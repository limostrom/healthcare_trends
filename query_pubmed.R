# Load package for web scraping
library(rvest)

# Define term
##term = 'cardiovascular disease'
term = '("Cardiovascular Diseases"[Mesh] NOT ("Neoplasms"[Mesh] OR "Pregnancy Complications"[Mesh] OR "Psychiatry and Psychology Category"[Mesh])) AND jsubsetaim[text] AND (NIH[gr] OR "research support, n i h, extramural"[Publication Type] OR "research support, n i h, intramural"[Publication Type])'

# Clean term for search. e.g. replace whitespace with '%20' for web search
term_clean = URLencode(term)
print(term_clean)

# Form URL using the term
url = paste0('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pmc&term=',
            term_clean, 
            '&tool=my_tool&email=my_email@example.com'
            )
print(url)


# Query PubMed and save result
xml = read_xml(url)

# View structure of output
print(xml)

# Print Count of Articles
xml %>% 
  xml_node('Count') %>% 
  xml_double()
