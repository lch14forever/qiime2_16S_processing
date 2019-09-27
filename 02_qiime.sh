#!/bin/bash
set -e -o pipefail

prefix=$1

gg=/mnt/projects/lich/stooldrug/16S/models/gg-13-8-99-515-806-nb-classifier.qza
silva=/mnt/projects/lich/stooldrug/16S/models/silva-132-99-515-806-nb-classifier.qza

classifier=$gg ## default is gg

db=gg

if [ "$db" = "gg" ]; then
  classifier=$gg
fi

if [ "$db" = "silva" ]; then
  classifier=$silva
fi

echo "Using $db<==>$classifier as the trained classifier..."

echo "[01] import into qiime..."
qiime tools import \
  --type 'SampleData[SequencesWithQuality]' \
  --input-path ${prefix}.single.manifest \
  --output-path ${prefix}-demux.qza \
  --input-format SingleEndFastqManifestPhred33

echo "[02] denoising with dada2..."
qiime dada2 denoise-single \
  --p-trim-left 0 \
  --p-trunc-len 0 \
  --i-demultiplexed-seqs ${prefix}-demux.qza \
  --o-representative-sequences ${prefix}-rep-seqs-dada2.qza \
  --o-table ${prefix}-table-dada2.qza \
  --o-denoising-stats ${prefix}-stats-dada2.qza --verbose


echo "[03] classifying features..."
mkdir -p $PWD/tmp
TMPDIR=$PWD/tmp qiime feature-classifier classify-sklearn \
  --i-classifier $classifier \
  --i-reads ${prefix}-rep-seqs-dada2.qza \
  --o-classification ${prefix}-taxonomy-dada2.qza

echo "[04.1] collapse at genus level..."
qiime taxa collapse \
  --i-table ${prefix}-table-dada2.qza \
  --i-taxonomy ${prefix}-taxonomy-dada2.qza \
  --p-level 6 \
  --o-collapsed-table ${prefix}-genus-table-dada2.qza
qiime tools export --input-path ${prefix}-genus-table-dada2.qza --output-path exported
biom convert -i exported/feature-table.biom -o ${prefix}-genus-table.tsv --to-tsv

echo "[04.2] collapse at family level..."
qiime taxa collapse \
  --i-table ${prefix}-table-dada2.qza \
  --i-taxonomy ${prefix}-taxonomy-dada2.qza \
  --p-level 5 \
  --o-collapsed-table ${prefix}-family-table-dada2.qza
qiime tools export --input-path ${prefix}-family-table-dada2.qza --output-path exported
biom convert -i exported/feature-table.biom -o ${prefix}-family-table.tsv --to-tsv

# echo "[05] export feature (ASV) table to data"
# qiime tools export --input-path ${prefix}-table-dada2.qza --output-path exported
# qiime tools export --input-path ${prefix}-taxonomy-dada2.qza --output-path exported
# biom convert -i exported/feature-table.biom -o ${prefix}-feature-table.tsv --to-tsv
# ~lich/local/bin/csvtk join -C '$' -t <(tail -n+2 ${prefix}-feature-table.tsv ) exported/taxonomy.tsv -o ${prefix}-feature-table-tax.tsv


