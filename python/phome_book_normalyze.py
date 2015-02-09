import re

lines = []

f = open('phones.csv', 'r')
for line in f:
	lines.append(line)
f.close()

def pars(line):
	line = re.sub(r'\s', '', line)
	if len(line) == 7:
		return '+38044' + line
	elif len(line) == 9:
		return '+380' + line
	elif len(line) == 10:
		return '+38' + line
	elif len(line) == 11:
		return '+3' + line
	elif len(line) == 12:
		return '+' + line
	elif len(line) == 13:
		return line
	else:
		print('unknown lenght of number: ' + str(len(line)) + '  | line is: \"' + line + '\"')
		return line

f = open('new.csv', 'w')
for line in map(pars, lines):
	f.write(line + '\n')
f.close()
