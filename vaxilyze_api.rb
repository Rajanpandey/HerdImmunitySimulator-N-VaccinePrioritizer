#!/usr/bin/ruby

require 'open-uri'
require 'csv'
require 'json'

$masterHash = {}

EFFICACY = {
	'Covaxin' => [81, 81],
	'Oxford/AstraZeneca' => [76, 82.4],
	'Pfizer/BioNTech' => [60, 95],
	'Moderna' => [80, 94.5],
	'Sputnik V' => [80, 91.6],
	'EpiVacCorona' => [100, 100],
	'Sinopharm/Beijing' => [62, 79.34],
	'Sinopharm/Wuhan' => [62, 79.34],
	'Sinovac' => [50.38, 50.38],
	'Johnson&Johnson' => [65, 65]
}

VACCINE_SHOT_GAP = {
	'Covaxin' => ['2 doses', '4 weeks apart'],
	'Oxford/AstraZeneca' => ['2 doses', '8 weeks apart', 'can be extended to 12 weeks'],
	'Pfizer/BioNTech' => ['2 doses', '3 weeks apart'],
	'Moderna' => ['2 doses', '4 weeks apart', 'can be extended to 6 weeks'],
	'Sputnik V' => ['2 doses', '3 weeks apart'],
	'EpiVacCorona' => ['2 doses', '3 weeks apart'],
	'Sinopharm/Beijing' => ['2 doses', '3 weeks apart'],
	'Sinopharm/Wuhan' => ['2 doses', '3 weeks apart'],
	'Sinovac' =>  ['2 doses', '2 weeks apart'],
	'Johnson&Johnson' => ['1 dose']
}

UNREPORTED_CASES_MULTIPLIER = {
	'India' =>  50,
	'United States' =>  10,
	'Belgium' =>  10,
	'Brazil' =>  10,
}

DEFAULT_UNREPORTED_CASES_MULTIPLIER = 10
MONTHLY_LIMIT_OF_NATURAL_IMMUNITY = 6
PERCENTAGE_OF_PEOPLE_DEV_NATURAL_IMMNITY = 95 / 100.to_f

def download_dataset
	IO.copy_stream(URI.open("https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/testing/covid-testing-all-observations.csv"), 'test_count.csv')
	IO.copy_stream(URI.open("https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/vaccinations/vaccinations.csv"), 'vaccine_count.csv')
	IO.copy_stream(URI.open("https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/vaccinations/locations.csv"), 'vaccine_name.csv')
	IO.copy_stream(URI.open("https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/jhu/total_cases.csv"), 'confirmed_count.csv')
	IO.copy_stream(URI.open("https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/jhu/total_deaths.csv"), 'death_count.csv')
	IO.copy_stream(URI.open("https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/jhu/locations.csv"), 'population_count.csv')
end

def load_dataset
	$TEST_COUNT = CSV.read("test_count.csv").freeze
	$VACCINE_NAME = CSV.read("vaccine_name.csv").freeze
	$VACCINE_COUNT = CSV.read("vaccine_count.csv").freeze
	$CONFIRMED_COUNT = CSV.read("confirmed_count.csv").freeze
	$DEATH_COUNT = CSV.read("death_count.csv").freeze
	$POPULATION_COUNT = CSV.read("population_count.csv").freeze
	$HEALTH_CARE_INDEX = CSV.read("health_care_index.csv").freeze
	$PERCENT_OF_OLD_PEOPLE = CSV.read("percentage_of_old_people.csv").freeze
end

def add_vaccine_and_efficacy_data
	$VACCINE_NAME.each_with_index do |row, idx|
		next if idx == 0
		country = row[0]
		$masterHash[country] = {}
		$masterHash[country]['vaccines'] = {}
		noOfVaccines = row[2].split(', ').count
		avgSemiEfficacy = 0
		avgFullEfficacy = 0
		row[2].gsub('/ ', '/').split(', ').each do |vaccine|
			$masterHash[country]['vaccines'][vaccine] = EFFICACY[vaccine]
			avgSemiEfficacy += EFFICACY[vaccine][0]
			avgFullEfficacy += EFFICACY[vaccine][1]
		end
		avgSemiEfficacy /=  noOfVaccines
		avgFullEfficacy /=  noOfVaccines
		$masterHash[country]['avg_half_dose_efficacy'] = avgSemiEfficacy
		$masterHash[country]['avg_full_dose_efficacy'] = avgFullEfficacy
	end
end

def add_population_data
	$POPULATION_COUNT.each_with_index do |row, idx|
		next if idx == 0
		country = row[1]
		$masterHash[country]['population'] = row[4].to_i if $masterHash[country]
	end
end

def add_vaccine_data
	$VACCINE_COUNT.each_with_index do |row, idx|
		next if idx == 0
		country = row[0]
		if $masterHash[country]
			total_vaccinations = [row[3].to_i, $masterHash[country]['total_vaccinations'] ? $masterHash[country]['total_vaccinations'] : 1].max
			people_semi_vaccinated = [row[4].to_i, $masterHash[country]['people_semi_vaccinated'] ? $masterHash[country]['people_semi_vaccinated'] : 1].max
			people_fully_vaccinated = [row[5].to_i, $masterHash[country]['people_fully_vaccinated'] ? $masterHash[country]['people_fully_vaccinated'] : 1].max

			people_semi_vaccinated = (total_vaccinations * people_semi_vaccinated) / (people_semi_vaccinated + people_fully_vaccinated)
			people_fully_vaccinated = (total_vaccinations * people_fully_vaccinated) / (people_semi_vaccinated + people_fully_vaccinated)
			$masterHash[country]['total_vaccinations'] = total_vaccinations
			$masterHash[country]['people_semi_vaccinated'] = people_semi_vaccinated
			$masterHash[country]['people_fully_vaccinated'] = people_fully_vaccinated
		end
	end
end

def add_covid_data
	$CONFIRMED_COUNT[0].each_with_index do |country, idx|
		if $masterHash[country]
			$masterHash[country]['total_confirmed_count'] = $CONFIRMED_COUNT[$CONFIRMED_COUNT.size - 1][idx].to_i
			$masterHash[country]["covid_count_#{MONTHLY_LIMIT_OF_NATURAL_IMMUNITY}_months_ago"] = $CONFIRMED_COUNT[$CONFIRMED_COUNT.size - 1 - (MONTHLY_LIMIT_OF_NATURAL_IMMUNITY * 30)][idx].to_i

			r0Value = 0
			for i in (0..52)
				break if !$CONFIRMED_COUNT[$CONFIRMED_COUNT.size - 1 - ((i + 1) * 7)][idx]
				r0Value += (($CONFIRMED_COUNT[$CONFIRMED_COUNT.size - 1 - (i * 7)][idx].to_f - $CONFIRMED_COUNT[$CONFIRMED_COUNT.size - 1 - ((i + 1) * 7)][idx].to_f) / $CONFIRMED_COUNT[$CONFIRMED_COUNT.size - 1 - ((i + 1) * 7)][idx].to_f)
			end
			r0Value = (r0Value / 7).round(4)

			$masterHash[country]['historical_r0_value'] = r0Value
			$masterHash[country]['current_HIT'] = ((r0Value - 1) / r0Value * 100).round(4)
		end
	end

	$DEATH_COUNT[0].each_with_index do |country, idx|
		if $masterHash[country]
			$masterHash[country]['total_death_count'] = $DEATH_COUNT[$DEATH_COUNT.size - 1][idx].to_i
			$masterHash[country]["death_count_#{MONTHLY_LIMIT_OF_NATURAL_IMMUNITY - 1}_months_ago"] = $DEATH_COUNT[$DEATH_COUNT.size - 1 - ((MONTHLY_LIMIT_OF_NATURAL_IMMUNITY - 1) * 30)][idx].to_i
		end
	end
end

def add_health_and_age_index_data
	minHealthIndex = 16.2
	maxHealthIndex = 83.5
	$HEALTH_CARE_INDEX.each_with_index do |row, idx|
		next if idx == 0
		country = row[0]
		healthIndexValue = row[1].to_f
		normalizedHealthIndex = (healthIndexValue - minHealthIndex) / (maxHealthIndex - minHealthIndex).to_f.round(4)
		$masterHash[country]['health_care_index'] = healthIndexValue if $masterHash[country]
		$masterHash[country]['normalized_health_care_index'] = normalizedHealthIndex.round(4) if $masterHash[country]
	end
	$masterHash.each do |country, data|
		$masterHash[country]['health_care_index'] = 0 if $masterHash[country]['health_care_index'].nil?
		$masterHash[country]['normalized_health_care_index'] = 0 if $masterHash[country]['normalized_health_care_index'].nil?
	end

	minOldPeoplePercent = 1.523163117
	maxOldPeoplePercent = 28.00204928
	$PERCENT_OF_OLD_PEOPLE.each_with_index do |row, idx|
		next if idx == 0
		country = row[0]
		percent_of_old_people = row[2].to_f
		$masterHash[country]['percent_of_old_people'] = percent_of_old_people.round(4) if $masterHash[country]
		$masterHash[country]['normalized_percent_of_old_people'] = ((percent_of_old_people - minOldPeoplePercent) / (maxOldPeoplePercent - minOldPeoplePercent).to_f).round(4) if $masterHash[country]
	end
	$masterHash.each do |country, data|
		$masterHash[country]['percent_of_old_people'] = 0 if $masterHash[country]['percent_of_old_people'].nil?
		$masterHash[country]['normalized_percent_of_old_people'] = 0 if $masterHash[country]['normalized_percent_of_old_people'].nil?
	end
end

def calculate_herd_immunity
	$masterHash.each do |country, data|
		$masterHash.delete(country) and next if !data['population']
		naturalImmunity = (($masterHash[country]["total_confirmed_count"] - $masterHash[country]["total_death_count"]) - ($masterHash[country]["covid_count_#{MONTHLY_LIMIT_OF_NATURAL_IMMUNITY}_months_ago"] - $masterHash[country]["death_count_#{MONTHLY_LIMIT_OF_NATURAL_IMMUNITY - 1}_months_ago"])) * (UNREPORTED_CASES_MULTIPLIER[country] ? UNREPORTED_CASES_MULTIPLIER[country] : DEFAULT_UNREPORTED_CASES_MULTIPLIER) * PERCENTAGE_OF_PEOPLE_DEV_NATURAL_IMMNITY
		vaccinatedImmunity = (data['people_semi_vaccinated'] * data['avg_half_dose_efficacy'] / 100) + (data['people_fully_vaccinated'] * data['avg_full_dose_efficacy'] / 100)
		$masterHash[country]["natural_immunity"] = naturalImmunity
		$masterHash[country]["vaccinated_immunity"] = vaccinatedImmunity
		$masterHash[country]['herd_immunity_achieved'] = (((vaccinatedImmunity + naturalImmunity) * 100).to_f / data['population']).to_f.round(4)
	end
end

def calculate_vaccines_required
	totalVaccinesRequiredInWorld = 0
	maxVaccinePriority = 0.0

	$masterHash.each do |country, data|
		$masterHash[country]['total_vaccines_required'] = (data['current_HIT'] - data['herd_immunity_achieved']) > 0 ? ((data['current_HIT'] - data['herd_immunity_achieved']) * data['population'] / 100).round : 0
		totalVaccinesRequiredInWorld += $masterHash[country]['total_vaccines_required']
		normalizedVaccineRequired = (data['total_vaccines_required'] / totalVaccinesRequiredInWorld.to_f).round(4)
		$masterHash[country]['vaccine_priority'] = data['total_vaccines_required'] > 0 ? (((((1 - data['normalized_health_care_index']) ? (1 - data['normalized_health_care_index']) : normalizedVaccineRequired) + normalizedVaccineRequired + ($masterHash[country]['normalized_percent_of_old_people'] ? $masterHash[country]['normalized_percent_of_old_people'] : normalizedVaccineRequired)) / 3).to_f.round(4)) : 0.0
		maxVaccinePriority = [maxVaccinePriority, $masterHash[country]['vaccine_priority']].max
	end

	$masterHash.each do |country, data|
		$masterHash[country]['vaccine_priority'] = ($masterHash[country]['vaccine_priority'] / maxVaccinePriority).round(4) if $masterHash[country]
		$masterHash[country]['vaccines_required_priority_wise'] = ($masterHash[country]['vaccine_priority'] * data['total_vaccines_required']).round
	end
end

def separate_number_with_commas(number)
	number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
end

def fill_cell(data)
    data.is_a?(Integer) ? separate_number_with_commas(data).to_s.ljust(16) : data.to_s.ljust(16)
end

def table
    table_string = '_' * 238
    table_string += "\n| #{'Country'.ljust(13)} | #{'Covid Cases'.ljust(16)} | #{'Vaccinated'.ljust(16)} | #{'Population'.ljust(16)} | #{'R0'.ljust(16)} | #{'HIT'.ljust(17)} |  #{'Curr. Herd Immun'.ljust(16)} | #{'Total Vacc. Req.'.ljust(16)} | #{'Norm. Health Idx'.ljust(16)} | #{'% of Old People'.ljust(16)} | #{'Vaccine Priority'.ljust(16)} | #{'Vaccine Req. Priority-wise'.ljust(16)} |"
    table_string += "\n|#{'-' * 236}|\n"

    $masterHash.sort_by {|country, data| data['vaccine_priority']}.reverse.to_h.each do |country, data|
	    table_string += "| #{fill_cell(country)[0..12]} "
	    table_string += "| #{fill_cell(data['total_confirmed_count'])} "
	    table_string += "| #{fill_cell(data['total_vaccinations'])} "
	    table_string += "| #{fill_cell(data['population'])} "
	    table_string += "| #{fill_cell(data['historical_r0_value'])} "
	    table_string += "| #{fill_cell(data['current_HIT'])}% "
	    table_string += "| #{fill_cell(data['herd_immunity_achieved'])}% "
	    table_string += "| #{fill_cell(data['total_vaccines_required'])} "
	    table_string += "| #{fill_cell(data['normalized_health_care_index'])} "
	    table_string += "| #{fill_cell(data['percent_of_old_people'])}% "
	    table_string += "| #{fill_cell(data['vaccine_priority'])} "
	    table_string += "| #{fill_cell(data['vaccines_required_priority_wise'])}           |\n"
    end

    table_string += '_' * 238
end

def prepare_and_export_csv
	headers = ['country'] + $masterHash['United States'].keys
	CSV.open("data.csv", "w") do |csv|
	    csv << headers
	    $masterHash.each do |country, data|
	    	csv << [country] + data.values
	    end
	end
end

download_dataset
load_dataset
add_vaccine_and_efficacy_data
add_population_data
add_vaccine_data
add_covid_data
add_health_and_age_index_data
calculate_herd_immunity
calculate_vaccines_required
# puts table
# prepare_and_export_csv
puts JSON.pretty_generate(ARGV.size == 1 ? $masterHash.slice(ARGV[0]) : $masterHash)
