## Dataset Instruction

The dataset is too large and can't be stored in this repository. Below are the instructions on how to download dataset. 

To download dataset:
1. Go to https://www.kaggle.com/datasets/shengkunwang/housets-dataset?resource=download

2. Download the dataset files in zip format. 

3. Extract the content of the ZIP file on your machine.
   	- you should see folder named archive and inside of it files such as: 
		- CSV/TSV files for housing prices, socioeconomic features, POI and indexes.
   		- Folder called DMV_Multi_Data


## Local Setup
1. Place (copy/paste) the extracted dataset folder named 'archive/' inside the 'data/' folder. (Please do this locally on your machine, do not push to GitHub).

If done correctly you should see the following folder structure:

	data/
	archive/
	HouseTS.csv
	DMV_Multi_Data/

2. Verify the file sizes to ensure download worked: 
	- HouseTS.csv = 284 MB
	- DMV_Multi_Data folder with additional files

3. ** Please never commit raw data ** to GitHub. This repo should only include:
   	- data/README.md (this file with download instructions)
	- no .csv or raw data files

## Note
After completing these steps, you are all set. You can use the data together with our program for exploration, modeling, and analysis.

## Data Description
	- Coverage: ** March 2012 - December 2023 **
	- Size: ** ~890,000+ records **
	- Geography: ** ~6,000 ZIP codes** across **30 U.S metropolitan areas **
	- Features: housing prices, socioeconomic indicators, POIs, sales volumes, indexes

This dataset will be used for trend analysis, regional comparisons, and predictive modeling of the U.S housing market. 


