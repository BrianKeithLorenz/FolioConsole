#!/usr/bin/bash

cd /Users/blorenz/scripts
filename=`date "+FolioInventory.%Y.%m.%d.%H.%M.%S.csv"`
directory=/Users/blorenz/inventory/
fullFileName=${directory}${filename}

curl https://resources.lendingclub.com/SecondaryMarketAllNotes.csv --output $fullFileName 

if [ -s $fullFileName ]; then
	source loadFile.sh $fullFileName
fi

