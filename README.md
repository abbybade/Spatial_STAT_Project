# Spatial_STAT_Project

## Retail Store Traffic Analysis in College Station, TX
Project Overvie: 

This project analyzes retail store traffic patterns in College Station, Texas using demographic data, geospatial analysis, and Bayesian modeling techniques.

File Structure:

Data_Cleaner_Final.Rmd: Main script for data preparation and analysis

Data Sources
TIGER/Line shapefile for census tracts
American Community Survey (ACS) demographic data
Retail store location data
Key Features

## Data Collection and Preparation:
Loads and processes TIGER/Line shapefile data
Fetches ACS demographic data (population, income, education)
Merges shapefile and demographic data
Filters data for College Station area
Data Visualization:
Creates census tract maps
Generates choropleth maps for population density, education level, and median income
Produces an interactive map of retail store locations
Retail Store Data Processing:
Combines multiple CSV files of store locations
Filters unique stores within College Station boundaries
Performs spatial join with census tract data
Traffic Estimation Model:
Generates synthetic traffic data based on socio-economic factors
Fits a Bayesian linear model using brms
Predicts traffic for each store
Evaluates the model using MSE, MAE, and R-squared
Required Libraries
dplyr, sf, ggplot2, tidycensus, tidyr, viridis, units, patchwork, leaflet, brms
Usage
Ensure all required libraries are installed
Set up Census API key
Run the Data_Cleaner_Final.Rmd script
Output
Visualizations of demographic data and store locations
Predicted traffic data for retail stores
Model evaluation metrics
For more detailed information on the analysis process and results, please refer to the comments within the R Markdown file.
