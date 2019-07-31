#Import dependencies

import pandas as pd
import numpy as np

#Defining global function to read csv data

def read_data(location):
    #global full_data
    full_data = pd.read_csv(location)
    return full_data

#Specifying file and location

location = "/Users/abhinavmathur/Downloads/titanic/train.csv"

full_data = read_data(location)

# Getting input data dimensions

def data_dims(df):
    global rows, columns

    rows = df.shape[0]
    columns = df.shape[1]

# Defining a function to remove columns having more than a specified percentage of missing values

def missing_removal(df,cut_off):
    #global subset
    missing_count = df.isna().sum()
    missing_count_temp = pd.DataFrame(missing_count)
    missing_count_temp['vars'] = missing_count_temp.index
    missing_count_temp['missing_perc'] = (missing_count_temp[0]/rows)*100
    new_cols = missing_count_temp[missing_count_temp.missing_perc < cut_off]
    new_cols_list = list(new_cols['vars'])
    subset = df[df.columns.intersection(new_cols_list)]
    return subset
