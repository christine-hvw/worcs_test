# In this file, write the R-code necessary to load your original data file
# (e.g., an SPSS, Excel, or SAS-file), and convert it to a data.frame. Then,
# use the function open_data(your_data_frame) or closed_data(your_data_frame)
# to store the data.

library(worcs)
library(here)
library(dplyr)
library(tidygraph)
library(readxl)

# Read data 1
# -> incidence matrix with authors as rows, publications as cols
inc_mat <- readRDS(here("data-raw", "socpub_bipart.RDS")) 

# transform: inc. matrix x transponse(inc. matrix) = adj. matrix
adj_mat <- inc_mat %*% t(inc_mat) 

net_noatt <- as_tbl_graph(adj_mat, directed = FALSE)

# Read data 2
# -> author attributes
auth_att <- as.data.frame(read_excel(here("data", "auth_attributes.xlsx")))

# edit attribute data
auth_att %<>%
  mutate(socium = if_else(is.na(dep_cat), 0, 1)) %>% # indicator for socium member
  mutate(dep_cat = case_when(dep_cat == 1 ~ "Theory", # label departments
                             dep_cat == 2 ~ "Polit. Economy",
                             dep_cat == 3 ~ "Ineq. in Welfare Societies",
                             dep_cat == 4 ~ "Life Course",
                             dep_cat == 5 ~ "Health")) %>% 
  mutate(al = if_else(socium==1 & is.na(al), 0, al),
         agl = if_else(socium==1 & is.na(agl), 0, agl)) %>% 
  rename("Head Department" = "al", "Head Working Grp." = "agl")

# Join data sets
net <- net_noatt %>% 
  activate(nodes) %>% 
  left_join(auth_att)

# Subset of Socium members
net_soc <- net %>% 
  filter(socium == 1)

# Save processed data
saveRDS(net, here("data-processed", "net.rds"))
saveRDS(net_soc, here("data-processed", "net_soc.rds"))
