#!/bin/ksh --login

module purge
module load intel/18.0.5.274
module load rocoto/1.3.1
#module load slurm

/apps/rocoto/1.3.1/bin/rocotorun -w /home/Qindan.Zhu/sunvex-run-scripts/run_CONUS_fv19_BEIS_1.0xISO_RACM_v4.2.2_racm_vcp_noI_phot_4km/run_CANV_4km.xml -d /home/Qindan.Zhu/sunvex-run-scripts/run_CONUS_fv19_BEIS_1.0xISO_RACM_v4.2.2_racm_vcp_noI_phot_4km/Logs/workflow_RACM.store -v >>/home/Qindan.Zhu/sunvex-run-scripts/run_CONUS_fv19_BEIS_1.0xISO_RACM_v4.2.2_racm_vcp_noI_phot_4km/Logs/ksh_job.log 2>&1

exit 0
