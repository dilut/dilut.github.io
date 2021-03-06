library(scholar)
library(tidyverse)
library(glue)

# escape some special chars, german umlauts, ...
char2html <- function(x){
  dictionary <- data.frame(
    symbol = c("ä","ö","ü","Ä", "Ö", "Ü", "ß"),
    html = c("&auml;","&ouml;", "&uuml;","&Auml;",
             "&Ouml;", "&Uuml;","&szlig;"))
  for(i in 1:dim(dictionary)[1]){
    x <- gsub(dictionary$symbol[i],dictionary$html[i],x)
  }
  x
}

# my google scholar user id from my profile url
# https://scholar.google.com/citations?user=Zho_VdoAAAAJ
dilut <- "Zho_VdoAAAAJ"

# pull from google
html_1 <- get_publications(dilut)

# convert to htlm table - the ugly way ;)
html_2 <- html_1 %>%
  as_tibble %>% arrange(desc(year)) %>%
  mutate(
#    author=str_replace_all(author, " (\\S) ", "\\1 "),
    author=str_replace_all(author, "([A-Z]) ([A-Z]) ", "\\1\\2 "),
    author=str_replace_all(author, ", \\.\\.\\.", " et al."),
    author=str_replace_all(author, "D Ilut", "<b>D Ilut</b>"), # make my name fat
    author=str_replace_all(author, "DC Ilut", "<b>DC Ilut</b>") # make my name fat
  ) %>% split(.$year) %>%
    map(function(x){
      x <- x %>%
        glue_data('<tr><td width="100%">{author} ({year}) <a href="https://scholar.google.com/scholar?oi=bibs&cluster={cid}&btnI=1&hl=en">{title}</a>, {journal}, {number}</td></tr>') %>%
        str_replace_all("(, )+</p>", "</p>") %>%
        char2html()
      x <- c('<table class="publication-table" border="10px solid blue" cellspacing="0" cellpadding="6" rules="", frame=""><tbody>', x, '</tbody></table>')
      return(x);
    }) %>% rev

html_3 <- map2(names(html_2) %>% paste0("<h3>", ., "</h3>"), html_2, c) %>% unlist

html_4 <- c(
  paste0('<p style="text-align: right; margin-top: -40px;"><small>Last updated <i>',
         format(Sys.Date(), format="%B %d, %Y"),
         '&ndash; Pulled automatically from my <a href="https://scholar.google.com/citations?hl=en&user=',dilut,'b8bWNkUAAAAJ">Google Scholar profile</a>. </small></p>'), html_3)

# write the html list to a file
writeLines(html_4, "../_includes/publications.html")

