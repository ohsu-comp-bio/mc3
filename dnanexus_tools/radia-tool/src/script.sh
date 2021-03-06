#!/bin/bash

PATH=$PATH:/opt/bin

set -e -x -o pipefail

dx-download-all-inputs --parallel

mkdir -p out/output_vcf
mkdir -p out/filtered_output_vcf

if [[ "$patientId" != "" ]]
then
  radia_options="--patientId $patientId $radia_options"
  radia_filter_options="--patientId $patientId $radia_filter_options"
fi

if [[ "$fasta_path" == *.gz ]]
then
  gunzip "$fasta_path"
  fasta_path=${fasta_path%.gz}
  fasta_name=${fasta_name%.gz}
fi

if [[ "$rnaFasta" != "" ]]
then
  if [[ "$rnaFasta_path" == *.gz ]]
  then
    gunzip "$rnaFasta_path"
    rnaFasta_path=${rnaFasta_path%.gz}
    rnaFasta_name=${rnaFasta_name%.gz}
  fi
fi

if [[ "$dnaTumorBai" != "" ]]
then
  dnaTumor="--dnaTumorFilename ${dnaTumorBam_path} --dnaTumorBaiFilename ${dnaTumorBai_path}"
else
  dnaTumor="--dnaTumorFilename ${dnaTumorBam_path}"
fi

if [[ "$dnaNormalBai" != "" ]]
then
  dnaNormal="--dnaNormalFilename ${dnaNormalBam_path} --dnaNormalBaiFilename ${dnaNormalBai_path}"
else
  dnaNormal="--dnaNormalFilename ${dnaNormalBam_path}"
fi

if [[ "$rnaTumorBam" != "" ]]
then
  if [[ "$rnaTumorBai" != "" ]]
  then
    rnaTumor="--rnaTumorFilename ${rnaTumorBam_path} --rnaTumorBaiFilename ${rnaTumorBai_path}"
  else
    rnaTumor="--rnaTumorFilename ${rnaTumorBam_path}"
  fi
  if [[ "$rnaFasta" != "" ]]
  then
    rnaTumor="$rnaTumor --rnaTumorFasta ${rnaFasta_path}"
  fi
fi

if [[ "$rnaNormalBam" != "" ]]
then
  if [[ "$rnaNormalBai" != "" ]]
  then
    rnaNormal="--rnaNormalFilename ${rnaNormalBam_path} --rnaNormalBaiFilename ${rnaNormalBai_path}"
  else
    rnaNormal="--rnaNormalFilename ${rnaNormalBam_path}"
  fi
  if [[ "$rnaFasta" != "" ]]
  then
    rnaNormal="$rnaNormal --rnaNormalFasta ${rnaFasta_path}"
  fi
fi


mkdir radiatemp
cd radiatemp
python ~/radia.py \
  $dnaTumor \
  $dnaNormal \
  $rnaTumor \
  $rnaNormal \
  --fastaFilename "${fasta_path}" \
  $radia_options \
  --outputDir ~/radiatemp/ \
  -o output.vcf \
  --scriptsDir ~/radia-1.1.5/scripts/ \
  --number_of_procs `nproc`
mv output.vcf ~/out/output_vcf/output.radia.vcf
cd ..

mkdir radiafiltertemp
cd radiafiltertemp
python ~/radia_filter.py \
  --inputVCF ~/out/output_vcf/output.radia.vcf \
  $dnaTumor \
  $dnaNormal \
  $rnaTumor \
  $rnaNormal \
  --fastaFilename "${fasta_path}" \
  $radia_filter_options \
  --outputDir ~/radiafiltertemp/ \
  -o filtered.vcf \
  --scriptsDir /home/dnanexus/radia-1.1.5/scripts/ \
  --number_of_procs `nproc`
mv filtered.vcf ~/out/filtered_output_vcf/filtered.radia.vcf
cd ..

dx-upload-all-outputs

