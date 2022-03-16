library(stringr)
library(dplyr)

raw_data <- '<span style="display:inline-block; font-size:10pt;">
		<br />
		<strong>1006 LLC DBA Taco Mac (Food Service Inspections)</strong><br>
		1006 N HIGHLAND AVE NE 
ATLANTA, GA 30306<br>
		View inspections:<br />
		<a href="history.cfm?id=2816367&inspID=55999566&county=Fulton">May 10, 2019 Score: 82, Grade: B</a> <br />
		<a href="history.cfm?id=2816367&inspID=56530102&county=Fulton">August 7, 2019 Score: 96, Grade: A</a> <br />
		<a href="history.cfm?id=2816367&inspID=56757059&county=Fulton">March 4, 2020 Score: 93, Grade: A</a> <br />
		<a href="history.cfm?id=2816367&inspID=56766979&county=Fulton">August 21, 2020 Score: 92, Grade: A</a> <br />
		<br />
		<strong>102 Pizza (Food Service Inspections)</strong><br>
		1 STATE FARM DR 
ATLANTA, GA 30303<br>
		View inspections:<br />
		<a href="history.cfm?id=9483807&inspID=56541355&county=Fulton">November 6, 2019 Score: 100, Grade: A</a> <br />
		<a href="history.cfm?id=9483807&inspID=56757930&county=Fulton">March 11, 2020 Score: 100, Grade: A</a> <br />
		<a href="history.cfm?id=9483807&inspID=57240006&county=Fulton">December 3, 2020 Score: 100, Grade: A</a> <br />
		<a href="history.cfm?id=9483807&inspID=57275931&county=Fulton">October 6, 2021 Score: 100, Grade: A</a> <br />
		<a href="history.cfm?id=9483807&inspID=57291209&county=Fulton">February 23, 2022 Score: 100, Grade: A</a> <br />
		<br />
		<strong>103 Mexican (Food Service Inspections)</strong><br>
		1 STATE FARM DR 
ATLANTA, GA 30303<br>
		View inspections:<br />
		<a href="history.cfm?id=9483808&inspID=56541356&county=Fulton">November 6, 2019 Score: 100, Grade: A</a> <br />
		<a href="history.cfm?id=9483808&inspID=56757948&county=Fulton">March 11, 2020 Score: 100, Grade: A</a> <br />
		<a href="history.cfm?id=9483808&inspID=57243439&county=Fulton">January 5, 2021 Score: 100, Grade: A</a> <br />
		<a href="history.cfm?id=9483808&inspID=57275476&county=Fulton">October 6, 2021 Score: 100, Grade: A</a> <br />
		<a href="history.cfm?id=9483808&inspID=57291232&county=Fulton">February 23, 2022 Score: 100, Grade: A</a> <br />
		<br />
		<strong>107 Grill (Food Service Inspections)</strong><br>
		1 STATE FARM DR 
ATLANTA, GA 30303<br>
		View inspections:<br />
		<a href="history.cfm?id=9483927&inspID=56541367&county=Fulton">November 6, 2019 Score: 100, Grade: A</a> <br />
		<a href="history.cfm?id=9483927&inspID=56757945&county=Fulton">March 11, 2020 Score: 100, Grade: A</a> <br />
		<a href="history.cfm?id=9483927&inspID=57240156&county=Fulton">December 3, 2020 Score: 100, Grade: A</a> <br />
		<a href="history.cfm?id=9483927&inspID=57275492&county=Fulton">October 6, 2021 Score: 100, Grade: A</a> <br />
		<a href="history.cfm?id=9483927&inspID=57291211&county=Fulton">February 23, 2022 Score: 100, Grade: A</a> <br />
		<br />
		<strong>107 Meatless Grill Portable (Food Service Inspections)</strong><br>
		1 AMB DR NW 
ATLANTA, GA 30313<br>
		View inspections:<br />
		<a href="history.cfm?id=7957642&inspID=56006865&county=Fulton">July 7, 2019 Score: 100, Grade: A</a> <br />
	<br />
	</span>'

raw_data <- str_split(raw_data, "<strong>")[[1]][-1]
entity <- str_match(raw_data, '(.+?) \\(Food Service Inspections\\)')[,2]
street_address <- str_match(raw_data, '<br>\\n\\t\\t(.+?) \\n')[,2]
city_zip <- str_match(raw_data, '\\n(.+?)<br>\\n\\t\\tView inspections')[,2]
inspections <- str_split(raw_data, "<br />")
inspections <- lapply(inspections, function(ins_list){
  ins_list <- ins_list[2:(length(ins_list)-2)]
  return(data.frame(
    date = str_match(ins_list, '>(.+?) Score:')[, 2],
    score = str_match(ins_list, ' Score: (\\d+?),')[, 2],
    grade = str_match(ins_list, ' Grade: (\\w)')[, 2],
    report_url = str_match(ins_list, ' href=\\"(.+?)\\"')[, 2]
  ))
})

df <- data.frame(entity, street_address, city_zip, I(inspections))
