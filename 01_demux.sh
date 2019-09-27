#!/bin/bash
set -e -o pipefail
input=$1
barcode=$2

R1=${input}/*R1*.fastq.gz
R2=${input}/*R2*.fastq.gz

outprefix=`basename $R1 | cut -f1 -d '_'`

prefix=trimmed_${outprefix}

echo "### demux on the left..."
cutadapt -O 10 -g file:${barcode} \
	 -o ${prefix}-L-{name}.1.fastq.gz -p ${prefix}-L-{name}.2.fastq.gz \
	 $R1 $R2

echo "### demux on the right..."
cutadapt -O 10 -g file:${barcode} \
	 -o ${prefix}-R-{name}.2.fastq.gz -p ${prefix}-R-{name}.1.fastq.gz \
	 $R2 $R1

	 ### ${prefix}-L-unknown.2.fastq.gz ${prefix}-L-unknown.1.fastq.gz

echo "### concatenating left and right..."
for b in `grep '^>' $barcode | sed 's/>//'`;
do
    cat ${prefix}-L-${b}.2.fastq.gz ${prefix}-R-${b}.1.fastq.gz > ${outprefix}-${b}.concat.fastq.gz
done

echo "### creating a manifest file for qiime2..."
echo "sample-id,absolute-filepath,direction" > ${outprefix}.single.manifest
for b in `grep '^>' $barcode | sed 's/>//'`;
do
    echo "${b},$PWD/${outprefix}-${b}.concat.fastq.gz,forward" >> ${outprefix}.single.manifest
done

