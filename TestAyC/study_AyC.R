# Study AyC file synthetic data (the first one only)

#### Packages
library(ggplot2)
library(moments)
library(digest) # For hash functions
library(tidyverse)
library(boot)

# Redirect all output to a file
sink("/Users/soupornoghosh/Desktop/IMT 600/Synthetic Data/results_AyC.txt", append=FALSE, split=TRUE)

#### Read dataset
original_data <- read_excel("/Users/soupornoghosh/Desktop/IMT 600/Synthetic Data/Arquitectura_y_Concreto_encoded.xlsx")
colnames(original_data) <- trimws(colnames(original_data))  # strips spaces from column names
synthetic_data <- read.csv("/Users/soupornoghosh/Desktop/IMT 600/Synthetic Data/synthetic_data.csv")
colnames(synthetic_data) <- colnames(original_data)  # fixes the dot-replaced column names in CSV

# Select only numeric analysis columns (drop PII like Yam, E-mail, First Name)
variables <- c(
  "Years of Service",
  #"Communication - It works",
  "CulturaAyC - We add value to clients (internal and external)",
  "CulturaAyC - We genuinely care for people",
  "CulturaAyC - We execute with discipline",
  "CulturaAyC - We promote high-performing teams",
  "CulturaAyC - We innovate, we learn and we adapt",
  "PERFORMANCE",
  "AGE",
  "NPS company"
)

#### Original data
### The author uses SEX and ETHGP as their demographic grouping variables. Our equivalents are GENDER and AREA. 
# Note — since we already subsetted to numeric variables above, we'd actually want to keep GENDER and AREA in the dataset or read them separately. I'll flag this when we get to the subgroup section.
# Do this BEFORE the subsetting lines
gender_counts <- table(original_data$GENDER)
gender_proportions <- prop.table(gender_counts)
print("GENDER Proportions:")
print(gender_proportions)

area_counts <- table(original_data$AREA)
area_proportions <- prop.table(area_counts)
print("AREA Proportions:")
print(area_proportions)

# THEN subset
original_data <- original_data[, variables]
synthetic_data <- synthetic_data[, variables]

#### 1. Overlapped Sample Test
#  Convert rows of data to hash values
row_to_hash <- function(row) {
  digest(paste0(row, collapse = ""), algo = "md5")
}

# converts each row of the dataset to a hash value and returns the hash set
hash_dataset <- function(dataset) {
  sapply(1:nrow(dataset), function(i) row_to_hash(dataset[i, ]))
}

# Hash the two datasets
hashed_original <- hash_dataset(original_data)
hashed_synthetic <- hash_dataset(synthetic_data)

# Compute the intersection
overlapping_hashes <- intersect(hashed_original, hashed_synthetic)

# Calculate the percentage of overlap
overlap_ratio <- length(overlapping_hashes) / length(hashed_original)

# print
print(paste("Overlap Ratio:", overlap_ratio))






#### 2. Constrained Reflection Test (Descriptive table)
# create an empty data table
summary_table <- data.frame(Variable=character(),
                            Min=numeric(), 
                            Max=numeric(),
                            Median=numeric(),
                            Mean=numeric(),
                            SD=numeric(),
                            Cohens_d=numeric(),  
                            stringsAsFactors=FALSE)

# all variables
variables <- c(
  "Years of Service",
  #"Communication - It works",
  "CulturaAyC - We add value to clients (internal and external)",
  "CulturaAyC - We genuinely care for people",
  "CulturaAyC - We execute with discipline",
  "CulturaAyC - We promote high-performing teams",
  "CulturaAyC - We innovate, we learn and we adapt",
  "PERFORMANCE",
  "AGE",
  "NPS company"
)

# loop
for(v in variables) {
  original_data[[v]] <- as.numeric(original_data[[v]])
  synthetic_data[[v]] <- as.numeric(synthetic_data[[v]])
  original_summary <- summary(original_data[[v]])
  synthetic_summary <- summary(synthetic_data[[v]])
  mean_original <- mean(original_data[[v]], na.rm = TRUE)
  mean_synthetic <- mean(synthetic_data[[v]], na.rm = TRUE)
  sd_original <- sd(original_data[[v]], na.rm = TRUE)
  sd_synthetic <- sd(synthetic_data[[v]], na.rm = TRUE)
  n_original <- sum(!is.na(original_data[[v]]))
  n_synthetic <- sum(!is.na(synthetic_data[[v]]))
  pooled_sd <- sqrt(((n_original - 1) * sd_original^2 + (n_synthetic - 1) * sd_synthetic^2) / (n_original + n_synthetic - 2))
  cohens_d_value <- (mean_original - mean_synthetic) / pooled_sd
  
  summary_table <- rbind(summary_table, 
                         data.frame(Variable=paste(v, "original", sep="_"),
                                    Min=original_summary["Min."][[1]], 
                                    Max=original_summary["Max."][[1]],
                                    Median=median(original_data[[v]], na.rm = TRUE),
                                    Mean=mean_original,
                                    SD=sd_original,
                                    Cohens_d=NA),  # Placeholder for Cohens_f in original data
                         data.frame(Variable=paste(v, "synthetic", sep="_"),
                                    Min=synthetic_summary["Min."][[1]], 
                                    Max=synthetic_summary["Max."][[1]],
                                    Median=median(synthetic_data[[v]], na.rm = TRUE),
                                    Mean=mean_synthetic,
                                    SD=sd_synthetic,
                                    Cohens_d=cohens_d_value))
}

# check table
print(summary_table)







#### 3. Variable Correlation Test
variables <- c(
  "Years of Service",
  #"Communication - It works",
  "CulturaAyC - We add value to clients (internal and external)",
  "CulturaAyC - We genuinely care for people",
  "CulturaAyC - We execute with discipline",
  "CulturaAyC - We promote high-performing teams",
  "CulturaAyC - We innovate, we learn and we adapt",
  "PERFORMANCE",
  "AGE",
  "NPS company"
)

# The mutate(across(everything(), as.numeric)) part does the same type conversion for all columns at once — cleaner than doing it column by column in a loop.
original_data_selected <- original_data[, variables] |> 
  mutate(across(everything(), as.numeric))

synthetic_data_selected <- synthetic_data[, variables] |>
  mutate(across(everything(), as.numeric))

cor_matrix_original <- cor(original_data_selected, use="complete.obs", method="pearson")
cor_matrix_synthetic <- cor(synthetic_data_selected, use="complete.obs", method="pearson")

cor_difference <- cor_matrix_original - cor_matrix_synthetic

cor_matrix_original
cor_matrix_synthetic

# mean difference cor
mean_difference <- mean(abs(cor_difference), na.rm = TRUE)

# print
print(mean_difference)

sd_difference <- sd(abs(cor_difference), na.rm = TRUE)
min_difference <- min(abs(cor_difference), na.rm = TRUE)
max_difference <- max(abs(cor_difference), na.rm = TRUE)

print(paste("Standard Deviation:", sd_difference))
print(paste("Minimum Difference:", min_difference))
print(paste("Maximum Difference:", max_difference))


absolute_cor_difference <- abs(cor_difference)

absolute_cor_difference_vector <- data.frame(absolute = as.vector(absolute_cor_difference))

ggplot(data = absolute_cor_difference_vector, aes(x = absolute)) +
  geom_histogram(alpha = .50) +
  xlab("Absolute Difference in Correlation (r) for Synthetic and Observed") +
  theme_classic() +
  theme(text = element_text(size = 15),
        legend.position = "none") +
  ylab("N") +
  scale_x_continuous(labels = scales::number_format(accuracy = 0.1))

# Add this to save the plot:
ggsave("/Users/soupornoghosh/Desktop/IMT 600/Synthetic Data/plot_correlation_difference.png", 
       width=8, height=5, dpi=300)


#### Regression
original_data$type <- 'Original'
synthetic_data$type <- 'Synthetic'
combined_data <- rbind(original_data, synthetic_data)

## Regression result
# Higher order distributions of 3 or more columns are not included.
# Very high order similarity may have an adverse effect on the synthetic data. 

results_df <- data.frame(
Variable = character(),
Dataset = character(),
Beta = numeric(),
P_Value = numeric(),
R_Squared = numeric(),
stringsAsFactors = FALSE
)

# PERFORMANCE is our criterion (like CRFIN). Use "Years of Service" or culture items as predictors (like G, V, N...)

ggplot(combined_data, aes(x=`Years of Service`, y=PERFORMANCE, color=type)) +
  geom_point(alpha=0.5) +
  geom_smooth(method="lm", se=FALSE, aes(group=type)) +
  theme_minimal() +
  labs(title="Scatter Plot of PERFORMANCE vs Years of Service",
       x="Years of Service", y="PERFORMANCE") +
  scale_color_manual(values=c("Original"="blue", "Synthetic"="red"))

# Add this to save the plot:
ggsave("/Users/soupornoghosh/Desktop/IMT 600/Synthetic Data/plot_regression_scatter.png", 
       width=8, height=5, dpi=300)

variables <- c(
  "Years of Service",
  #"Communication - It works",
  "CulturaAyC - We add value to clients (internal and external)",
  "CulturaAyC - We genuinely care for people",
  "CulturaAyC - We execute with discipline",
  "CulturaAyC - We promote high-performing teams",
  "CulturaAyC - We innovate, we learn and we adapt",
  "AGE",
  "NPS company"
)

for (var in variables) {
# model_original <- lm(paste0("CRFIN ~ ", var), data=original_data)
  model_original <- lm(as.formula(paste0("PERFORMANCE ~ `", var, "`")), data=original_data)
  summary_model_original <- summary(model_original)
  
# model_synthetic <- lm(paste0("CRFIN ~ ", var), data=synthetic_data)
  model_synthetic <- lm(as.formula(paste0("PERFORMANCE ~ `", var, "`")), data=synthetic_data)
  summary_model_synthetic <- summary(model_synthetic)
  
  results_df <- rbind(results_df, data.frame(
    Variable = var,
    Dataset = "Original",
    Beta = summary_model_original$coefficients[2, 1],
    P_Value = summary_model_original$coefficients[2, 4],
    R_Squared = summary_model_original$r.squared
  ))
  
  results_df <- rbind(results_df, data.frame(
    Variable = var,
    Dataset = "Synthetic",
    Beta = summary_model_synthetic$coefficients[2, 1],
    P_Value = summary_model_synthetic$coefficients[2, 4],
    R_Squared = summary_model_synthetic$r.squared
  ))
}

delta_results <- data.frame(
  Variable = rep(variables, each = 1),
  Delta_Beta = numeric(length(variables)),
  Delta_R_Squared = numeric(length(variables)),
  stringsAsFactors = FALSE
)

for (var in variables) {
  original_beta <- results_df$Beta[results_df$Variable == var & results_df$Dataset == "Original"]
  synthetic_beta <- results_df$Beta[results_df$Variable == var & results_df$Dataset == "Synthetic"]
  original_r_squared <- results_df$R_Squared[results_df$Variable == var & results_df$Dataset == "Original"]
  synthetic_r_squared <- results_df$R_Squared[results_df$Variable == var & results_df$Dataset == "Synthetic"]
  
  delta_results$Delta_Beta[delta_results$Variable == var] <- synthetic_beta - original_beta
  delta_results$Delta_R_Squared[delta_results$Variable == var] <- synthetic_r_squared - original_r_squared
}

results_df <- merge(results_df, delta_results, by = "Variable")

results_df$P_Value <- ifelse(results_df$P_Value < 0.001, "< .001",
                             ifelse(results_df$P_Value < 0.01, "< .01",
                                    ifelse(results_df$P_Value < 0.05, "< .05", ">= .05")))

print(results_df)





#### 4. Distribution Kurtosis and Skewness Test
summary_table <- data.frame(Variable=character(),
                            Kurtosis=numeric(),
                            Skewness=numeric(),
                            stringsAsFactors=FALSE)

variables <- c(
  "Years of Service",
  #"Communication - It works",
  "CulturaAyC - We add value to clients (internal and external)",
  "CulturaAyC - We genuinely care for people",
  "CulturaAyC - We execute with discipline",
  "CulturaAyC - We promote high-performing teams",
  "CulturaAyC - We innovate, we learn and we adapt",
  "AGE",
  "NPS company"
)

for(v in variables) {
  kurtosis_original <- kurtosis(original_data[[v]], na.rm = TRUE)
  kurtosis_synthetic <- kurtosis(synthetic_data[[v]], na.rm = TRUE)
  skewness_original <- skewness(original_data[[v]], na.rm = TRUE)
  skewness_synthetic <- skewness(synthetic_data[[v]], na.rm = TRUE)
  
  summary_table <- rbind(summary_table, 
                         data.frame(Variable=paste(v, "original", sep="_"),
                                    Kurtosis=kurtosis_original,
                                    Skewness=skewness_original),
                         data.frame(Variable=paste(v, "synthetic", sep="_"),
                                    Kurtosis=kurtosis_synthetic,
                                    Skewness=skewness_synthetic))
}

print(summary_table)




# Re-read full data for subgroup analysis
original_full <- read_excel("/Users/soupornoghosh/Desktop/IMT 600/Synthetic Data/Arquitectura_y_Concreto_encoded.xlsx")
colnames(original_full) <- trimws(colnames(original_full))
synthetic_full <- read.csv("/Users/soupornoghosh/Desktop/IMT 600/Synthetic Data/synthetic_data.csv")
colnames(synthetic_full) <- colnames(original_full)


# Check what values GENDER actually has
print(table(original_full$GENDER))

# Define the function FIRST, with your variables
calculate_stats_general <- function(data, filter_column, filter_values, data_label) {
  variables <- c(
    "Years of Service",
    #"Communication - It works",
    "CulturaAyC - We add value to clients (internal and external)",
    "CulturaAyC - We genuinely care for people",
    "CulturaAyC - We execute with discipline",
    "CulturaAyC - We promote high-performing teams",
    "CulturaAyC - We innovate, we learn and we adapt",
    "PERFORMANCE",
    "AGE",
    "NPS company"
  )

  stats_list <- lapply(filter_values, function(value) {
    filtered_data <- data[data[[filter_column]] == value, ]
    summary_table <- data.frame()
    for(v in variables) {
      variable_data <- as.numeric(filtered_data[[v]])
      summary_table <- rbind(summary_table,
                             data.frame(DataType=data_label,
                                        Group=value,
                                        Variable=v,
                                        Min=min(variable_data, na.rm=TRUE),
                                        Max=max(variable_data, na.rm=TRUE),
                                        Median=median(variable_data, na.rm=TRUE),
                                        Mean=mean(variable_data, na.rm=TRUE),
                                        SD=sd(variable_data, na.rm=TRUE)))
    }
    return(summary_table)
  })
  do.call(rbind, stats_list)
}

# Cohen's d function
cohens_d <- function(mean1, mean2, sd1, sd2, n) {
  pooled_sd <- sqrt(((n-1)*sd1^2 + (n-1)*sd2^2) / (n+n-2))
  d <- (mean1 - mean2) / pooled_sd
  return(d)
}

calculate_cohens_d_within_type <- function(data, n) {
  results <- data.frame(DataType = character(),
                        Variable = character(),
                        Cohens_d = numeric(),
                        stringsAsFactors = FALSE)
  for (data_type in unique(data$DataType)) {
    for (variable in unique(data$Variable)) {
      sub_data <- data[data$DataType == data_type & data$Variable == variable,]
      if(nrow(sub_data) == 2) {
        d_value <- cohens_d(sub_data$Mean[1], sub_data$Mean[2],
                            sub_data$SD[1], sub_data$SD[2], n)
        results <- rbind(results, data.frame(DataType = data_type,
                                             Variable = variable,
                                             Cohens_d = d_value))
      }
    }
  }
  return(results)
}

# GENDER subgroup (equivalent of SEX in the paper)
stats_original_gender <- calculate_stats_general(original_full, "GENDER", c("Male", "Female"), "Original")
stats_synthetic_gender <- calculate_stats_general(synthetic_full, "GENDER", c("Male", "Female"), "Synthetic")

combined_stats_gender <- rbind(stats_original_gender, stats_synthetic_gender)
print(combined_stats_gender)

# n per group — check your actual counts first
n_gender <- min(table(original_full$GENDER))

cohens_d_gender <- calculate_cohens_d_within_type(combined_stats_gender, n_gender)
print(cohens_d_gender)

# AREA subgroup (equivalent of ETHGP in the paper)
stats_original_area <- calculate_stats_general(original_full, "AREA", unique(original_full$AREA), "Original")
stats_synthetic_area <- calculate_stats_general(synthetic_full, "AREA", unique(original_full$AREA), "Synthetic")

combined_stats_area <- rbind(stats_original_area, stats_synthetic_area)
print(combined_stats_area)

n_area <- min(table(original_full$AREA))

cohens_d_area <- calculate_cohens_d_within_type(combined_stats_area, n_area)
print(cohens_d_area)

# Close the sink
sink()