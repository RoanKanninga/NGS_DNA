#MOLGENIS nodes=1 ppn=1 mem=1gb walltime=05:59:00

#Parameter mapping
#string tmpName
#string seqType
#string phiXEnd1Gz
#string phiXEnd2Gz
#string srBarcodeFqGz
#string peEnd1BarcodeFqGz
#string peEnd2BarcodeFqGz
#string peEnd1BarcodePhiXFqGz
#string peEnd2BarcodePhiXFqGz
#string project
#string logsDir 
#string groupname

# Spike phiX only once
samp=`tail -10 ${peEnd1BarcodeFqGz}`
phiX=`tail -10 ${phiXEnd1Gz}`

if [ "$samp" = "$phiX" ]; 
then
	echo "Skip this step! PhiX was already spiked in!"
	exit 0
else
	if [ "${seqType}" == "SR" ]
	then
		echo "Spike phiX not implemented yet for Single Read"
		exit 1
	elif [ "${seqType}" == "PE" ]
	then
		echo "Append phiX reads"
		cat ${peEnd1BarcodeFqGz} ${phiXEnd1Gz} > ${peEnd1BarcodePhiXFqGz}
		cat ${peEnd2BarcodeFqGz} ${phiXEnd2Gz} > ${peEnd2BarcodePhiXFqGz}
	fi
fi
