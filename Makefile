

CCs= $(shell cat TK200_DTKNR.out | egrep -v '1510|1526|1542') # ignore un-planned CCs, see https://download.bgr.de/bgr/Boden/BUEK200/Indexkarte/Indexkarte_BUEK200.pdf

BUEKs= $(CCs:%=buek200_%.pdf)
BUEKSHPs= $(CCs:%=buek200_shp_%/)


.PHONY: all getAll getAllSHPs


all : TK200_DTKNR.out # first get list of TK200 Blattschnitte, then get PDFs accordingly
	$(MAKE) -k -L getAll # use symlink mtimes
	find . -follow -printf "" 2>&1 | grep -o "\..*'" | sed "s/'//g" | xargs rm -v # remove circular links

getAll : $(BUEKs)

getAllSHPs : $(BUEKSHPs)


netz_dtk200_gk3.zip :
	wget http://www.geodatenzentrum.de/uebersichten/netz_dtk200_gk3.zip

b200_gk3.% : | netz_dtk200_gk3.zip # order only as netz_dtk200_gk3.zip: has no deps: http://stackoverflow.com/questions/21745816/makefile-make-dependency-only-if-file-doesnt-exist
	unzip -u $< $@
	chmod a-x $@

TK200_DTKNR.out : b200_gk3.shp b200_gk3.shx b200_gk3.dbf b200_gk3.prj # extract TK200 Blattschnitte
	ogrinfo -al $< | grep DTKNR | grep -o '[0-9]\{4\}' > $@ # all TK200 Blattschnitte have 4 digits


buek200_%.zip :
	-wget https://download.bgr.de/bgr/Boden/BUEK200/$*/pdf/buek200_$*.zip

buek200_%.pdf : buek200_%.zip # $< expands to '' if made order-only
	ln -sf `unzip -o $< 'buek200_*pdf' | grep 'extracting:' | awk '{print $$2}'` $@
	-chmod a-x `readlink $@`


buek200_shp_%.zip :
	-wget https://download.bgr.de/bgr/Boden/BUEK200/$*/shp/buek200_$*.zip -O $@

buek200_shp_%/ : buek200_shp_%.zip # $< expands to '' if made order-only
	find -name $< -size 0 -exec rm -v {} \;
	-test -e $< && unzip -u -d $@ $< 'buek200_$**'


#prevent removal of any intermediate files http://stackoverflow.com/questions/5426934/why-this-makefile-removes-my-goal https://www.gnu.org/software/make/manual/html_node/Chained-Rules.html
.SECONDARY: 


