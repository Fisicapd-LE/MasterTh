#include gmsl

# commands /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

SHELL=/bin/bash -O extglob -c

glob = $(shell script/glob "$(1)")

define echolog
	@tput setaf 6
	@echo $1
	@tput sgr0
endef

define errlog
	@tput setaf 1
	@echo $1
	@tput sgr0
endef

define clean
	@rm $1 2>/dev/null || true
endef

uniq = $(if $1,$(firstword $(1)) $(call uniq,$(filter-out $(firstword $(1)),$(1))))

strip_name = $(notdir $(basename $(1)))

img_candidate_impl = $(firstword $(foreach ext,$(MEDIA_EXT),$(call glob,raw/$(1)/$(2).$(ext))))
img_candidate = $(if $(call img_candidate_impl,$(1),$(2)),$(call img_candidate_impl,$(1),$(2)),img/notfound)

compose_dependency_impl = $(foreach file,$(call uniq,$(foreach glob_file,$(call glob,raw/$(1)/$(2)@*.!(txt)),$(basename $(glob_file)))),$(call img_candidate,$(1),$(call strip_name,$(file))))
compose_dependency = $(if $(call compose_dependency_impl,$(1),$(2)),$(call compose_dependency_impl,$(1),$(2)),img/notfound)

# definitions //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

FILE_REL_TEX = latex/main.tex
BASENAME_REL = $(shell basename -a $(FILE_REL_TEX))

DEPS_DIR = latex/deps

LATEXMK = latexmk.pl -recorder -use-make -deps -f -e '@cus_dep_list = ();' -e 'show_cus_dep();' -file-line-error -lualatex
	

MEDIA_EXT = tex pdf png jpg

PREAMBLE_TARGETS = lualatex pdflatex general essential
PACK_CAT = $(foreach target,$(PREAMBLE_TARGETS),latex/preamble/packages/packages_$(target).tex)
MACRO_CAT = $(foreach target,$(PREAMBLE_TARGETS),latex/preamble/macros/macros_$(target).tex)

.PHONY: clean cleanlog  preamble packlog macrolog  media graph img  clean_preamble clean_graphs clean_imgs clean_tables

# main /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

all: latex/main.pdf
	cp $(basename $(FILE_REL_TEX)).pdf ./$(shell cat info/filename)
	cp $(basename $(FILE_REL_TEX)).pdf backup/$(shell cat info/filename)

latex/main.pdf: preamble
	$(call echolog,"Building thesis...")
	yes '' | $(LATEXMK) -e '$$max_repeat = 2;' -pdf -lualatex -deps-out=$(DEPS_DIR)/$(BASENAME_REL).d -outdir=latex $(FILE_REL_TEX) || true
	#$(LATEXMK) -interaction=nonstopmode -e '$$max_repeat = 1;' -pdf -deps-out=$(DEPS_DIR)/$(BASENAME_REL).d -outdir=latex $(FILE_REL_TEX) || true
	$(LATEXMK) -pdf -lualatex -deps-out=$(DEPS_DIR)/$(BASENAME_REL).d -outdir=latex $(FILE_REL_TEX)
	
publish:
	if [ -f info/publish ]; \
	then \
		cp $(shell cat info/filename) $(shell cat info/publish); \
	fi;
	

# clean ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
clean: cleanlog clean_preamble clean_graphs clean_imgs clean_tables clean_deps
	$(call echolog,"Cleaning main files...")
	@latexmk -C -pdf -outdir=latex $(FILE_REL_TEX)
	rm -f $(shell cat info/filename)

cleanlog:
	$(call echolog,"Cleaning...")


# preamble /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
preamble: latex/preamble/packages.tex latex/preamble/macros.tex


latex/preamble/packages.tex: packlog $(PACK_CAT)

packlog:
	$(call echolog, "Checking for new packages...")

$(PACK_CAT): latex/preamble/packages/packages_%.tex: latex/preamble/packages/% script/compose/packages.sh
	$(call echolog,"Found new $* packages")
	script/compose/packages.sh $*


latex/preamble/macros.tex: macrolog $(MACRO_CAT)

macrolog:
	$(call echolog,"Checking for new macros...")
	
$(MACRO_CAT): latex/preamble/macros/macros_%.tex: latex/preamble/macros/% script/compose/macros.sh
	$(call echolog,"Found new $* macros")
	script/compose/macros.sh $*

clean_preamble:
	$(call echolog,"Cleaning preamble...")
	$(call clean,$(PACK_CAT))
	$(call clean,$(MACRO_CAT))

# deps ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
$(foreach file,$(wildcard $(DEPS_DIR)/*.d),$(eval -include $(file)))

clean_deps:	
	$(call clean,$(wildcard latex/deps/*)) 
	
.SECONDEXPANSION:
# media ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

latex/img/%.tex: $$(call img_candidate,img,%) $$(wildcard raw/img/%.txt) $$(wildcard raw/img/%.json) $$(wildcard raw/img/$(firstword $(subst @, ,%)).json) script/to_latex/cleanup.py script/to_latex/img.py
	$(call echolog,"Formatting $*...")
	script/to_latex/img.py $* img $(suffix $(call img_candidate,img,$*))
	
latex/img/%.tex: $$(call compose_dependency,img,%) $$(wildcard raw/img/%.txt) $$(wildcard raw/img/%.json) script/to_latex/cleanup.py script/to_latex/compose_img.py
	$(call echolog,"Composing $*...")
	script/to_latex/compose_img.py $* img $(foreach name,$(call compose_dependency,img,$*),$(call strip_name,$(name)))
		
latex/img/%.tex: 
	$(call errlog,"No candidate found for image $*!")
	
clean_imgs:
	$(call echolog,"Cleaning imgs...")
	$(call clean,$(wildcard latex/img/*.tex))
	

latex/graph/%.tex: $$(call img_candidate,graph,%) $$(wildcard raw/graph/%.txt) $$(wildcard raw/graph/%.json) $$(wildcard raw/graph/$(firstword $(subst @, ,%)).json) script/to_latex/cleanup.py script/to_latex/img.py
	echo $(wildcard raw/graph/$(firstword $(subst @, ,$*)).json)
	$(call echolog,"Formatting $*...")
	script/to_latex/img.py $* graph $(suffix $(call img_candidate,graph,$*))
	
latex/graph/%.tex: $$(call compose_dependency,graph,%) $$(wildcard raw/graph/%.txt) $$(wildcard raw/graph/%.json) script/to_latex/cleanup.py script/to_latex/compose_img.py
	$(call echolog,"Composing $*...")
	script/to_latex/compose_img.py $* graph $(foreach name,$(call compose_dependency,graph,$*),$(call strip_name,$(name)))
	
latex/graph/%.tex: 
	$(call errlog,"No candidate found for graph $*!")
	
clean_graphs:
	$(call echolog,"Cleaning graphs...")
	$(call clean,$(wildcard latex/graph/*.tex))
	
	
latex/table/%.tex: raw/table/%.dat $$(wildcard raw/table/%.txt) script/to_latex/cleanup.py script/to_latex/img.py
	$(call echolog,"Formatting $*...")
	script/to_latex/table.py $*
	
latex/table/%.tex: 
	$(call errlog,"No candidate found for table $*!")
	
clean_tables:
	$(call echolog,"Cleaning tables...")
	$(call clean,$(wildcard latex/table/*.tex))	
