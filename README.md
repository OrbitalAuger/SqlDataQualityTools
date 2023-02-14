# SqlDataQualityTools

Some data quality T-SQL scripts. Mainly for personal use and to take use of when transferring between projects.

## The goal at the moment

My goal is to make collection of procedures so that it can be used in some basic data quality testing.

## Planned functionalities

I have planned to make the following functionalities:

- Generate the necessary tables with parameters 
    - proc_DataChecker_CreateDataModel (WiP)
- Gather test subjects (tables and columns) and insert them into data model
    - proc_DataChecker_AddTests (WiP)
- A config file for all available tests
    - TBD
- A test suite to run and store into data model
    - TBD
- A view to make the long observation tables to wide format and join additional information
    - TBD  
- SQL Server 2008 -> compatible

Also some additional scripts that I have found that have come in handy... (maybe someday)

