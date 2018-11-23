#!/bin/bash

function add_macros {
	filename="latex/preamble/macros/macros_$1.tex"
	printf "" > $filename
	for i in latex/preamble/macros/$1/*.tex
	do
		name=$(basename $i)
		
		text="\\\\input{latex/preamble/macros/$1/$name}\\n"

		printf $text >> $filename
	done
}

add_macros $1
