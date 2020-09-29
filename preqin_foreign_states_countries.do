/*
Cleaning MSAs for Merging w/ Patents Dataset

*/

#delimit ;
local foreign_cities zzz "Buenos Aires" "Yerevan" "Adelaide" "Brisbane" "Camperdown"
			"Canberra" "Melbourne" "Perth" "Sydney" "Wien" "Bangladesh" "Belgique"
			"Brussels" "Leuven" "Bruxelles" "Rio " "Sao Paulo" "Calgary" "Edmonton"
			"Manitoba" "Montreal" "Ontario" "Ottawa" "Quebec" "Toronto" "Vancouver"
			"Winnipeg" "Phnom Penh"	"Beijing" "Guangzhou" "Shanghai" "Bogota"
			"Prague" "Copenhagen" "Cairo" "Addis Ababa" "Helsinki" "Turku"
			"Bordeaux" "Lyon" "Marseille" "Nantes" "Nice" "Paris" "Rouen"
			"Strasbourg" "Berlin" "Bremen" "Frankfurt" "Hamburg" "Munich"
			"Thessaloniki" "Port-au-Prince" "Hong Kong" "Budapest"
			"Bangalore" "Bombay" "Calcutta" "Kolkata" "Mumbai" "New Delhi"
			"Dublin" "Baghdad" "Jerusalem" "Tel Aviv" "Bologna" "Genova" "Milan"
			"Rome" "Kyoto" "Osaka" "Tokyo" "Nairobi" "Seoul" "Mexico City"
			"Amsterdam" "Auckland" "Oslo" "Bergen" "Warsaw" "Edinburgh"
			"Barcelona" "Cordoba" "Seville" "Khartoum" "Stockholm" "Singapore"
			"Basel" "Bern" "Geneva" "Zurich" "Taipei" "Bangkok" "London"
			"Aix-en-Provence" "Abu Dhabi" "Amman" "Hellerup" "Zug" "Moscow" "Shenzhen";
local foreign_states zzz "Ontario" "Quebec" "British Columbia" "Alberta"
			"Saskatchewan" "Manitoba" "Karnataka" "Cyberjaya" "Durham" "Deutschland"
			"Queensland" "New South Wales" "Victoria" "Western Australia" "South Australia"
			"Hertfordshire" "Cambridgeshire" "England" "Surrey" "Middlesex" "Cheshire"
			"Kusnacht" "Tokyo" "Kanagawa" "Osaka" "Aichi" "Kerala" "Hellerup" "Modena"
			"Shanghai" "Guangdong" "Jiangsu" "Sandton" "Delhi" "Mumbai" "Shiga"
			"Zhejiang" "Gyeonggi-do" "Oxfordshire" "Saarland" "Banten" "Yunnan" "CX Saint"
			"Pituach" "Moscow Oblast" "Newfoundland" "Hubei" "Maharashtra" "Rheda"
			"Fujian" "Sichuan" "Australian Capital Territory" "Québec" " Henan"
			"Nuevo Leon" "Chester" "Jiangxi" "Liaoning" "Chungcheongbuk-do" "Nova Scotia"
			"Lancashire" "Gujarat" "Haryana" "Harjumaa" "Niigata" "Hyogo" "Oita"
			"Catalonia" "Shanxi" "Liaoning" "Hongkong" "Ibaraki Prefecture";
#delimit cr

