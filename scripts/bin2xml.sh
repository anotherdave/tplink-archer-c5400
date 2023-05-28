#!/bin/bash
[ $# -lt 1 ] && echo "Syntax: $0 backup-filename.bin [output-filename.xml]" && exit

IN=$1
[ $# -lt 2 ] && OUT=${IN%.*}.xml || OUT=$2

OPENSSL=/usr/local/bin/openssl

[ ! -f $IN ] && echo File $IN does not exist && exit

# Product name found in the firmware bin file (root.img):
# SupportList:
# {product_name:ArcherC5400,product_ver:1.0.0,special_id:00000000}
# {product_name:ArcherC5400,product_ver:1.0.0,special_id:55530000}
OUR_MD5=`echo -n "ArcherC5400" | md5sum | cut -d' ' -f 1`

# AES key & iv params
AES="-K 2EB38F7EC41D4B8E1422805BCD5F740BC3B95BE163E39D67579EB344427F7836 -iv 360028C9064242F81074F4C127D299F6"

TMP=$IN-tmp-dir
mkdir -p $TMP

# decode binary file downloaded from TP-Link firmware - Backup
$OPENSSL aes-256-cbc -d $AES -in $IN | $OPENSSL zlib -d -out $TMP/mid.bin

# first 16 bytes are MD5 of product
FILE_MD5=`dd if=$TMP/mid.bin  bs=1 count=16 2>/dev/null |  hexdump -v -e '/1 "%02x"'`

echo "File MD5: ${FILE_MD5}, product MD5: ${OUR_MD5}"
[ "${OUR_MD5}" != "${FILE_MD5}" ] && echo "MD5 product name mismatch, beware when using xml2bin !!!" || echo "MD5 matches, this is the right binary file :-)"

# skip 16 bytes of md5 and extract tar file which contains:
#drwxr-xr-x root/root         0 1970-01-11 16:02 ./
#---------- root/root     10656 1970-01-11 16:02 ./ori-backup-user-config.bin
#---------- root/root         0 1970-01-11 16:02 ./ori-backup-certificate.bin
dd if=$TMP/mid.bin of=$TMP/orig.tar bs=1 skip=16 2>/dev/null
tar --directory $TMP -xvf $TMP/orig.tar 

# decrypt again to get xml file
$OPENSSL aes-256-cbc -d $AES -in $TMP/ori-backup-user-config.bin | $OPENSSL zlib -d -out $OUT

echo XML file saved in $OUT
rm -rf $TMP
