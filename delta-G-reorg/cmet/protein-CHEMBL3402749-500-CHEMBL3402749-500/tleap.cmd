source leaprc.protein.ff14SB
source leaprc.phosaa14SB
source leaprc.DNA.OL15
source leaprc.RNA.OL3
source leaprc.lipid21
source leaprc.water.tip3p
source leaprc.gaff2
solute_0=loadpdb /nfs/sheenam-d/self-rbfe/cmet-2/003_rism/proteins/cmet/protein.pdb
source /nfs/sheenam-d/self-rbfe/cmet-2/002_ffengine/forcefield/CHEMBL3402749-500/leaprc_header
loadAmberParams /nfs/sheenam-d/self-rbfe/cmet-2/002_ffengine/forcefield/CHEMBL3402749-500/L1.frcmod
solute_1=loadmol2 /nfs/sheenam-d/self-rbfe/cmet-2/002_ffengine/forcefield/CHEMBL3402749-500/L1.mol2
solute_2=loadmol2 /nfs/sheenam-d/self-rbfe/cmet-2/002_ffengine/forcefield/CHEMBL3402749-500/L1.mol2
translate solute_2 {  1.91 43.96 7.25 }
sys=combine {solute_0 solute_1 solute_2}
solvateBox sys TIP3PBOX 10
addions sys K+ 0
addions sys Cl- 0
check sys
saveamberparm sys protein-CHEMBL3402749-500-CHEMBL3402749-500.prmtop protein-CHEMBL3402749-500-CHEMBL3402749-500.inpcrd
savePdb sys protein-CHEMBL3402749-500-CHEMBL3402749-500.pdb
quit
