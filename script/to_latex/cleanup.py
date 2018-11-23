flags = {}

def check_and_set(filename, tag):
	if tag in filename:
		flags[tag] = True
	else:
		flags[tag] = False
		
	return filename.replace("_"+tag,"")

def cleanup(filename):
	cleanName = check_and_set(filename, "nofloat")
	
	if "@" in cleanName:
		flags["sub"] = True
	else:
		flags["sub"] = False
	
	return cleanName
	
