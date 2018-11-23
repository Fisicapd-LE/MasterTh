#!/usr/bin/env python3

import cleanup
import sys
import json

def img_to_latex(name, folder, ext):
	cleanName = cleanup.cleanup(name)
	prefix = {"graph": "gr", "img": "img"}
	f = open("latex/" + folder + "/" + cleanName + ".tex", "w")
	try:
		caption = open("raw/" + folder + "/" + cleanName + ".txt", "r").read()
	except FileNotFoundError:
		caption = cleanName.replace("_", " ")
	
	try:
		metainfo = json.load(open("raw/" + folder + "/" + name + ".json", "r"))
	except FileNotFoundError:
		metainfo = {}
	
	if not cleanup.flags["sub"]:
		f.write("\\begin{figure}[" + ("H" if cleanup.flags["nofloat"] else "h") + "]\n")
	else:
		print("raw/" + folder + "/" + name.split("@")[0] + ".json")
		try:
			container_metainfo = json.load(open("raw/" + folder + "/" + name.split("@")[0] + ".json", "r"))
		except FileNotFoundError:
			container_metainfo = {}
			
		print(str(container_metainfo))
			
		if 'by_row' in container_metainfo:
			width = 0.95/container_metainfo['by_row']
		else:
			width = 0.475
		
		f.write("\\begin{subfigure}{" + str(width) + "\\textwidth}\n")
	
	f.write("\\centering\n")
	if ext ==  ".tex":
		f.write("\\resizebox{0.7\\textwidth}{!}{\\input{./raw/" + folder + "/" + cleanName + ext + "}}\n")
	else:
		f.write("\\includegraphics[width=0.7\\textwidth]{./raw/" + folder + "/" + cleanName + ext + "}\n")
	f.write("\\caption{" + caption + "}\n")
	f.write("\\label{" + prefix[folder] + ":" + cleanName + "}\n")
	if not cleanup.flags["sub"]:
		f.write("\\end{figure}")
	else:
		f.write("\\end{subfigure}")
		
	f.close()
	return 0
	
img_to_latex(sys.argv[1], sys.argv[2], sys.argv[3])


