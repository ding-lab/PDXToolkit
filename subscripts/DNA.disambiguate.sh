#!/bin/bash

# 3/25/2019 - to running many samples same time, added the remove command 
# Hua Sun

# sh disambiguate.sh -C contig.ini -N sampleName -D /path/outDir
# output - the result output to outDir/sampleName folder
# memory 18 Gb # some times need to high memory

# getOptions
while getopts "C:N:D:" opt; do
  case $opt in
    C)
      CONFIG=$OPTARG
      ;;
    N)
      NAME=$OPTARG
      ;;
    D)
      DIR=$OPTARG
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

if [ ! -d $DIR ]; then
  echo "[ERROR] The $DIR not exists!" >&2
  exit 1
fi

if [ -z "$NAME" ]; then
  echo "[ERROR] The Name is empty!" >&2
  exit 1
fi


OUT=$DIR/$NAME

##-------------- Do Disambiguate --------------##

# Disambiguate (mouse-filter)
$DISAMBIGUATE -s $NAME -o $OUT -a bwa $OUT/$NAME.human.sort.bam $OUT/$NAME.mouse.sort.bam


##-------------- remove all disambiguate processing files
rm -f $OUT/$NAME.human.sort.bam $OUT/$NAME.mouse.sort.bam $OUT/$NAME.disambiguatedSpeciesB.bam


# re-create fq
$SAMTOOLS sort -m 2G -@ 6 -o $OUT/$NAME.disam.sortbyname.bam -n $OUT/$NAME.disambiguatedSpeciesA.bam
$SAMTOOLS fastq $OUT/$NAME.disam.sortbyname.bam -1 $OUT/$NAME.disam_1.fastq.gz -2 $OUT/$NAME.disam_2.fastq.gz -0 /dev/null -s /dev/null -n -F 0x900


##-------------- remove disambiguate spaciesA and disam.sortbyname bams
rm -f $OUT/$NAME.disambiguatedSpeciesA.bam 
rm -f $OUT/$NAME.disam.sortbyname.bam


# mapping to human reference and create to bam
$BWA mem -t 8 -M -R "@RG\tID:$NAME\tPL:illumina\tLB:$NAME\tPU:$NAME\tSM:$NAME" $REF_HUMAN $OUT/$NAME.disam_1.fastq.gz $OUT/$NAME.disam_2.fastq.gz | $SAMTOOLS view -Shb -o $OUT/$NAME.disam.reAlign.pre.bam - 


##-------------- remove fq files
rm -f $OUT/$NAME.disam_1.fastq.gz $OUT/$NAME.disam_2.fastq.gz


# sort
$JAVA -Xmx16G -jar $PICARD SortSam \
   CREATE_INDEX=true \
   I=$OUT/$NAME.disam.reAlign.pre.bam \
   O=$OUT/$NAME.disam.reAlign.bam \
   SORT_ORDER=coordinate \
   VALIDATION_STRINGENCY=STRICT

# remove process file for save space
rm -f $OUT/$NAME.disam.reAlign.pre.bam

# remove-duplication
$JAVA -Xmx16G -jar $PICARD MarkDuplicates \
   I=$OUT/$NAME.disam.reAlign.bam \
   O=$OUT/$NAME.disam.reAlign.remDup.bam \
   REMOVE_DUPLICATES=true \
   M=$OUT/$NAME.disam.reAlign.remDup.metrics.txt

# index bam
$SAMTOOLS index $OUT/$NAME.disam.reAlign.remDup.bam


##-------------- remove process file for save space
rm -f $OUT/$NAME.disam.reAlign.bam
rm -f $OUT/$NAME.ambiguous*

