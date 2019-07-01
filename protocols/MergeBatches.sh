#Parameter mapping
#string tmpName


#string gatkVersion
#string gatkJar
#string htsLibVersion
#string ngsUtilsVersion
#string tempDir
#string intermediateDir
#string projectVariantsMerged
#string projectVariantsMergedSorted
#string projectVariantsMergedSortedGz
#list batchID
#string projectPrefix
#string tmpDataDir
#string project
#string logsDir 
#string intermediateDir
#string groupname
#string sortVCFpl
#string indexFile
#string indexFileFastaIndex
#string extension
#string dataDir
#string capturingKit


#Load module GATK,tabix
module load "${gatkVersion}"
module load "${htsLibVersion}"
module load "${ngsUtilsVersion}"

module list

makeTmpDir "${projectVariantsMerged}"
tmpProjectVariantsMerged="${MC_tmpFile}"

makeTmpDir "${projectVariantsMergedSorted}"
tmpProjectVariantsMergedSorted="${MC_tmpFile}"

makeTmpDir "${projectVariantsMergedSortedGz}"
tmpProjectVariantsMergedSortedGz="${MC_tmpFile}"

#Function to check if array contains value
array_contains () {
    local array="$1[@]"
    local seeking=${2}
    local in=1
    for element in "${!array-}"; do
        if [[ "${element}" == "${seeking}" ]]; then
            in=0
            break
        fi
    done
    return "${in}"
}

INPUTS=()

for b in "${batchID[@]}"
do
	if [ -f "${projectPrefix}.batch-${b}.${extension}" ]
	then
		array_contains INPUTS "--variant ${projectPrefix}.batch-${b}.${extension}" || INPUTS+=("--variant ${projectPrefix}.batch-${b}.${extension}")
	fi
done

#WIP
gatk --java-options "-Xmx5g -Djava.io.tmpdir=${tempDir}" MergeVcfs \
${INPUTS[@]} \

java -Xmx5g -Djava.io.tmpdir="${tempDir}" -cp "${EBROOTGATK}/${gatkJar}" org.broadinstitute.gatk.tools.CatVariants \
-R "${indexFile}" \
${INPUTS[@]} \
-out "${tmpProjectVariantsMerged}"

echo "sorting vcf"
sortVCFbyFai.pl -fastaIndexFile "${indexFile}.fai" -inputVCF "${tmpProjectVariantsMerged}" -outputVcf "${tmpProjectVariantsMergedSorted}"

bgzip -c "${tmpProjectVariantsMergedSorted}" > "${projectVariantsMergedSortedGz}"
tabix -p vcf "${projectVariantsMergedSortedGz}"

### make allChromosomes bedfile to use it later in CheckOutput script
awk '{print $1}' "${dataDir}/${capturingKit}/human_g1k_v37/captured.merged.bed" | uniq > "${intermediateDir}/allChromosomes.txt"

