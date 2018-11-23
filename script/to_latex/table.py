#!/usr/bin/env python3

import sys
import cleanup
import re
import json
from string import Template

def compose_line(fields):
	line_sep = json.load(open("aux/table/line_model.json"))
	
	write_line = line_sep['before']
	write_line += line_sep['middle'].join(fields)
	write_line += line_sep['after']
	
	return write_line
	
def compose_title(fields):
	title_sep = json.load(open("aux/table/title_model.json"))
	
	labels = []
	for pos, field in enumerate(fields):
		levels = field.split("#")
		for level, label in enumerate(reversed(levels)):
			if len(labels) == level:
				labels.append([])
				
			if pos > len(labels[level]):
				for i in range(len(labels[level]), pos):
					labels[level].append(None)
			
			if label == "":
				label = None
				
			labels[level].append(label)
			
	
	
	write_title = ""
	for line, level in reversed(list(enumerate(labels))):
		fields = []
		lines = ""
		previousLabel = level[0]
		length = 1
		pos = 1
		for label in level[1:]:
			pos += 1
			
			if label == previousLabel and previousLabel != None:
				length += 1
				continue
				
			field = ""
			if previousLabel != None:
				if length == 1:
					field = previousLabel
				else:
					field = "\multicolumn{" + str(length) + "}{c}{" + str(previousLabel) + "}"
					lines += "\cmidrule(lr){" + str(pos - length) + "-" + str(pos - 1) + "}\n"
				
			fields.append(field)
				
			previousLabel = label
			length = 1
			
		pos += 1
		
		field = ""	
		if previousLabel != None:
			if length == 1:
				field = previousLabel
			else:
				field = "\multicolumn{" + str(length) + "}{c}{" + str(previousLabel) + "}"
				lines += "\cmidrule(lr){" + str(pos - length) + "-" + str(pos - 1) + "}\n"
		fields.append(field)
		
		write_title += title_sep['before']
		write_title += title_sep['middle'].join(fields)
		write_title += title_sep['after']
		write_title += "\n"
		
		if line != 0:
			write_title += lines
	
	return write_title
	
def compose_tbody(lines):
	tbody_sep = json.load(open("aux/table/tbody_model.json"))
	
	write_tbody = tbody_sep['before']
	write_tbody += tbody_sep['middle'].join(lines)
	write_tbody += tbody_sep['after']
	
	return write_tbody

def tab_to_latex(name):
	cleanName = cleanup.cleanup(name)
	f = open("latex/table/" + cleanName + ".tex", "w")
	fin = open("raw/table/" + name + ".dat", "r")
	
	table_model = Template(open("aux/table/table_model.tpl").read())
	tbody_sep = json.load(open("aux/table/tbody_model.json"))
	
	try:
		caption = open("raw/table/" + cleanName + ".txt", "r").read()
	except FileNotFoundError:
		caption = cleanName.replace("_", " ")
		
	#fileLines = fin.readlines()
	
	title = fin.readline().strip()
	titlefields = re.split(r"\t+", title)
	cols = ""
	write_fields = []
	for field in titlefields:
		if field == "|":
			cols += "|"
		else:
			cols += "c"
			if field == "$empty":
				write_fields.append("")
			else:
				write_fields.append(field)
			
	write_title = compose_title(write_fields)
	
	lines = []
	
	for line in fin:
		if line.startswith("#"):
			continue
		line = line.strip()
		fields = re.split(r"\t+", line)
		fields = [f if f != "$empty" else "" for f in fields]
		lines.append(compose_line(fields))
		
	tablebody = compose_tbody(lines)
	
	table = table_model.substitute(titleline = write_title, tbody = tablebody, cols = cols)
	
	f.write("\\begin{table}[" + ("H" if cleanup.flags["nofloat"] else "h") + "]\n")
	f.write(table)
	f.write("\\caption{" + caption + "}\n")
	f.write("\\label{tab:" + cleanName + "}\n")
	f.write("\\end{table}")
		
	f.close()
	return 0
	
tab_to_latex(sys.argv[1])
