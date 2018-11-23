#!/bin/bash

function add_packages {
	filename="latex/preamble/packages/packages_$1.tex"
	printf "" > $filename
	for i in latex/preamble/packages/$1/*.tex
	do
		name=$(basename $i)
		
		text="\\\\input{latex/preamble/packages/$1/$name}\\n"

		printf $text >> $filename
	done
}

add_packages $1


