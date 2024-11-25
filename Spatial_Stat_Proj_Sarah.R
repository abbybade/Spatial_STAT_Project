library(sp)
library(sf)
library(rstan)
library(rstanarm)
library(INLA)
library(spdep)
library(dplyr)
library(spatialreg)


# Import all datasets
unique_stores <- read.csv("https://raw.githubusercontent.com/sarahvastani/newrepo/refs/heads/main/unique_stores.csv")
Traffic_estimate_Socio_econ <- read.csv("https://raw.githubusercontent.com/sarahvastani/newrepo/refs/heads/main/Traffic_estimate_Socio_econ.csv")
cleaned_Store_Demographic <- read.csv("https://raw.githubusercontent.com/sarahvastani/newrepo/refs/heads/main/cleaned_Store_Demographic_new.csv")
expected_customer_traffic_withProxmity <- read.csv("https://raw.githubusercontent.com/sarahvastani/newrepo/refs/heads/main/expected_customer_traffic_withProxmity.csv")

# Merge the data frames cleaned_Store_Demographic and unique_stores on the 'Store_name' column
merged_data <- merge(cleaned_Store_Demographic, unique_stores, by = "Store_name", all = FALSE)

# Merge the data frames expected_customer_traffic_withProxmity and Traffic_estimate_Socio_econ by the 'storeID' column
merged_data_2 <- merge(expected_customer_traffic_withProxmity, Traffic_estimate_Socio_econ, by = "StoreID", all = FALSE)

# Rename the column StoreID to Store_name
merged_data_2 <- merged_data_2 %>%
  rename(Store_name = StoreID)

# Merge the datasets merged_data and merged_data_2 using the common column "Store_name"
merged_data_combined <- merge(merged_data, merged_data_2, by = "Store_name")

# Aggregate data
aggregated_data <- merged_data_combined %>%
  group_by(Store_name, Latitude, Longitude) %>%
  summarise(
    Utility_Socio = mean(Utility_Socio, na.rm = TRUE),
    Utility_Traffic = mean(Utility_Traffic, na.rm = TRUE),
    Distance = mean(Distance, na.rm = TRUE),
    Estimated_Traffic = mean(Estimated_Traffic, na.rm = TRUE),
    Mean_Utility = mean(Mean_Utility, na.rm = TRUE),
    .groups = "drop"
  )

# Convert to sf object
spatial_data <- st_as_sf(aggregated_data, coords = c("Longitude", "Latitude"), crs = 4326)

# Create spatial neighbors based on the distance between points
coords <- st_coordinates(spatial_data)  
neighbors <- dnearneigh(coords, d1 = 0, d2 = 1)  

# Create a spatial weights matrix from the neighbors
weights <- nb2listw(neighbors, style = "W")


# You can use these as coordinates for the spatial model
#spatial_data$Latitude <- st_coordinates(spatial_data)[,2]
#spatial_data$Longitude <- st_coordinates(spatial_data)[,1]

# Example of standardizing predictors
spatial_data$Estimated_Traffic <- scale(spatial_data$Estimated_Traffic)
spatial_data$Latitude <- scale(spatial_data$Latitude)
spatial_data$Longitude <- scale(spatial_data$Longitude)
spatial_data$Utility_Socio <- scale(spatial_data$Utility_Socio)
spatial_data$Utility_Traffic <- scale(spatial_data$Utility_Traffic)
spatial_data$Distance <- scale(spatial_data$Distance)
spatial_data$Mean_Utility <- scale(spatial_data$Mean_Utility)


# Run a Bayesian spatial model using rstanarm
model_bayesian <- stan_glm(
  Estimated_Traffic ~ Latitude + Longitude + Utility_Socio + Utility_Traffic + Distance + Mean_Utility,
  data = spatial_data,
  family = gaussian(),
  prior = normal(0, 5), 
  chains = 4,           
  cores = parallel::detectCores(), 
  iter = 2000,           
  warmup = 1000          
)

# Check model summary
summary(model_bayesian)

# Posterior samples plot
plot(model_bayesian)

# Extracting the predicted values from the stan_glm model
predicted_values <- predict(model_bayesian, type = "response")

# Actual values (observed) from the data
actual_values <- spatial_data$Estimated_Traffic

# Compute Mean Squared Error (MSE)
mse <- mean((predicted_values - actual_values)^2)

# Compute R-squared
sst <- sum((actual_values - mean(actual_values))^2)
sse <- sum((actual_values - predicted_values)^2)
r_squared <- 1 - (sse / sst)

# Print MSE and R²
cat("MSE: ", mse, "\n")
cat("R²: ", r_squared, "\n")







# Fit a spatial lag model using the spatial weights matrix with adjusted tol.solve and method
model_gaussian <- lagsarlm(
  Estimated_Traffic ~ Latitude + Longitude + Utility_Socio + Utility_Traffic + Distance + Mean_Utility,
  data = spatial_data,
  listw = weights,
  tol.solve = 1e-12,  
  method = "Matrix"   
)

# Check model summary
summary(model_gaussian)

# Extracting the predicted values from the spatial lag model
predicted_values_gaussian <- predict(model_gaussian, newdata = spatial_data, listw = weights)

# Actual values (observed) from the data
actual_values <- spatial_data$Estimated_Traffic

# Compute Mean Squared Error (MSE)
mse_gaussian <- mean((predicted_values_gaussian - actual_values)^2)

# Compute R-squared
sst_gaussian <- sum((actual_values - mean(actual_values))^2)
sse_gaussian <- sum((actual_values - predicted_values_gaussian)^2)
r_squared_gaussian <- 1 - (sse_gaussian / sst_gaussian)

# Print MSE and R²
cat("Gaussian Model MSE: ", mse_gaussian, "\n")
cat("Gaussian Model R²: ", r_squared_gaussian, "\n")








