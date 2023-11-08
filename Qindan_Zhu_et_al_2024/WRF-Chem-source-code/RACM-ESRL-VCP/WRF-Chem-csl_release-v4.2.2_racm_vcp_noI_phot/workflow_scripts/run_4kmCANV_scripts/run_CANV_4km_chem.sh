#!/bin/bash
# Script to run real.exe, wrf.exe with varying namelist
#
# Load modules
module purge
module load intel/18.0.5.274
module load impi/2018.4.274
module load netcdf/4.6.1
module load hdf5/1.10.4
module load pnetcdf/1.11.2
module load nco/4.9.1

# Use let, expr functions, handle better numbers starting "0"
# Set up paths to shell commands
###############################################################################
# The working directory (should be the directory in which this file resides):
execdir=$WRF_CHEM_ROOT                       # directory where the executable is located
realdir=${WRF_CHEM_ROOT}$"Real/"
ndowndir=${WRF_CHEM_ROOT}$"Ndown/"
real2dir=${WRF_CHEM_ROOT}$"Real2/"           # directory where real will be run treating the 4km domain as the parent
path_out=${WRF_CHEM_ROOT}$"Output/"

echo Home directory:
echo $PWD  # It starts at home directory

#JianHe: setup directories and link executable files
if [ ! -d $execdir ]; then
    mkdir $execdir
    mkdir $realdir
    mkdir $ndowndir
    mkdir $real2dir
    mkdir $path_out
    mkdir $path_out"chem_res"

    cp $casedir"namelist.base" $execdir"namelist.base"
    cp $casedir"linkwrf.sh" $execdir"linkwrf.sh"
    cd $execdir     # make sure to go to the working directory
    ./linkwrf.sh    # link WRF files under output directory

    cp $casedir"namelist.real" $execdir"namelist.real"
    cp $casedir"linkwrf.sh" $realdir"linkwrf.sh"
    cd $realdir     # make sure to go to the working directory
    ./linkwrf.sh    # link WRF files under output directory

    cp $casedir"namelist.ndown" $execdir"namelist.ndown"
    cp $casedir"linkwrf.sh" $ndowndir"linkwrf.sh"
    cd $ndowndir     # make sure to go to the working directory
    ./linkwrf.sh    # link WRF files under output directory

    cp $casedir"namelist.real2" $execdir"namelist.real2"
    cp $casedir"linkwrf.sh" $real2dir"linkwrf.sh"
    cd $real2dir     # make sure to go to the working directory
    ./linkwrf.sh    # link WRF files under output directory
fi

#runid=test_wrf                         # run ID parameter; match -N line above
cd $execdir

###############################################################################
# START_TIME is like "2013-02-01_00"
year=$(echo $START_TIME | cut -c1-4)
month=$(echo $START_TIME | cut -c6-7)
day=$(echo $START_TIME | cut -c9-10)
hr=$(echo $START_TIME | cut -c12-13)

run_days=1
run_hours=6

END_TIME=$(date -d "${year}${month}${day} ${hr} + ${run_days} day + ${run_hours} hour" +'%Y-%m-%d_%H')
DOW=$(date -d "${year}${month}${day}" +'%u') # Day Of the Week: 1=Monday, 2=Tuesday, ..., 7=Sunday

end_year=$(echo $END_TIME | cut -c1-4)
end_month=$(echo $END_TIME | cut -c6-7)
end_day=$(echo $END_TIME | cut -c9-10)
end_hr=$(echo $END_TIME | cut -c12-13)
#
chem_rest=1
# for first day, initialization from the idealized profile
if [ $day == "25" ] && [ $month == "05" ]; then
  chem_rest=0
fi

# Bert V., when linking files, make sure the exist first
function check_and_link {
  if [ -f ${1} ]
  then
    ln -fs ${1} ${2}
  else
    echo ERROR: ${1} not found
    exit
  fi
}

if [ "$task_no" -lt 1 ]; then
    echo Task number does not correspond to an existing task: task_no = $task_no
fi

# Bert V., get season to link biogenic emissions
season=winter
if [ "$month" -gt 2 ] && [ "$month" -le 5 ]; then
    season=spring
fi
if [ "$month" -gt 5 ] && [ "$month" -le 8 ]; then
    season=summer
fi
if [ "$month" -gt 8 ] && [ "$month" -le 11 ]; then
    season=fall
fi


###############################################################################
cat > namelist.time << __EOF
&time_control
run_days                            = ${run_days},
run_hours                           = ${run_hours},
run_minutes                         = 0,
run_seconds                         = 0,

start_year                          = ${year},       ${year}, 2000,
start_month                         = ${month},      ${month},   01,
start_day                           = ${day},        ${day},   24,
start_hour                          = ${hr},         ${hr},   12,
start_minute                        = 00,          00,   00,
start_second                        = 00,          00,   00,

end_year                            = ${end_year},   ${end_year},   2000,
end_month                           = ${end_month},  ${end_month},  01,
end_day                             = ${end_day},    ${end_day},    24,
end_hour                            = ${end_hr},     ${end_hr},   12,
end_minute                          = 00,          00,   00,
end_second                          = 00,          00,   00,
force_use_old_data                  = .true.,
__EOF

#
cat > chem_input.txt << __EOF
chem_in_opt                         = $chem_rest,   $chem_rest,
/
__EOF

###############################################################################
if [ "$task_no" -eq 1 ]; then
    rm -f ${realdir}namelist.input
    rm -f ${realdir}met_em.d*
    echo "link met_em files"

    # the NAM files are available every 6 hours
    for hh in $(seq 0 6 $(($run_days*24+$run_hours)) )
    do
        met_em_date=$(date -d "${year}${month}${day} ${hr} + ${hh} hour" +'%Y-%m-%d_%H')
        # Pay attention when doing one-was nesting to rename the domain from the WPS format to d01 for WRF-Chem
        check_and_link ${met12kdir}met_em.d01.${met_em_date}:00:00.nc ${realdir}met_em.d01.${met_em_date}:00:00.nc
        check_and_link ${met4kdir}met_em.d02.${met_em_date}:00:00.nc ${realdir}met_em.d02.${met_em_date}:00:00.nc
    done

    #JianHe: copy wrfbiochemi file to run directory and assign timestamp required by io_style_emissions=2
    rm -f ${realdir}"wrfbiochemi*"
    echo "link wrfbio files"

    echo $month
    # for 12k CONUS domain
    echo link wrfbio to ${season} file for parent
    echo ${bioemisdir}"US12k_vcp_urban2_summer/txt2ntcdf/wrfbiochemi_d01"
    cp ${bioemisdir}"US12k_vcp_urban2_summer/txt2ntcdf/wrfbiochemi_d01" ${realdir}"tmpbio.nc"

    ncap2 -s "Times=\"${year}-${month}-${day}_00:00:00,\"" ${realdir}"tmpbio.nc" -O ${realdir}"wrfbiochemi_d01"
    rm -f ${realdir}"tmpbio.nc"
    echo "Current timestamp is assigned to wrfbiochemi_d01"

    # for 4k CA domain
    echo link wrfbio to ${season} file for child
    echo ${bioemisdir}"ca4k_vcp_urban2_summer/txt2ntcdf/wrfbiochemi_d01"
    cp ${bioemisdir}"ca4k_vcp_urban2_summer/txt2ntcdf/wrfbiochemi_d01" ${realdir}"tmpbio.nc"

    ncap2 -s "Times=\"${year}-${month}-${day}_00:00:00,\"" ${realdir}"tmpbio.nc" -O ${realdir}"wrfbiochemi_d02"
    rm -f ${realdir}"tmpbio.nc"
    echo "Current timestamp is assigned to wrfbiochemi_d02"

    cat namelist.time namelist.real chem_input.txt >${realdir}"namelist.input"

    cd ${realdir}
    rm -f wrfinput* wrfbdy* wrflowinp* rsl.*
    srun ${realdir}"real.exe"

    cp -p wrfinput_d02 $ndowndir"wrfndi_d02"

    echo 'real.exe is done'
fi

###############################################################################
# JianHe: NDOWN
if [ "$task_no" -eq 2 ]; then
    rm -f ${ndowndir}"namelist.input"
    rm -f ${ndowndir}"wrfbiochemi*"
    echo "link wrfbio files"

    # for 4k CA domain
    echo link wrfbio to ${season} file
    echo ${bioemisdir}"ca4k_vcp_urban2_summer/txt2ntcdf/wrfbiochemi_d01"
    cp ${bioemisdir}"ca4k_vcp_urban2_summer/txt2ntcdf/wrfbiochemi_d01" ${ndowndir}"tmpbio.nc"

    ncap2 -s "Times=\"${year}-${month}-${day}_00:00:00,\"" ${ndowndir}"tmpbio.nc" -O ${ndowndir}"wrfbiochemi_d02"
    rm -f ${ndowndir}"tmpbio.nc"
    echo "Current timestamp is assigned to wrfbiochemi_d02"
#
    cat namelist.time namelist.ndown chem_input.txt >${ndowndir}"namelist.input"

    cd ${ndowndir}
    rm -f wrfinput* rsl.* wrfout_d01_*
    ln -sf ${chem12kdir}$month$day/wrfout_d01_* . 

    srun  ${ndowndir}"ndown.exe"

    echo 'ndown is done'
fi

###############################################################################
# Bert V, run real a second time to get HRRR variables for WRF input files
if [ "$task_no" -eq 3 ]; then
    rm -f ${real2dir}namelist.input
    rm -f ${real2dir}met_em.d*
    echo "link met_em files"

    for hh in $(seq 0 $(($run_days*24+$run_hours)) )
    do
        met_em_date=$(date -d "${year}${month}${day} ${hr} + ${hh} hour" +'%Y-%m-%d_%H')
        met_em_month=$(echo $met_em_date | cut -c6-7)
        # Pay attention when doing one-was nesting to rename the domain from the WPS format to d01 for WRF-Chem
        check_and_link ${metdir}${met_em_month}/met_em.d01.${met_em_date}:00:00.nc ${real2dir}met_em.d01.${met_em_date}:00:00.nc
    done

    rm -f wrfbiochemi*

    # for 4k CA domain
    echo link wrfbio to ${season} file
    echo ${bioemisdir}"ca4k_vcp_urban2_summer/txt2ntcdf/wrfbiochemi_d01"
    cp ${bioemisdir}"ca4k_vcp_urban2_summer/txt2ntcdf/wrfbiochemi_d01" ${real2dir}"tmpbio.nc"

    ncap2 -s "Times=\"${year}-${month}-${day}_00:00:00,\"" ${real2dir}"tmpbio.nc" -O ${real2dir}"wrfbiochemi_d01"
    rm -f ${real2dir}"tmpbio.nc"
    echo "Current timestamp is assigned to wrfbiochemi_d01"

    if [ "$chem_rest" -eq 0 ]
    then
      echo first date, get only meteorology from Real2
      cat namelist.time namelist.real2 chem_input.txt >${real2dir}"namelist.input"
    else
      echo Get both meteorology and chemistry from Real2
      cat namelist.time namelist.base chem_input.txt >${real2dir}"namelist.input"
    fi

    cd ${real2dir}
    rm -f wrfinput* wrfbdy* wrflowinp* wrf_chem_input* rsl.*
    
    if [ "$chem_rest" -eq 1 ]
    then
      echo Link output from previous run for chemical ICs
      check_and_link $path_out"chem_res/wrfout_d01_"$year"-"$month"-"$day"_00:00:00" ${real2dir}"wrf_chem_input_d01"
    fi

    srun ${real2dir}"real.exe"
    echo "real2 is done"

fi

###############################################################################
#JianHe: assign timestamp into wrfchemi files required by io_style_emissions = 2
if [ "$task_no" -eq 4 ]; then
    cd $execdir
    echo $task_no

    rm -f namelist.input rsl*
    rm -f ${execdir}met_em.d*
    echo "link met_em files"

    for hh in $(seq 0 $(($run_days*24+$run_hours)) )
    do
        met_em_date=$(date -d "${year}${month}${day} ${hr} + ${hh} hour" +'%Y-%m-%d_%H')
        met_em_month=$(echo $met_em_date | cut -c6-7)
        # Pay attention when doing one-was nesting to rename the domain from the WPS format to d01 for WRF-Chem
        check_and_link ${metdir}${met_em_month}/met_em.d01.${met_em_date}:00:00.nc ${execdir}met_em.d01.${met_em_date}:00:00.nc
    done

    rm -f ${execdir}"wrfbiochemi*"
    echo "link wrfbio files"

    # for 4k CA domain
    echo link wrfbio to ${season} file
    echo ${bioemisdir}"ca4k_vcp_urban2_summer/txt2ntcdf/wrfbiochemi_d01"
    cp ${bioemisdir}"ca4k_vcp_urban2_summer/txt2ntcdf/wrfbiochemi_d01" ${execdir}"tmpbio.nc"

    ncap2 -s "Times=\"${year}-${month}-${day}_00:00:00,\"" ${execdir}"tmpbio.nc" -O ${execdir}"wrfbiochemi_d01"
    rm -f ${execdir}"tmpbio.nc"
    echo "Current timestamp is assigned to wrfbiochemi_d01"

    # Anthropogenic emissions
    rm -f ${execdir}"wrfchemi*"
    echo "link wrfchemi files"

    if [ "$DOW" -lt 5 ]; then
        echo "start and end day are Weekdays"
        cp ${emisdir}"Month${month}/weekdy/wrfchemi_00z_d01" ${execdir}"tmp-day1.00z.nc"
        cp ${emisdir}"Month${month}/weekdy/wrfchemi_12z_d01" ${execdir}"tmp-day1.12z.nc"
        cp ${emisdir}"Month${end_month}/weekdy/wrfchemi_00z_d01" ${execdir}"tmp-day2.00z.nc"
    fi
    if [ "$DOW" -eq 5 ]; then
        echo "start day is Friday"
        cp ${emisdir}"Month${month}/weekdy/wrfchemi_00z_d01" ${execdir}"tmp-day1.00z.nc"
        cp ${emisdir}"Month${month}/weekdy/wrfchemi_12z_d01" ${execdir}"tmp-day1.12z.nc"
        cp ${emisdir}"Month${end_month}/satdy/wrfchemi_00z_d01" ${execdir}"tmp-day2.00z.nc"
    fi
    if [ "$DOW" -eq 6 ]; then
        echo "start day is Saturday"
        cp ${emisdir}"Month${month}/satdy/wrfchemi_00z_d01" ${execdir}"tmp-day1.00z.nc"
        cp ${emisdir}"Month${month}/satdy/wrfchemi_12z_d01" ${execdir}"tmp-day1.12z.nc"
        cp ${emisdir}"Month${end_month}/sundy/wrfchemi_00z_d01" ${execdir}"tmp-day2.00z.nc"
    fi
    if [ "$DOW" -eq 7 ]; then
        echo "start day is Sunday"
        cp ${emisdir}"Month${month}/sundy/wrfchemi_00z_d01" ${execdir}"tmp-day1.00z.nc"
        cp ${emisdir}"Month${month}/sundy/wrfchemi_12z_d01" ${execdir}"tmp-day1.12z.nc"
        cp ${emisdir}"Month${end_month}/weekdy/wrfchemi_00z_d01" ${execdir}"tmp-day2.00z.nc"
    fi

    ncap2 -s "Times=\"${year}-${month}-${day}_00:00:00${year}-${month}-${day}_01:00:00${year}-${month}-${day}_02:00:00${year}-${month}-${day}_03:00:00${year}-${month}-${day}_04:00:00${year}-${month}-${day}_05:00:00${year}-${month}-${day}_06:00:00${year}-${month}-${day}_07:00:00${year}-${month}-${day}_08:00:00${year}-${month}-${day}_09:00:00${year}-${month}-${day}_10:00:00${year}-${month}-${day}_11:00:00,\"" ${execdir}"tmp-day1.00z.nc" -O ${execdir}"wrfchemi_d01_${year}-${month}-${day}_00:00:00"

    ncap2 -s "Times=\"${year}-${month}-${day}_12:00:00${year}-${month}-${day}_13:00:00${year}-${month}-${day}_14:00:00${year}-${month}-${day}_15:00:00${year}-${month}-${day}_16:00:00${year}-${month}-${day}_17:00:00${year}-${month}-${day}_18:00:00${year}-${month}-${day}_19:00:00${year}-${month}-${day}_20:00:00${year}-${month}-${day}_21:00:00${year}-${month}-${day}_22:00:00${year}-${month}-${day}_23:00:00,\"" ${execdir}"tmp-day1.12z.nc" -O ${execdir}"wrfchemi_d01_${year}-${month}-${day}_12:00:00"

    ncap2 -s "Times=\"${end_year}-${end_month}-${end_day}_00:00:00${end_year}-${end_month}-${end_day}_01:00:00${end_year}-${end_month}-${end_day}_02:00:00${end_year}-${end_month}-${end_day}_03:00:00${end_year}-${end_month}-${end_day}_04:00:00${end_year}-${end_month}-${end_day}_05:00:00${end_year}-${end_month}-${end_day}_06:00:00${end_year}-${end_month}-${end_day}_07:00:00${end_year}-${end_month}-${end_day}_08:00:00${end_year}-${end_month}-${end_day}_09:00:00${end_year}-${end_month}-${end_day}_10:00:00${end_year}-${end_month}-${end_day}_11:00:00,\"" ${execdir}"tmp-day2.00z.nc" -O ${execdir}"wrfchemi_d01_${end_year}-${end_month}-${end_day}_00:00:00"
    
    rm -f ${execdir}"tmp-day1.00z.nc" ${execdir}"tmp-day1.12z.nc" ${execdir}"tmp-day2.00z.nc"
    echo "Current timestamp is assigned to wrfchemi files"

#
    cat namelist.time namelist.base chem_input.txt >$execdir"namelist.input"

# chem_opt = 113
    #chem_sps=(so2 sulf no2 no o3 hno3 h2o2 ald hcho op1 op2 paa ora1 ora2 nh3 n2o5 no3 pan hc3 hc5 hc8 eth co ete olt oli tol xyl aco3 hono hno4 ket gly mgly onit csl iso co2 ch4 hket api lim dien macr acd ace act bald ben dcb1 dcb2 dcb3 eoh epx eteg ishpa ishpb ishpd ihnd ihnb inheb inhed inpd inpb icn r4n r4no nh4co3 mahp mct mek moh mpan mvk per1 per2 phen ppn rco3 roh uald xyo glyc isopnd isopnb uhc hac macrn mvkn propnn vrp iepoxa iepoxb iepoxd iap dhmob moba ethln isnp pyac hpald imonit honit monit donit aonit tonit utonit tonin utonin tonih mpn prog glycr ipoh sesq mbo cvasoa1 cvasoa2 cvasoa3 cvasoa4 cvbsoa1 cvbsoa2 cvbsoa3 cvbsoa4 ho ho2 so4aj so4ai nh4aj nh4ai no3aj no3ai naaj naai claj clai asoa1j asoa1i asoa2j asoa2i asoa3j asoa3i asoa4j asoa4i bsoa1j bsoa1i bsoa2j bsoa2i bsoa3j bsoa3i bsoa4j bsoa4i orgpaj orgpai ecj eci p25j p25i antha seas soila nu0 ac0 corn)
    # Bert V., combine files from Ndown and Real2
    # chem_opt = 108
    chem_sps=(so2 sulf no2 no o3 hno3 h2o2 ald hcho op1 op2 paa ora1 ora2 nh3 n2o5 no3 pan hc3 hc5 hc8 eth co ete olt oli tol xyl aco3 tpan hono hno4 ket gly mgly dcb onit csl iso moh eoh eteg prog glyc ipoh act co2 ch4 udd hket api lim dien macr hace ishp ison mahp mpan nald sesq mbo cvasoa1 cvasoa2 cvasoa3 cvasoa4 cvbsoa1 cvbsoa2 cvbsoa3 cvbsoa4 ho ho2 so4aj so4ai nh4aj nh4ai no3aj no3ai naaj naai claj clai asoa1j asoa1i asoa2j asoa2i asoa3j asoa3i asoa4j asoa4i bsoa1j bsoa1i bsoa2j bsoa2i bsoa3j bsoa3i bsoa4j bsoa4i orgpaj orgpai ecj eci p25j p25i antha seas soila nu0 ac0 corn)

    # chem_opt = 107 (no sesquiterpenes, mbo, and all soa species)
    # chem_sps=(so2 sulf no2 no o3 hno3 h2o2 ald hcho op1 op2 paa ora1 ora2 nh3 n2o5 no3 pan hc3 hc5 hc8 eth co ete olt oli tol xyl aco3 tpan hono hno4 ket gly mgly dcb onit csl iso co2 ch4 udd hket api lim dien macr hace ishp ison mahp mpan nald ho ho2 so4aj so4ai nh4aj nh4ai no3aj no3ai naaj naai claj clai orgpaj orgpai ecj eci p25j p25i antha seas soila nu0 ac0 corn)
    bdy_vars=''
    chm_vars=''
    for sp in ${chem_sps[@]}
    do
      chm_vars=${chm_vars}${sp},
      for suffix in BXS BXE BYS BYE BTXS BTXE BTYS BTYE
      do
        bdy_vars=${bdy_vars}${sp}_${suffix},
      done
    done

    # remove last ','
    bdy_vars=${bdy_vars::-1}
    chm_vars=${chm_vars::-1}

    rm -f wrflowinp_d01 wrfinput_d01 wrfbdy_d01

    echo copy wrfinput files from Real2
    cp ${real2dir}wrflowinp_d01 ${execdir}.
    cp ${real2dir}wrfinput_d01 ${execdir}.
    cp ${real2dir}wrfbdy_d01 ${execdir}.
    
    echo add chemical variables to wrfbdy file
    ncks -A -v ${bdy_vars} ${ndowndir}wrfbdy_d02 wrfbdy_d01
    ncks -A -v ${chm_vars} ${ndowndir}wrfbdy_d02 wrfbdy_d01

    if [ "$chem_rest" -eq 0 ]
    then
      echo first date, get initial chemistry conditions from Ndown
      ncks -A -v ${chm_vars} ${ndowndir}wrfinput_d02 wrfinput_d01
    fi


    rm -f rsl.*

    echo run wrf-chem
    srun ${execdir}"wrf.exe" 

    cp -p "wrfout_d01_"$end_year"-"$end_month"-"$end_day"_00:00:00" $path_out"chem_res"
    mkdir $path_out$month$day
    mv wrfout_* $path_out$month$day
    mv wrfinput_d01  $path_out$month$day"/wrfinput_d01_"$year"-"$month"-"$day"_"$hr":00:00"
    mv wrfbdy_d01  $path_out$month$day"/wrfbdy_d01_"$year"-"$month"-"$day"_"$hr":00:00"
    mv wrflowinp_d01  $path_out$month$day"/wrflowinp_d01_"$year"-"$month"-"$day"_"$hr":00:00"
    mv namelist.input  $path_out$month$day"/namelist_"$year"-"$month"-"$day"_"$hr":00:00"
    mv rsl.error.0000  $path_out$month$day"/rslerr_"$year"-"$month"-"$day"_"$hr":00:00"
    mv rsl.out.0000  $path_out$month$day"/rslout_"$year"-"$month"-"$day"_"$hr":00:00"

    echo 'wrf.exe is done'
    date
fi
#
#else
# Check if the run is a success and more log
#set success = 0
#set lastline = `tail -1 rsl.error.0000`
#set stamp = ${end_year}-${end_month}-${end_day}_${end_hr}:00:00
#if ( `echo $lastline` == `echo d01 $stamp wrf: SUCCESS COMPLETE WRF` ) then
#    echo $lastline
#    set success = 1
#else
#    echo 'WRF run was unsuccessful! '
#    echo 'last line of rsl.error.0000: '
#    echo $lastline

#    exit 1
#endif
#
##mv wrfout_* $path_out

#
#mv wrfinput_d02  $path_out"wrfinput_d02_"$year"-"$month0"-"$day0"_"$hr":00:00"
#mv wrf_diag_* $path_out
#
echo 'End of the cycle: '$START_TIME
#
#date
exit 0
