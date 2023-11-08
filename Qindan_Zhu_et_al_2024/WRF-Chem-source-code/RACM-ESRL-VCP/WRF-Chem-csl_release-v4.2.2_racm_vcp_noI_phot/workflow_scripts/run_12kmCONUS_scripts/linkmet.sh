##
ln -sf /scratch2/BMC/rcm1/qzhu/wrfchem/WPSV4.0_o3/met_em.d01.2021-06-* .
ln -sf /scratch2/BMC/rcm1/qzhu/wrfchem/WPSV4.0_o3/met_em.d01.2021-05-* .
#ln -sf /scratch2/BMC/rcm1/wrfchem_input/met_em/met1dom_CONUS_2021/met_em.d01.2021-07* .
#ln -fs /scratch2/BMC/rcm1/kyu/sunvex21/WPSV4.0/met_em.d01.2021-06* .
## Link run directory and main model executables
ln -fs /scratch2/BMC/rcm1/qzhu/wrfchem/code/github/csl_release-v4.2.2_racm_vcp_noI_phot/run/* .
# We specify our own namelist so remove the default
rm namelist.input*
# Relink the executables so clear from main directory
ln -fs /scratch2/BMC/rcm1/qzhu/wrfchem/code/github/csl_release-v4.2.2_racm_vcp_noI_phot/main/wrf.exe .
ln -fs /scratch2/BMC/rcm1/qzhu/wrfchem/code/github/csl_release-v4.2.2_racm_vcp_noI_phot/main/ndown.exe .
ln -fs /scratch2/BMC/rcm1/qzhu/wrfchem/code/github/csl_release-v4.2.2_racm_vcp_noI_phot/main/real.exe .
ln -fs /scratch2/BMC/rcm1/qzhu/wrfchem/code/github/csl_release-v4.2.2_racm_vcp_noI_phot/main/tc.exe . 
## Link biogenic emissions file
ln -sf /scratch2/BMC/rcm1/rhs/wrfchem/emissions/beis/season/US12k_vcp_urban2_summer/txt2ntcdf/wrfbiochemi_d01 wrfbiochemi_d01
cp wrfbiochemi_d01 tmpbio.nc
#ln -sf /scratch2/BMC/rcm1/rhs/wrfchem/emissions/beis/conus12k_berkvcp_urban_2/wrfbiochemi_d01 wrfbiochemi_d01
#ln -fs /scratch2/BMC/rcm1/rhs/wrfchem/emissions/beis/conus12k_vcp_urban/wrfbiochemi_d01 wrfbiochemi_d01
## Link TUV file
ln -fs /scratch2/BMC/rcm1/rhs/wrfchem/emissions/phot_data/TUV/TUV.phot/* .
ln -fs /scratch2/BMC/rcm1/qzhu/wrfchem/code/github/CSL_chembc_RACM_ESRL/wrfchembc wrfchembc
#ln -fs /scratch2/BMC/rcm1/qzhu/wrfchem/wrfchembc/combine/wrfchembc wrfchembc
#ln -fs /scratch1/BMC/rcm2/jhe/prep/wrfchembc/combine/wrfchembc wrfchembc
