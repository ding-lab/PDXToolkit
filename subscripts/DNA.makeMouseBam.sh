#!/bin/bash

# 2018/11/4 - to running many samples same time, added the remove command 
# Hua Sun

# sh disambiguate.full-step.from_fq.sh -C contig.ini -N sampleName -1 name.fq1.gz -2 name.fq2.gz -O /path/outDir
# output - the result output to outDir/sampleName folder
# memory 16 Gb # some times need to high memory

# getOptions
while getopts "C:N:1:2:O:" opt; do
  case $opt in
    C)
      CONFIG=$OPTARG
      ;;
    N)
      NAME=$OPTARG
      ;;
    1)
      FQ1=$OPTARG
      ;;
    2)
      FQ2=$OPTARG
      ;;    
    O)
      OUTDIR=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done


source $CONFIG

if [ ! -d $OUTDIR ]; then
  echo "[ERROR] The $OUTDIR not exists!" >&2
  exit 1
fi

if [ -z "$NAME" ]; then
  echo "[ERROR] The Name is empty!" >&2
  exit 1
fi


OUT=$OUTDIR/$NAME
mkdir -p $OUT


# mouse
$BWA mem -t 8 -M -R "@RG\tID:$NAME\tPL:illumina\tLB:$NAME\tPU:$NAME\tSM:$NAME" $REF_MOUSE $FQ1 $FQ2 | $SAMTOOLS view -Shb -o $OUT/$NAME.mouse.bam -

#$SAMTOOLS view -Sbh $OUT/$NAME.mouse.sam > $OUT/$NAME.mouse.bam
# remove process file for save space
#rm -f $OUT/$NAME.mouse.sam

# sort bam by natural name
$SAMTOOLS sort -m 2G -@ 6 -o $OUT/$NAME.mouse.sort.bam -n $OUT/$NAME.mouse.bam

# remove process file for save space
rm -f $OUT/$NAME.mouse.bam
