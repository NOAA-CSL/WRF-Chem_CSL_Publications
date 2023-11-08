##
# Link run directory and main model executables
ln -fs /scratch2/BMC/rcm1/qzhu/wrfchem/code/github/csl_release-v4.2.2_racm_vcp_noI_phot/run/* .
# We specify our own namelist so remove the default
rm namelist.input*
# Relink the executables so clear from main directory
ln -fs /scratch2/BMC/rcm1/qzhu/wrfchem/code/github/csl_release-v4.2.2_racm_vcp_noI_phot/main/wrf.exe .
ln -fs /scratch2/BMC/rcm1/qzhu/wrfchem/code/github/csl_release-v4.2.2_racm_vcp_noI_phot/main/ndown.exe .
ln -fs /scratch2/BMC/rcm1/qzhu/wrfchem/code/github/csl_release-v4.2.2_racm_vcp_noI_phot/main/real.exe .
ln -fs /scratch2/BMC/rcm1/qzhu/wrfchem/code/github/csl_release-v4.2.2_racm_vcp_noI_phot/main/tc.exe . 
# Link TUV file
ln -fs /scratch2/BMC/rcm1/rhs/wrfchem/emissions/phot_data/TUV/TUV.phot/* .
ln -fs /scratch2/BMC/rcm1/qzhu/wrfchem/code/github/CSL_chembc_RACM_ESRL/wrfchembc wrfchembc
#ln -fs /scratch2/BMC/rcm1/qzhu/wrfchem/wrfchembc/combine/wrfchembc wrfchembc
#ln -fs /scratch1/BMC/rcm2/jhe/prep/wrfchembc/combine/wrfchembc wrfchembc
