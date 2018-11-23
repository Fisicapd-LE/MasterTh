#!/usr/bin/env python3

import sys
import json

def composeImg(name, folder, files):
	files = list(files)
	f = open("latex/" + folder + "/" + name + ".tex", "w")
	try:
		caption = open("raw/" + folder + "/" + name + ".txt", "r").read()
	except FileNotFoundError:
		caption = name.replace("_", " ")
	
	try:
		metainfo = json.load(open("raw/" + folder + "/" + name + ".json", "r"))
	except:
		metainfo = {}
		
	if 'by_row' in metainfo:
		by_row = int(metainfo['by_row'])
	else:
		by_row = 2
		
	f.write("\\begin{figure}[H]\n")
	f.write("\\centering\n")
	
	for i in range(len(files)//by_row):
		for j in range(by_row):
			f.write("\input" + folder + "{" + files[by_row*i+j] + "}%\n")
			f.write("~\n")
		f.write("\\\\\n")
	
	for i in range(by_row*(len(files)//by_row),len(files)):
		f.write("\input" + folder + "{" + str(files[i]) + "}%\n")
		f.write("~\n")
	
	f.write("\\caption{" + caption + "}\n")
	f.write("\\label{gr:" + name + "}\n")
	f.write("\\end{figure}")
	
	return 0

composeImg(sys.argv[1], sys.argv[2], sys.argv[3:])
