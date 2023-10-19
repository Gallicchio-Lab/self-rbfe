#!/bin/bash

#load settings
work_dir=$(pwd)
scripts_dir=${work_dir}/scripts
. ${scripts_dir}/setup-settings.sh

cd ${work_dir} || exit 1

#process each ligand pair
npairs=${#ligands[@]}
n=$(expr ${#ligands[@]} - 1)
for l in `seq 0 $n` ; do
    
    #return to main work directory for each ligand pair
    cd ${work_dir} || exit 1

    #ligands in ligand pair
    ligpair=${ligands[$l]}
    read -ra ligs <<< $ligpair
    lig1=${ligs[0]}
    lig2=${ligs[1]}

    echo "Processing ligand pair $lig1 $lig2 ..."
    
    #append to list of ligand pairs
    if [ -z "$ligpreppairs" ] ; then
	ligpreppairs="${lig1}-${lig2}"
    else
	ligpreppairs="${ligpreppairs} ${lig1}-${lig2}"
    fi

    #creates system in complexes folder
    jobname=${receptor}-${lig1}-${lig2}
    mkdir -p ${work_dir}/complexes/${jobname} || exit 1
    cd ${work_dir}/complexes/${jobname}    || exit 1

    #creates simulation system
    displs=""
    for d in ${displacement[@]}; do
	displs="$displs $d"
    done
    echo "Displacement vector: $displs"


    (
cat <<EOF
source leaprc.protein.ff14SB
source leaprc.phosaa14SB
source leaprc.DNA.OL15
source leaprc.RNA.OL3
source leaprc.lipid21
source leaprc.water.tip3p
source leaprc.gaff2
solute_0=loadpdb ${work_dir}/001.prep/proteins/cdk8/protein.pdb
source ${work_dir}/002_ffengine/forcefield/${lig1}/leaprc_header
loadAmberParams ${work_dir}/002_ffengine/forcefield/${lig1}/L1.frcmod
solute_1=loadmol2 ${work_dir}/002_ffengine/forcefield/${lig1}/L1.mol2
solute_2=loadmol2 ${work_dir}/002_ffengine/forcefield/${lig1}/L1.mol2
translate solute_2 { $displs }
sys=combine {solute_0 solute_1 solute_2}
solvateBox sys TIP3PBOX 10
addions sys K+ 0
addions sys Cl- 0
check sys
saveamberparm sys ${jobname}.prmtop ${jobname}.inpcrd
savePdb sys ${jobname}.pdb
quit
EOF
) > tleap.cmd

    if [ ! -f ${jobname}.pdb ] ; then
	tleap -f tleap.cmd || exit 1
    fi

    #search for the first ligand to find the size of the receptor
    namereslig1=$( awk  'f{printf("%.3s", $8);f=0} /@<TRIPOS>ATOM/{f=1}' ${work_dir}/002_ffengine/forcefield/${lig1}/L1.mol2 ) || exit 1
    l1=$( awk "\$4 ~ /${namereslig1}/{print \$2}" < ${jobname}.pdb  | head -1 ) || exit 1
    lig1start=$(expr $l1 - 1 )
    num_atoms_rcpt=$(expr $l1 - 1 )
    #retrieve number of atoms of the ligands from their mol2 files
    num_atoms_lig1=$( awk 'NR==3{print $1}' ${work_dir}/002_ffengine/forcefield/${lig1}/L1.mol2 ) || exit 1
    num_atoms_lig2=$( awk 'NR==3{print $1}' ${work_dir}/002_ffengine/forcefield/${lig1}/L1.mol2 ) || exit 1
    lig2start=$( expr $num_atoms_rcpt + $num_atoms_lig1 )
    
    #list of ligand atoms (starting from zero) assuming they are listed soon after the receptor
    lig1end=$( expr $lig1start + $num_atoms_lig1 - 1 )
    lig1_atoms=""
    for i in $( seq $lig1start $lig1end ); do
	if [ -z "$lig1_atoms" ] ; then
	    lig1_atoms=$i
	else
	    lig1_atoms="${lig1_atoms}, $i"
	fi
    done
    lig2end=$( expr $lig2start + $num_atoms_lig2 - 1 )
    lig2_atoms=""
    for i in $( seq $lig2start $lig2end ); do
	if [ -z "$lig2_atoms" ] ; then
	    lig2_atoms=$i
	else
	    lig2_atoms="${lig2_atoms}, $i"
	fi
    done
    echo "atoms of $lig1 are $lig1_atoms"
    echo "atoms of $lig2 are $lig2_atoms"

    #ligand alignment reference atoms
    refpair=${ref_atoms[$l]}
    read -ra ref <<< $refpair
    ref_atoms1a="${ref[0]}"
    ref_atoms2a="${ref[1]}"
    #split each list of ref atoms such as 1,2,3 on the commas and shift by 1
    IFS=','
    read -ra ref1 <<< "${ref_atoms1a}"
    ref_atoms1=""
    ref_atoms1_g=""
    for i in ${ref1[@]}; do
	#i1=$( expr $i - 1 )
	#reference atoms are already shifted
	i1=$( expr $i - 0)
	i2=$( expr $i1 + $lig1start )
	if [ -z "$ref_atoms1" ] ; then
	    ref_atoms1=$i1
	    ref_atoms1_g=$i2
	else
	    ref_atoms1="${ref_atoms1}, $i1"
	    ref_atoms1_g="${ref_atoms1_g}, $i2"
	    
	fi
    done
    read -ra ref2 <<< "${ref_atoms2a}"
    ref_atoms2=""
    for i in ${ref2[@]}; do
	#i1=$( expr $i - 1 )
	#reference atoms are already shifted
	i1=$( expr $i - 0 )
	i2=$( expr $i1 + $lig2start )
	if [ -z "$ref_atoms2" ] ; then
	    ref_atoms2=$i1
	    ref_atoms2_g=$i2
	else
	    ref_atoms2="${ref_atoms2}, $i1"
	    ref_atoms2_g="${ref_atoms2_g}, $i2"
	fi
    done
    unset IFS
    echo "the reference alignment atoms (mol indexes) for $lig1 are $ref_atoms1"
    echo "the reference alignment atoms (mol indexes) for $lig2 are $ref_atoms2"
    echo "the reference alignment atoms (global indexes) for $lig1 are $ref_atoms1_g"
    echo "the reference alignment atoms (global indexes) for $lig2 are $ref_atoms2_g"

    #builds mintherm, mdlambda scripts
    replstring="s#<JOBNAME>#${jobname}# ; s#<DISPLX>#${displacement[0]}# ; s#<DISPLY>#${displacement[1]}# ; s#<DISPLZ>#${displacement[2]}# ; s#<REFERENCEATOMS1>#${ref_atoms1}# ; s#<REFERENCEATOMS2>#${ref_atoms2}# ; s#<VSITERECEPTORATOMS>#${vsite_rcpt_atoms}# ; s#<RESTRAINEDATOMS>#${restr_atoms}# ; s#<LIG1RESID>#${ligresid[0]}# ; s#<LIG2RESID>#${ligresid[1]}# ; s#<LIG1ATOMS>#${lig1_atoms}# ; s#<LIG2ATOMS>#${lig2_atoms}# ; s#<LIG1CMATOMS>#$lig1_cmatom# ; s#<LIG2CMATOMS>#$lig2_cmatom# " 
    sed "${replstring}" < ${work_dir}/scripts/asyncre_template.cntl > ${jobname}_asyncre.cntl || exit 1

    #copy runopenmm, nodefile, slurm files, etc
    sed "s#<JOBNAME>#${jobname}#g;s#<ASYNCRE_DIR>#${asyncre_dir}#g" < ${work_dir}/scripts/run_template.sh > ${work_dir}/complexes/${jobname}/run.sh
    sed "s#<JOBNAME>#${jobname}#g;s#<ASYNCRE_DIR>#${asyncre_dir}#g" < ${work_dir}/scripts/run-farm-4gpus-template.sh > ${work_dir}/complexes/${jobname}/run-farm-4gpus.sh
    cp ${work_dir}/scripts/analyze.sh ${work_dir}/scripts/uwham_analysis.R ${work_dir}/complexes/${jobname}/
    
done

#prepare prep script
sed "s#<RECEPTOR>#${receptor}# ; s#<LIGPAIRS>#${ligpreppairs}# ; s#<ASYNCRE_DIR>#${asyncre_dir}#g " < ${work_dir}/scripts/prep_template.sh > ${work_dir}/complexes/prep.sh
#prepare free energy calculation script
sed "s#<RECEPTOR>#${receptor}# ; s#<LIGPAIRS>#${ligpreppairs}# " < ${work_dir}/scripts/free_energies_template.sh > ${work_dir}/complexes/free_energies.sh
