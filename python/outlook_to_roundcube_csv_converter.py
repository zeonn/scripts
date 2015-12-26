# Преобразует адресную книгу, экспортированную из Outlook в адресную книгу для импорта в Roundcube

import csv
import sys

fields = ('Имя', 'Отчество', 'Фамилия', 'Адрес эл. почты', 'Адрес 2 эл. почты', 'Адрес 3 эл. почты')
headers = ('First Name', 'Middle Name', 'Last Name', 'E-mail Address', 'E-mail 2 Address', 'E-mail 3 Address')
records = []

with open(sys.argv[1], 'r') as f:
	reader = csv.DictReader(f)
	for row in reader:
		row = {key: value for key, value in row.items() if value != None}	# удаляем отсутствующие значения
		if not row['Имя']:	# если нет имени, то вприсываем в качестве него Адрес эл. почты
			row.update({'Имя': value for key, value in row.items() if key == 'Адрес эл. почты'})
		row = {key: value for key, value in row.items() if value != ''}		# удаляем пустые значения
		row = {key: value for key, value in row.items() if key in fields}	# берем только нужные
		if row:
			records.append(row)

for record in records:
	print(record)

with open('result.csv', 'w', encoding='utf-8') as f:
	csv.writer(f).writerow(headers)		# записываем первую строку - заголовки
	writer = csv.DictWriter(f, fields)	# записываем данные
	writer.writerows(records)