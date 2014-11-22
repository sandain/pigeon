#!/bin/sh


# Olsen_3304X.txt file -> barcode & libraries
# Olsen_3304X.fna file -> raw fasta

USAGE="Usage: $0 <Library Description File> <Fasta File>"

PSAA_REF="/usr/local/database/psaA_ref.fa"
ERIC_REF="/usr/local/database/psaADVs.txt"

if [ ! -s "$1" ]; then
  echo "Library Description File not found!"
  echo $USAGE
  exit 1
fi

if [ ! -s "$2" ]; then
  echo "Fasta File not found!"
  echo $USAGE
  exit 1
fi

SAMPLE_IDS=$(grep -v '#' $1 | cut -f1)

for ID in $SAMPLE_IDS; do
  BARCODE=$(grep $ID $1 | cut -f2)
  /usr/local/biotools/pigeon/scripts/split_miseq.pl $2 $ID
  /usr/local/biotools/pigeon/scripts/remove_barcode.pl $ID.fna $BARCODE $ID.nobarcode.fna
  /usr/local/biotools/pigeon/scripts/align.pl $PSAA_REF $ID.nobarcode.fna $ID.nobarcode.aligned.fna
  /usr/local/biotools/pigeon/scripts/remove_duplicate.pl $ID.nobarcode.aligned.fna $ID.nobarcode.aligned.nodupe.fna
  /usr/local/biotools/pigeon/scripts/rename_sequence.pl $ID.nobarcode.aligned.nodupe.fna $ID.nobarcode.aligned.nodupe.renamed.fna
  /usr/local/biotools/pigeon/scripts/complement.pl $ID.nobarcode.aligned.nodupe.renamed.fna $ID.nobarcode.aligned.nodupe.renamed.complement.fna
  /usr/local/biotools/pigeon/scripts/compare.pl $ERIC_REF $ID.nobarcode.aligned.nodupe.renamed.complement.fna $ID.csv
done
