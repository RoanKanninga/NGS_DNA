#MOLGENIS walltime=05:59:00 mem=12gb nodes=1 ppn=1

#Parameter mapping
#string tmpName
#string gatkVersion
#string gatkJar
#string intermediateDir
#string dedupBam
#string project
#string logsDir 
#string groupname
#string externalSampleID
#string indexFile
#string capturedIntervalsPerBase
#string capturedBed
#string GCC_Analysis
#string sampleNameID
#string capturingKit
#string coveragePerBaseDir
#string coveragePerTargetDir
#string ngsUtilsVersion

sleep 5
module load ${gatkVersion}
module load ${ngsUtilsVersion}

### Per base bed files
bedfile=$(basename $capturingKit)
if [[ "${bedfile}" == *"CARDIO_v"* || "${bedfile}" == *"DER_v"* || "${bedfile}" == *"DYS_v"* || "${bedfile}" == *"EPI_v"* \
|| "${bedfile}" == *"LEVER_v"* || "${bedfile}" == *"MYO_v"* || "${bedfile}" == *"NEURO_v"* || "${bedfile}" == *"ONCO_v"* \
|| "${bedfile}" == *"PCS_v"* || "${bedfile}" == *"TID_v"* ]]
then
	if [ -d ${coveragePerBaseDir}/${bedfile} ]
	then
		for i in $(ls -d ${coveragePerBaseDir}/${bedfile}/*)
		do
			perBase=$(basename $i)
			perBaseDir=$(echo $(dirname $i)/${perBase}/human_g1k_v37/)
			echo "perBaseDir: $perBaseDir"
			java -Xmx10g -XX:ParallelGCThreads=4 -jar ${EBROOTGATK}/${gatkJar} \
			-R ${indexFile} \
			-T DepthOfCoverage \
			-o ${sampleNameID}.${perBase}.coveragePerBase \
			--omitLocusTable \
			-I ${dedupBam} \
			-L ${perBaseDir}/${perBase}.interval_list
	
			sed '1d' ${sampleNameID}.${perBase}.coveragePerBase > ${sampleNameID}.${perBase}.coveragePerBase_withoutHeader
			sort -V ${sampleNameID}.${perBase}.coveragePerBase_withoutHeader > ${sampleNameID}.${perBase}.coveragePerBase_withoutHeader.sorted
			paste ${perBaseDir}/${perBase}.uniq.per_base.bed ${sampleNameID}.${perBase}.coveragePerBase_withoutHeader.sorted > ${sampleNameID}.${perBase}.combined_bedfile_and_samtoolsoutput.txt

			##Paste command produces ^M character
			perl -p -i -e "s/\r//g" ${sampleNameID}.${perBase}.combined_bedfile_and_samtoolsoutput.txt

			echo -e "Index\tChr\tChr Position Start\tDescription\tMin Counts\tCDS\tContig" > ${sampleNameID}.${perBase}.coveragePerBase.txt

			awk -v OFS='\t' '{print NR,$1,$2,$4,$6,"CDS","1"}' ${sampleNameID}.${perBase}.combined_bedfile_and_samtoolsoutput.txt >> ${sampleNameID}.${perBase}.coveragePerBase.txt
			
			#remove phiX
			grep -v "NC_001422.1" ${sampleNameID}.${perBase}.coveragePerBase.txt > ${sampleNameID}.${perBase}.coveragePerBase.txt.tmp
			mv ${sampleNameID}.${perBase}.coveragePerBase.txt.tmp ${sampleNameID}.${perBase}.coveragePerBase.txt
			echo "phiX is removed for ${sampleNameID}.${perBase} perBase" 

		done
	else
		echo "There are no CoveragePerBase calculations for this bedfile: ${bedfile}"

	fi		
	## Per target bed files
	if [ -d ${coveragePerTargetDir}/${bedfile} ]
	then
		for i in $(ls -d ${coveragePerTargetDir}/${bedfile}/*)
		do
			perTarget=$(basename $i)
			perTargetDir=$(echo $(dirname $i)/${perTarget}/human_g1k_v37/)

			java -Xmx10g -XX:ParallelGCThreads=4 -jar ${EBROOTGATK}/${gatkJar} \
               		-R ${indexFile} \
               		-T DepthOfCoverage \
               		-o ${sampleNameID}.${perTarget}.coveragePerTarget \
               		-I ${dedupBam} \
			--omitDepthOutputAtEachBase \
               		-L ${perTargetDir}/${perTarget}.interval_list

			awk -v OFS='\t' '{print $1,$3}' ${sampleNameID}.${perTarget}.coveragePerTarget.sample_interval_summary | sed '1d' > ${sampleNameID}.${perTarget}.coveragePerTarget.coveragePerTarget.txt.tmp.tmp
			sort -V ${sampleNameID}.${perTarget}.coveragePerTarget.coveragePerTarget.txt.tmp.tmp > ${sampleNameID}.${perTarget}.coveragePerTarget.coveragePerTarget.txt.tmp
			paste ${sampleNameID}.${perTarget}.coveragePerTarget.coveragePerTarget.txt.tmp ${perTargetDir}/${perTarget}.genesOnly > ${sampleNameID}.${perTarget}.coveragePerTarget_inclGenes.txt
			##Paste command produces ^M character

			perl -p -i -e "s/\r//g" ${sampleNameID}.${perTarget}.coveragePerTarget_inclGenes.txt
	
			awk 'BEGIN { OFS = "\t" } ; {split($1,a,":"); print a[1],a[2],$2,$3}' ${sampleNameID}.${perTarget}.coveragePerTarget_inclGenes.txt | awk 'BEGIN { OFS = "\t" } ; {split($0,a,"-"); print a[1],a[2]}' > ${sampleNameID}.${perTarget}.coveragePerTarget_inclGenes_splitted.txt

			if [ -d ${sampleNameID}.${perTarget}.coveragePerTarget.txt ]
			then
				rm ${sampleNameID}.${perTarget}.coveragePerTarget.txt
			fi 

			echo -e "Index\tChr\tChr Position Start\tChr Position End\tAverage Counts\tDescription\tReference Length\tCDS\tContig" > ${sampleNameID}.${perTarget}.coveragePerTarget.txt
			awk '{OFS="\t"} {len=$3-$2} {print NR,$0,len,"CDS","1"}' ${sampleNameID}.${perTarget}.coveragePerTarget_inclGenes_splitted.txt >> ${sampleNameID}.${perTarget}.coveragePerTarget.txt 

			#Remove phiX
			grep -v "NC_001422.1" ${sampleNameID}.${perTarget}.coveragePerTarget.txt > ${sampleNameID}.${perTarget}.coveragePerTarget.txt.tmp
			mv ${sampleNameID}.${perTarget}.coveragePerTarget.txt.tmp ${sampleNameID}.${perTarget}.coveragePerTarget.txt
			echo "phiX is removed for ${sampleNameID}.${perTarget} perTarget" 

		done
	else
		echo "There are no CoveragePerTarget calculations for this bedfile: ${bedfile}"
	fi
else
	echo "CoveragePerBase skipped"

fi

