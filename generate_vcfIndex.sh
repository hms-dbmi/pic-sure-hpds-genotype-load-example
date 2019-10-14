#!/bin/bash
HPSD_PATH=$(pwd)
# export VARIOUS="one"


# Error message
error_msg ()
{
  echo 1>&2 "Error: $1"
  exit 1
}

# Usage
usage()
{
echo "Usage: load_vcf_to_hpds.sh [-s | --singlevcf <VCF filename>] [-v | --variousvcfs <text file with list of VCFs (one VCF per line)>] [-h | --help]

Options:
-v | --variousvcfs <list of VCFs>
    This option takes the list of VCFs that need to be processed in form of text file; one line per VCF; example content of list file (list.txt):
    HG00096
    HG00097
    HG00099
    Command example: 
    ./load_vcf_to_hpds.sh -v list.txt

-s | --singlevcf <git hash>
    Provide the VCF file name to process, i.e.: 1000KG.vcf.gz
    Command example: 
    ./load_vcf_to_hpds.sh -s 1000KG.vcf.gz

-h | --help
    Displays this menu"
    exit 1
}

# Read input parameters
while [ "$1" != "" ]; do
    case $1 in
        -v|--variousvcfs)	shift
                        VARIOUS="$1"
                        ;;
        -s|--singlevcf)	shift
                        SINGLE="$1"
                        ;;
        -h|--help)      usage
                        ;;
        -*)
      					error_msg "unrecognized option: $1"
      					;;
        *)              usage
    esac
    shift
done


echo "Generating hpds index file: "
CHR="ALL"
ANNOTATED="1"
FILE_PATH="$HPSD_PATH/$SINGLE"
EXT="${FILE_PATH##*.}"
GZIP="0"
if [ "$EXT" != "vcf" ] || [ "$EXT" != "VCF" ]; then
	echo "The VCF is zipped"
	GZIP="1"
fi

bcftools query -l $SINGLE > tmp.tsv
SAMPLES="$(wc -l tmp.tsv | awk '{ print $1 }')"
SAMPLEIDS="$(paste -sd, - < tmp.tsv)"

SEQ="$(seq -s , 1 $SAMPLES)"
OS=$(uname)
# Required to avoid trailing comma
if [ "$OS" = "Darwin" ]; then
	echo "Sequence for Mac"
	SEQ=${SEQ%%?}
fi

echo -e "filename\tchromosome\tannotated\tgzip\tsample_ids\tpatient_ids\tsample_relationship\trelated_sample_ids\n$FILE_PATH\t$CHR\t$ANNOTATED\t$GZIP\t$SAMPLEIDS\t$SEQ" > vcfIndex.tsv

rm tmp.tsv
