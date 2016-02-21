# Обрабытывает данные из csv файла, полученного в результате работы компонента CSVI Pro (данные магазина Virtuemart 3)
# Преобразует данные в удобочитаемый формат. С учетом того, что некоторые значения заданы через плагин customfieldsforall

import csv
import sys
import re

normal_fields = ('Название объекта', 'Категория', 'Цена', 'Имя агента', 'Без комиссии', 'file url')
custom_fields = ('custom_title', 'custom_value', 'custom_param')
digital_titles = ('Общая площадь', 'Жилая площадь', 'Площадь кухни', 'Количество комнат', 'Этаж', 'Этажность дома', 'Удалённость от города', 'Площадь участка')
headers = ('Название объекта', 'Категория', 'Цена', 'Способ реализации', 'Имя агента', 'Общая площадь', 'Жилая площадь', 'Площадь кухни', 'Количество комнат', 'Этаж', 'Этажность дома', 'Населенный пункт', 'Район', 'Массив', 'Улица', 'Номер дома', 'Ближайшее метро', 'Не первый / Не последний эт.', 'Удалённость от города', 'Площадь участка', 'Контакты продавца', 'Без комиссии', 'geocustom_plg', 'file url')
delimiter='|'

records = []
custom_records = []

# функция обработки кастомных полей
def pars_custom_fields(row):
	custom_record = {}
	custom_title = []
	custom_value = []
	custom_param = []
	
	for key, value in row.items():												# разбираем строку на элементы
		if key == 'custom_title':
			custom_title = value.split('~')
		if key == 'custom_value':
			custom_value = value.split('~')
		if key == 'custom_param':
			custom_param = value.split('~')
	
	for i in range(len(custom_title)):											# собираем из элементов новые данные
		if custom_title[i] in digital_titles: 									# проверяем, что бы в числовых полях были только числа
				custom_param[i] = re.sub('[^0-9.-]+', '', custom_param[i])		# если что-то другое - удаляем

		if custom_value[i] == 'customfieldsforall':
			custom_record[custom_title[i]] = custom_param[i]
		else:
			custom_record[custom_title[i]] = custom_value[i]
	
	return custom_record


# Обрабатываем переданный в аргументе файл
with open(sys.argv[1], 'r') as f:
	reader = csv.DictReader(f, delimiter=delimiter)
	
	for row in reader:																
		row = {key: value for key, value in row.items() if value != ''}					# удаляем пустые значения
		row = {key.replace(u'\ufeff"custom_title"', 'custom_title'): value for key, value in row.items()}
		
		row_normal = {key: value for key, value in row.items() if key in normal_fields}	# берем только normal_fields
		row_custom = {key: value for key, value in row.items() if key in custom_fields}	# берем только custom_fields
		
		row_new = pars_custom_fields(row_custom)
		row_new.update(row_normal)
		
		if row:
			records.append(row_new)


# проверка, что все необходимые поля существуют
# for record in records:
# 	for key, value in record.items():
# 		if key not in headers: print(key)

# выводим результаты на экран
# for record in records:
# 	print(record)


# запись результатов в новвый csv файл
with open('result.csv', 'w', encoding='utf-8') as f:
	csv.writer(f, delimiter=delimiter).writerow(headers)			# записываем первую строку - заголовки
	writer = csv.DictWriter(f, headers, delimiter=delimiter)		# записываем данные
	writer.writerows(records)