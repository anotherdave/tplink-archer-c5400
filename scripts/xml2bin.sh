#!/bin/bash
[ $# -lt 1 ] && echo "Syntax: $0 filename.xml [output-filename.bin]" && exit

IN=$1
[ $# -lt 2 ] && OUT=${IN%.*}.bin || OUT=$2

OPENSSL=/usr/local/bin/openssl

[ ! -f $IN ] && echo File $IN does not exist && exit

OUR_MD5=`echo -n "ArcherC5400" | md5sum | cut -d' ' -f 1`

# AES key & iv params
AES="-K 2EB38F7EC41D4B8E1422805BCD5F740BC3B95BE163E39D67579EB344427F7836 -iv 360028C9064242F81074F4C127D299F6"

TMP=$IN-tmp-dir
mkdir -p $TMP

# encrypt xml to get orig.bin file
cat $IN | $OPENSSL zlib | $OPENSSL aes-256-cbc $AES -out $TMP/ori-backup-user-config.bin

# make tar file with this and dummy cert
touch $TMP/ori-backup-certificate.bin
cd $TMP
tar --owner=0 --group=0 -cvf orig.bin .
cd ..

# create binary file (16 bytes) with content of product name md5
echo $OUR_MD5 | xxd -r -p >$TMP/md5file

# concatenate md5 file + orig.bin into mid.bin
cat $TMP/md5file $TMP/orig.bin >$TMP/mid.bin

# encrypt mid.bin to prepare final .bin acceptable by TP-Link firmware - Restore
$OPENSSL zlib -in $TMP/mid.bin | $OPENSSL aes-256-cbc $AES -out $OUT

echo BIN file saved in $OUT

rm -rf $TMP
