#!/usr/bin/bash

set -x #echo on

inventoryDirectory=/Users/blorenz/inventory
scriptsDirectory=/Users/blorenz/scripts


command="sh ${scriptsDirectory}/loadFile.sh"
for inventoryFileName in `ls ${inventoryDirectory}/*.csv`;
do
	FILESIZE=`du -k "${inventoryFileName}" | cut -f1`
	echo $FILESIZE
	if [ $FILESIZE -gt "85000" ]; then
	       ${command} $inventoryFileName
	else
echo		rm $inventoryFileName
	fi
done   

