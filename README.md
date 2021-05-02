# Vaxilyze

Real time dynamic herd immunity predictor and vaccine prioritizer for 136 countries.

# How does it work
Estimates and Formulae are used on all of the pandemic data available in the world!
The accuracy of the predictions can be off as a lot of estimates are involved.
![Estimates and Formulae](https://github.com/Rajanpandey/HerdImmunitySimulator-N-VaccinePrioritizer/blob/master/img/estimates-and-formulae.PNG?raw=true)


# What is the output
1. An API that gives global or country level data.
![API for 136 countries](https://github.com/Rajanpandey/HerdImmunitySimulator-N-VaccinePrioritizer/blob/master/img/api.PNG?raw=true)

2. A `data.csv` file that is ready to be ingested by any BI tool for data visualization.
![Power BI](https://github.com/Rajanpandey/HerdImmunitySimulator-N-VaccinePrioritizer/blob/master/img/power-bi.PNG?raw=true)

3. Data can also be printed on the CLI itself
![Data printed in the CLI](https://github.com/Rajanpandey/HerdImmunitySimulator-N-VaccinePrioritizer/blob/master/img/printed-data.PNG?raw=true)


# Datasets used
Our World in Data (OWID) is one of the most trusted sources of data. It compiles data from WHO, CDC, and government of respective countries to come up with the most accurate datasets.

1. Worldwide Daily Covid Cases: https://github.com/owid/covid-19-data/blob/master/public/data/jhu/total_cases.csv
2. Worldwide Daily Covid Deaths: https://github.com/owid/covid-19-data/blob/master/public/data/jhu/total_deaths.csv
3. World Population: https://github.com/owid/covid-19-data/blob/master/public/data/jhu/locations.csv
4. Worldwide Daily Vaccination Count: https://github.com/owid/covid-19-data/blob/master/public/data/vaccinations/vaccinations.csv
5. Vaccines Used Country-wise: https://github.com/owid/covid-19-data/blob/master/public/data/vaccinations/locations.csv
6. Worldwide Daily Testing: https://github.com/owid/covid-19-data/blob/master/public/data/testing/covid-testing-all-observations.csv
7. Global Health Security Index: https://www.ghsindex.org/
8. Percentage of Old Population Country-wise: https://data.worldbank.org/indicator/SP.POP.65UP.TO.ZS?end=2019&start=2019&view=map

# Vaccine data

1. Pfizer-BioNTech https://www.cvdvaccine.com/
2. Moderna (mRNA-1273): https://www.who.int/news-room/feature-stories/detail/the-moderna-covid-19-mrna-1273-vaccine-what-you-need-to-know
3. Oxford/AstraZeneca: https://www.who.int/news-room/feature-stories/detail/the-oxford-astrazeneca-covid-19-vaccine-what-you-need-to-know
4. Sputnik V: https://sputnikvaccine.com/about-vaccine/
5. Johnson & Johnson: https://www.jnj.com/johnson-johnson-covid-19-vaccine-authorized-by-u-s-fda-for-emergency-usefirst-single-shot-vaccine-in-fight-against-global-pandemic
6. Sinovac:
7. EpiVacCorona:
8. Sinopharm/Wuhan:
9. Sinopharm/Beijing:
