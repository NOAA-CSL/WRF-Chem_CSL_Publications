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

#echo $PWD  # It starts at home directory

#JianHe: setup directories and link executable files
if [ ! -d $execdir ]; then
    mkdir $execdir
    if [ ! -d $path_out ]; then
        mkdir $path_out
        if [ ! -d $path_out"chem_res" ]; then
            mkdir $path_out"chem_res"
        fi
    fi

    cp $casedir"namelist.base" $execdir"namelist.base"
    cp $casedir"linkwrf.sh" $execdir"linkwrf.sh"
    cd $execdir     # make sure to go to the working directory
    ./linkwrf.sh    # link WRF files under output directory
fi

#runid=test_wrf                         # run ID parameter; match -N line above
cd $execdir

###############################################################################
# START_TIME is like "2013-02-01_00"
year=$(echo $START_TIME | cut -c1-4)
month=$(echo $START_TIME | cut -c6-7)
month0=$month
day=$(echo $START_TIME | cut -c9-10)
day0=$day
hr=$(echo $START_TIME | cut -c12-13)
#
year=$year
end_year=$year
#end_hr=$hr
#
run_days=1
run_hours=0
#
chem_rest=1
# for first day, initialization from the idealized profile
if [ $day == "25" ] && [ $month == "05" ]; then
  chem_rest=0
fi
#
mmdde=(31 28 31 30 31 30 31 31 30 31 30 31)
let "leap_f= $year % 4"
#echo $leap_f
if [ "$leap_f" -eq 0 ]; then
   mmdde=(31 29 31 30 31 30 31 31 30 31 30 31)
fi
#

###############################################################################
# Month calculation
if [ ${month:0:1} == "0" ]; then
   end_month=${month:1}
   month=${month:1}
fi
end_month=$month
mm=$(($month-1))
#
if [ ${day:0:1} == "0" ]; then
   day=${day:1}
fi
end_day=$((day+1))
if [ ${day:0:1} == "0" ]; then
   end_day=${day:1}
   end_day=$[$end_day+1]
fi
if [ "$end_day" -lt 10 ]
then
   end_day="0"$end_day
fi
#
if [ "$end_day" -gt "${mmdde[$mm]}" ]; then
    end_day="01"
    end_month=$[$end_month + 1]
    if [ "$end_month" -gt 12 ]; then
        end_month="01"
        end_year=$[$year + 1]
    fi
fi
#
if [ "$end_month" -lt 10 ] && [ "$end_month" != 01 ]
then
        end_month="0"$end_month
fi
#
echo end_year= $end_year
echo end_month= $end_month
echo end_day= $end_day
#echo end_hr= $end_hr
#
if [ "$task_no" -lt 1 ]; then
    echo $task_no
    end_hour=06
fi
#
###############################################################################
cat > namelist.time << __EOF
&time_control
run_days                            = 0,
run_hours                           = 30,
run_minutes                         = 0,
run_seconds                         = 0,
start_year                          = $year,       $year, 2000,
start_month                         = $month0,     $month0,   01,
start_day                           = $day0,       $day0,   24,
start_hour                          = 00,          00,   12,
start_minute                        = 00,          00,   00,
start_second                        = 00,          00,   00,
end_year                            = $end_year,   $end_year,   2000,
end_month                           = $end_month,  $end_month,  01,
end_day                             = $end_day,    $end_day,    24,
end_hour                            = 06,          06,   12,
end_minute                          = 00,          00,   00,
end_second                          = 00,          00,   00,
force_use_old_data                  = .true.,
__EOF

###############################################################################
if [ "$task_no" -eq 1 ]; then
#JianHe: link met_em files
    rm -f ${execdir}"met_em.d01.*"

    echo "link met_em files"

    ln -sf ${metdir}"met_em.d01.${year}-${month0}-${day0}_00:00:00.nc" ${execdir}"met_em.d01.${year}-${month0}-${day0}_00:00:00.nc"
    ln -sf ${metdir}"met_em.d01.${year}-${month0}-${day0}_06:00:00.nc" ${execdir}"met_em.d01.${year}-${month0}-${day0}_06:00:00.nc"
    ln -sf ${metdir}"met_em.d01.${year}-${month0}-${day0}_12:00:00.nc" ${execdir}"met_em.d01.${year}-${month0}-${day0}_12:00:00.nc"
    ln -sf ${metdir}"met_em.d01.${year}-${month0}-${day0}_18:00:00.nc" ${execdir}"met_em.d01.${year}-${month0}-${day0}_18:00:00.nc"
    ln -sf ${metdir}"met_em.d01.${end_year}-${end_month}-${end_day}_00:00:00.nc" ${execdir}"met_em.d01.${end_year}-${end_month}-${end_day}_00:00:00.nc"
    ln -sf ${metdir}"met_em.d01.${end_year}-${end_month}-${end_day}_06:00:00.nc" ${execdir}"met_em.d01.${end_year}-${end_month}-${end_day}_06:00:00.nc"
    ln -sf ${metdir}"met_em.d01.${end_year}-${end_month}-${end_day}_12:00:00.nc" ${execdir}"met_em.d01.${end_year}-${end_month}-${end_day}_12:00:00.nc"
    ln -sf ${metdir}"met_em.d01.${end_year}-${end_month}-${end_day}_18:00:00.nc" ${execdir}"met_em.d01.${end_year}-${end_month}-${end_day}_18:00:00.nc"

#JianHe: copy wrfbiochemi file to run directory and assign timestamp required by io_style_emissions=2
    rm -f wrfbiochemi*
    
    echo $month
    if [ "$month" -le 2 ] || [ "$month" == 12 ]; then
        echo "link wrfbio to winter file"
        echo ${bioemisdir}"modUrban_conus12k_vcp_0.75xisop_winter/txt2ntcdf/wrfbiochemi_d01"
        cp ${bioemisdir}"modUrban_conus12k_vcp_0.75xisop_winter/txt2ntcdf/wrfbiochemi_d01" ${execdir}"tmpbio.nc"
    fi
    if [ "$month" -gt 2 ] && [ "$month" -le 5 ]; then
        echo "link wrfbio to spring file"
        echo ${bioemisdir}"modUrban_conus12k_vcp_0.75xisop_spring/txt2ntcdf/wrfbiochemi_d01"
        cp ${bioemisdir}"modUrban_conus12k_vcp_0.75xisop_spring/txt2ntcdf/wrfbiochemi_d01" ${execdir}"tmpbio.nc"
    fi
    if [ "$month" -gt 5 ] && [ "$month" -le 8 ]; then
        echo "link wrfbio to summer file"
        echo ${bioemisdir}"US12k_vcp_urban2_summer/txt2ntcdf/wrfbiochemi_d01"
        cp ${bioemisdir}"US12k_vcp_urban2_summer/txt2ntcdf/wrfbiochemi_d01" ${execdir}"tmpbio.nc"
    fi
    if [ "$month" -gt 8 ] && [ "$month" -le 11 ]; then
        echo "link wrfbio to fall file"
        echo ${bioemisdir}"modUrban_conus12k_vcp_0.75xisop_fall/txt2ntcdf/wrfbiochemi_d01"
        cp ${bioemisdir}"modUrban_conus12k_vcp_0.75xisop_fall/txt2ntcdf/wrfbiochemi_d01" ${execdir}"tmpbio.nc"
    fi

    ncap2 -s "Times=\"${year}-${month0}-${day0}_00:00:00,\"" ${execdir}"tmpbio.nc" -O ${execdir}"wrfbiochemi_d01"
    rm -f ${execdir}"tmpbio.nc"
    echo "Current timestamp is assigned to wrfbiochemi_d01"

#
cat > chem_input.txt << __EOF
chem_in_opt                         = $chem_rest,   $chem_rest,
/
__EOF

     cat namelist.time namelist.base chem_input.txt >namelist.input
     rm -f wrfinput* wrfbdy* wrflowinp*  wrf_chem_input* rsl.*

     if [ "$chem_rest" -eq 1 ]; then
         ln -sf $path_out"chem_res/wrfout_d01_"$year"-"$month0"-"$day0"_00:00:00" ${execdir}"/wrf_chem_input_d01"
     fi

     srun ${realdir}"real.exe"
     echo 'real.exe is done'
fi

###############################################################################
# JianHe: Read IC/BC from RAQMS first, then read from AM4 for CH4
if [ "$task_no" -eq 2 ]; then
cat > chem_input.txt << __EOF
chem_in_opt                         = $chem_rest,   $chem_rest,
have_bcs_chem                       = .true.,   .true.,
have_ics_ch4                        = .true.,   .true.,
/
__EOF

#
     cat namelist.time namelist.base chem_input.txt >namelist.input

     # JianHe, choose data (i.e., instantaneous or climatological)
     bdy_input=1     # 1 = instantaneous; 2 = climatological

     # only read the IC for the first day
     if [ "$chem_rest" -eq 0 ]; then
          rm -f raqms.wrfchembc.namelist.input
          echo 'Processing both ICs and BCs from RAQMS'

          # the year of the raqms data
          if [ "$bdy_input" -eq 2 ]; then
              year_raq="climo"  # JianHe, we use climo monthly data based on 2019-2021

              echo 'raqmps climatology year month day', $year, $month0, $day0
              echo 'raqmps climatology next year month day', $end_year, $end_month, $end_day

              # link 00z, 06z, 12z, 18z files, and the 00z, 06z of the next day
              ln -sf ${indir_raqms}$year_raq"/uwhyb_climo_${month0}.nc" "uwhyb_"$month0$day0$year"00.chem.assim.nc"
              ln -sf ${indir_raqms}$year_raq"/uwhyb_climo_${month0}.nc" "uwhyb_"$month0$day0$year"06.chem.assim.nc"
              ln -sf ${indir_raqms}$year_raq"/uwhyb_climo_${month0}.nc" "uwhyb_"$month0$day0$year"12.chem.assim.nc"
              ln -sf ${indir_raqms}$year_raq"/uwhyb_climo_${month0}.nc" "uwhyb_"$month0$day0$year"18.chem.assim.nc"
              ln -sf ${indir_raqms}$year_raq"/uwhyb_climo_${end_month}.nc" "uwhyb_"$end_month$end_day$end_year"00.chem.assim.nc"
              ln -sf ${indir_raqms}$year_raq"/uwhyb_climo_${end_month}.nc" "uwhyb_"$end_month$end_day$end_year"06.chem.assim.nc"

              echo ${indir_raqms}$year_raq"/uwhyb_climo_${month0}.nc"

          else  # use instantaneous raqms data, make sure data exists
              year_raq=$year
              nyear_raq=${end_year}  

              echo 'raqmps year month day', ${year_raq}, $month0, $day0
              echo 'raqmps next year month day', $nyear_raq, $end_month, $end_day

              # link 00z, 06z, 12z, 18z files, and the 00z, 06z of the next day
              ln -sf ${indir_raqms}$year_raq"/"$month0"/uwhyb_"$month0"_"$day0"_"${year_raq}"_00Z.chem.assim.nc" "uwhyb_"$month0$day0$year"00.chem.assim.nc"
              ln -sf ${indir_raqms}$year_raq"/"$month0"/uwhyb_"$month0"_"$day0"_"${year_raq}"_06Z.chem.assim.nc" "uwhyb_"$month0$day0$year"06.chem.assim.nc"
              ln -sf ${indir_raqms}$year_raq"/"$month0"/uwhyb_"$month0"_"$day0"_"${year_raq}"_12Z.chem.assim.nc" "uwhyb_"$month0$day0$year"12.chem.assim.nc"
              ln -sf ${indir_raqms}$year_raq"/"$month0"/uwhyb_"$month0"_"$day0"_"${year_raq}"_18Z.chem.assim.nc" "uwhyb_"$month0$day0$year"18.chem.assim.nc"

              ln -sf ${indir_raqms}$nyear_raq"/"${end_month}"/uwhyb_"${end_month}"_"${end_day}"_"${nyear_raq}"_00Z.chem.assim.nc" "uwhyb_"${end_month}${end_day}${end_year}"00.chem.assim.nc"
              ln -sf ${indir_raqms}$nyear_raq"/"${end_month}"/uwhyb_"${end_month}"_"${end_day}"_"${nyear_raq}"_06Z.chem.assim.nc" "uwhyb_"${end_month}${end_day}${end_year}"06.chem.assim.nc"
              echo ${indir_raqms}$year_raq"/"$month0"/uwhyb_"$month0"_"$day0"_"${year_raq}"_"$hr"Z.chem.assim.nc"

	      #if [ -d "${indir_raqms}$nyear_raq"/"${end_month}"/"]; then
              #   echo 'file is exist'
              #fi
         fi
#
cat > raqms.wrfchembc.namelist.input << __EOF
&control
 dir_wrf = './'   ! Run directory, wrf data directory
 fnb_wrf  = 'wrfbdy_d01'                           ! WRF boundary condition data file
 fni_wrf  = 'wrfinput_d01'                         ! WRF initial condition data file
 chem_bc_opt = 2                                   ! Global Model data used: 1=MOZART, 2=RAQMS, 3=AM4
 dir_global = './'   ! Global model data directory
 fn_global  =  'uwhyb_$month0$day0$year$hr.chem.assim.nc'! Global model data file name
 do_bc = .true.
 do_ic = .true.
 nspec = 27                                         ! number of species listed by name in specname
 specname = 'so2',                                   ! name of chemical species to be added to boundary conditions
           'sulf','no2','no','o3','hno3',
           'h2o2','ald','hcho','n2o5','no3','pan','eth','co','ete','olt','hno4','mgly','onit','iso',
           'macr','op1','op2','mvk','mpan','ho','ho2'
 /
__EOF
#
          ./wrfchembc < raqms.wrfchembc.namelist.input > "raqms.bcic."$year"."$month0"."$day0".out"

          rm -f uwhyb_*chem.assim.nc

          echo 'raqms chem ic/bc is done'

          rm -f am4.wrfchembc.namelist.input
          echo 'Now processing both ICs and BCs from AM4 for CH4 only'
    
          # year for AM4 data
          if [ "$bdy_input" -eq 2 ]; then
              year_am4="climo"    #JianHe, we use climo data (2015-2017 average)
              ln -sf ${indir_am4}"GFDL_AM4_"${year_am4}"_"$month0".nc" "GFDL_AM4_"$year$month0$day0".nc"
              echo ${indir_am4}"GFDL_AM4_"${year_am4}"_"$month0".nc"

          else
              year_am4="2017" # we only have data upto 2017 
              ln -sf ${indir_am4}"GFDL_AM4_"${year_am4}"_"$month0".nc" "GFDL_AM4_"$year$month0$day0".nc"
              echo ${indir_am4}"GFDL_AM4_"${year_am4}"_"$month0".nc"
          fi

#
cat > am4.wrfchembc.namelist.input << __EOF
&control
 dir_wrf = './'   ! Run directory, wrf data directory
 fnb_wrf  = 'wrfbdy_d01'                           ! WRF boundary condition data file
 fni_wrf  = 'wrfinput_d01'                         ! WRF initial condition data file
 chem_bc_opt = 3                                   ! Global Model data used: 1=MOZART, 2=RAQMS, 3=AM4
 dir_global = './'   ! Global model data directory
 fn_global  = 'GFDL_AM4_$year$month0$day0.nc' ! Global model data file name
 do_bc = .true.
 do_ic = .true.
 nspec = 1                                         ! number of species listed by name in specname
 specname = 'ch4'    ! name of chemical species to be added to boundary conditions
 /
__EOF
#
          ./wrfchembc < am4.wrfchembc.namelist.input > am4."$year""$month0""$day0".out

          echo 'am4 chem ic/bc for ch4 is done'
          rm -f "GFDL_AM4_"$year$month0$day0".nc"
     fi
#
     if [ "$chem_rest" -eq 1 ]; then
          rm -f raqms.wrfchembc.namelist.input
          echo 'Processing BCs only'

          # the year of the raqms
          if [ "$bdy_input" -eq 2 ]; then
              year_raq="climo"  # JianHe, we use climo data based on 2019-2021
              echo 'raqmps climatology year month day', $year, $month0, $day0
              echo 'raqmps climatology next year month day', $end_year, $end_month, $end_day

              # link 00z, 06z, 12z, 18z files, and the 00z, 06z of the next day
              ln -sf ${indir_raqms}$year_raq"/uwhyb_climo_${month0}.nc" "uwhyb_"$month0$day0$year"00.chem.assim.nc"
              ln -sf ${indir_raqms}$year_raq"/uwhyb_climo_${month0}.nc" "uwhyb_"$month0$day0$year"06.chem.assim.nc"
              ln -sf ${indir_raqms}$year_raq"/uwhyb_climo_${month0}.nc" "uwhyb_"$month0$day0$year"12.chem.assim.nc"
              ln -sf ${indir_raqms}$year_raq"/uwhyb_climo_${month0}.nc" "uwhyb_"$month0$day0$year"18.chem.assim.nc"
              ln -sf ${indir_raqms}$year_raq"/uwhyb_climo_${end_month}.nc" "uwhyb_"$end_month$end_day$end_year"00.chem.assim.nc"
              ln -sf ${indir_raqms}$year_raq"/uwhyb_climo_${end_month}.nc" "uwhyb_"$end_month$end_day$end_year"06.chem.assim.nc"

              echo ${indir_raqms}$year_raq"/uwhyb_climo_${month0}.nc"

          else
              year_raq=$year
              nyear_raq=${end_year}   

              echo 'raqmps year month day', ${year_raq}, $month0, $day0
              echo 'raqmps next year month day', $nyear_raq, $end_month, $end_day

              # link 00z, 06z, 12z, 18z files, and the 00z, 06z of the next day
              ln -sf ${indir_raqms}$year_raq"/"$month0"/uwhyb_"$month0"_"$day0"_"${year_raq}"_00Z.chem.assim.nc" "uwhyb_"$month0$day0$year"00.chem.assim.nc"
              ln -sf ${indir_raqms}$year_raq"/"$month0"/uwhyb_"$month0"_"$day0"_"${year_raq}"_06Z.chem.assim.nc" "uwhyb_"$month0$day0$year"06.chem.assim.nc"
              ln -sf ${indir_raqms}$year_raq"/"$month0"/uwhyb_"$month0"_"$day0"_"${year_raq}"_12Z.chem.assim.nc" "uwhyb_"$month0$day0$year"12.chem.assim.nc"
              ln -sf ${indir_raqms}$year_raq"/"$month0"/uwhyb_"$month0"_"$day0"_"${year_raq}"_18Z.chem.assim.nc" "uwhyb_"$month0$day0$year"18.chem.assim.nc"

              ln -sf ${indir_raqms}$nyear_raq"/"${end_month}"/uwhyb_"${end_month}"_"${end_day}"_"${nyear_raq}"_00Z.chem.assim.nc" "uwhyb_"${end_month}${end_day}${end_year}"00.chem.assim.nc"
              ln -sf ${indir_raqms}$nyear_raq"/"${end_month}"/uwhyb_"${end_month}"_"${end_day}"_"${nyear_raq}"_06Z.chem.assim.nc" "uwhyb_"${end_month}${end_day}${end_year}"06.chem.assim.nc"

              echo ${indir_raqms}$year_raq/$month0"/uwhyb_"$month0"_"$day0"_"${year_raq}"_"$hr"Z.chem.assim.nc"
         fi

#
cat > raqms.wrfchembc.namelist.input << __EOF
&control
 dir_wrf = './'   ! Run directory, wrf data directory
 fnb_wrf  = 'wrfbdy_d01'                           ! WRF boundary condition data file
 fni_wrf  = 'wrfinput_d01'                         ! WRF initial condition data file
 chem_bc_opt = 2                                   ! Global Model data used: 1=MOZART, 2=RAQMS, 3=AM4
 dir_global = './'   ! Global model data directory
 fn_global  =  'uwhyb_$month0$day0$year$hr.chem.assim.nc'! Global model data file name
 do_bc = .true.
 do_ic = .false.
 nspec = 27                                         ! number of species listed by name in specname
 specname = 'so2',                                   ! name of chemical species to be added to boundary conditions
           'sulf','no2','no','o3','hno3',
           'h2o2','ald','hcho','n2o5','no3','pan','eth','co','ete','olt','hno4','mgly','onit','iso',
           'macr','op1','op2','mvk','mpan','ho','ho2'
 /
__EOF
#
          ./wrfchembc < raqms.wrfchembc.namelist.input > "raqms.bc."$year"."$month0"."$day0".out"

          rm -f uwhyb_*chem.assim.nc

          echo 'raqms chembc is done'

          rm -f am4.wrfchembc.namelist.input
          echo 'Now processing BCs only for CH4'

          # year for AM4 data
          if [ "$bdy_input" -eq 2 ]; then
              year_am4="climo"  # we use climo data (2015-2017 average)
              ln -sf ${indir_am4}"GFDL_AM4_"${year_am4}"_"$month0".nc" "GFDL_AM4_"$year$month0$day0".nc"
              echo ${indir_am4}"GFDL_AM4_"${year_am4}"_"$month0".nc"

          else
              year_am4="2017"
              ln -sf ${indir_am4}"GFDL_AM4_"${year_am4}"_"$month0".nc" "GFDL_AM4_"$year$month0$day0".nc"
              echo ${indir_am4}"GFDL_AM4_"${year_am4}"_"$month0".nc"
          fi

#
cat > am4.wrfchembc.namelist.input << __EOF
&control
 dir_wrf = './'   ! Run directory, wrf data directory
 fnb_wrf  = 'wrfbdy_d01'                           ! WRF boundary condition data file
 fni_wrf  = 'wrfinput_d01'                         ! WRF initial condition data file
 chem_bc_opt = 3                                   ! Global Model data used: 1=MOZART, 2=RAQMS, 3=AM4
 dir_global = './'   ! Global model data directory
 fn_global  = 'GFDL_AM4_$year$month0$day0.nc' ! Global model data file name
 do_bc = .true.
 do_ic = .false.
 nspec = 1                                         ! number of species listed by name in specname
 specname = 'ch4'    ! name of chemical species to be added to boundary conditions
 /
__EOF
#
          ./wrfchembc < am4.wrfchembc.namelist.input > am4."$year""$month0""$day0".out

          echo 'am4 chem bc for ch4 is done'
          rm -f "GFDL_AM4_"$year$month0$day0".nc"
     fi

     echo 'chembc is done'
fi

###############################################################################
#JianHe: assign timestamp into wrfchemi files required by io_style_emissions = 2
if [ "$task_no" -eq 3 ]; then
    echo $task_no
    echo "link wrfchemi files"
    rm -f wrfchemi*

    iday=$(date -d $year$month0$day0  "+%u")
    echo "start_day is day $iday of the week"

    if [ "$iday" -lt 6 ]; then
        echo "start_day is Weekday"
        echo ${emisdir}"Month${month0}/weekdy/wrfchemi_00z_d01"
        echo ${emisdir}"Month${month0}/weekdy/wrfchemi_12z_d01"
        cp  ${emisdir}"Month${month0}/weekdy/wrfchemi_00z_d01" ${execdir}"tmp.00z.nc"
        cp  ${emisdir}"Month${month0}/weekdy/wrfchemi_12z_d01" ${execdir}"tmp.12z.nc"
    fi
    if [ "$iday" -eq 6 ]; then
        echo "start_day is Saturday"
        echo ${emisdir}"Month${month0}/satdy/wrfchemi_00z_d01"
        echo ${emisdir}"Month${month0}/satdy/wrfchemi_12z_d01"
        cp ${emisdir}"Month${month0}/satdy/wrfchemi_00z_d01" ${execdir}"tmp.00z.nc"
        cp ${emisdir}"Month${month0}/satdy/wrfchemi_12z_d01" ${execdir}"tmp.12z.nc"
    fi
    if [ "$iday" -eq 7 ]; then
        echo "start_day is Sunday"
        echo ${emisdir}"Month${month0}/sundy/wrfchemi_00z_d01"
        echo ${emisdir}"Month${month0}/sundy/wrfchemi_12z_d01"
        cp ${emisdir}"Month${month0}/sundy/wrfchemi_00z_d01" ${execdir}"tmp.00z.nc"
        cp ${emisdir}"Month${month0}/sundy/wrfchemi_12z_d01" ${execdir}"tmp.12z.nc"
    fi

    ncap2 -s "Times=\"${year}-${month0}-${day0}_00:00:00${year}-${month0}-${day0}_01:00:00${year}-${month0}-${day0}_02:00:00${year}-${month0}-${day0}_03:00:00${year}-${month0}-${day0}_04:00:00${year}-${month0}-${day0}_05:00:00${year}-${month0}-${day0}_06:00:00${year}-${month0}-${day0}_07:00:00${year}-${month0}-${day0}_08:00:00${year}-${month0}-${day0}_09:00:00${year}-${month0}-${day0}_10:00:00${year}-${month0}-${day0}_11:00:00,\"" ${execdir}"tmp.00z.nc" -O ${execdir}"wrfchemi_d01_${year}-${month0}-${day0}_00:00:00"

    ncap2 -s "Times=\"${year}-${month0}-${day0}_12:00:00${year}-${month0}-${day0}_13:00:00${year}-${month0}-${day0}_14:00:00${year}-${month0}-${day0}_15:00:00${year}-${month0}-${day0}_16:00:00${year}-${month0}-${day0}_17:00:00${year}-${month0}-${day0}_18:00:00${year}-${month0}-${day0}_19:00:00${year}-${month0}-${day0}_20:00:00${year}-${month0}-${day0}_21:00:00${year}-${month0}-${day0}_22:00:00${year}-${month0}-${day0}_23:00:00,\"" ${execdir}"tmp.12z.nc" -O ${execdir}"wrfchemi_d01_${year}-${month0}-${day0}_12:00:00"

    rm -f ${execdir}"tmp.00z.nc" ${execdir}"tmp.12z.nc"
    echo "Current timestamp is assigned to wrfchemi files"
#
    jday=$(date -d $end_year$end_month$end_day  "+%u")
    echo "end_day is day $jday of the week"

    if [ "$jday" -lt 6 ]; then
        echo "end_day is Weekday"
        echo ${emisdir}"Month${end_month}/weekdy/wrfchemi_00z_d01"
        cp  ${emisdir}"Month${end_month}/weekdy/wrfchemi_00z_d01" ${execdir}"tmp.00z.nc"
    fi
    if [ "$jday" -eq 6 ]; then
        echo "end_day is Saturday"
        echo ${emisdir}"Month${end_month}/satdy/wrfchemi_00z_d01"
        cp  ${emisdir}"Month${end_month}/satdy/wrfchemi_00z_d01" ${execdir}"tmp.00z.nc"
    fi
    if [ "$jday" -eq 7 ]; then
        echo "end_day is Sunday"
        echo ${emisdir}"Month${end_month}/sundy/wrfchemi_00z_d01"
        cp  ${emisdir}"Month${end_month}/sundy/wrfchemi_00z_d01" ${execdir}"tmp.00z.nc"
    fi

    ncap2 -s "Times=\"${end_year}-${end_month}-${end_day}_00:00:00${end_year}-${end_month}-${end_day}_01:00:00${end_year}-${end_month}-${end_day}_02:00:00${end_year}-${end_month}-${end_day}_03:00:00${end_year}-${end_month}-${end_day}_04:00:00${end_year}-${end_month}-${end_day}_05:00:00${end_year}-${end_month}-${end_day}_06:00:00${end_year}-${end_month}-${end_day}_07:00:00${end_year}-${end_month}-${end_day}_08:00:00${end_year}-${end_month}-${end_day}_09:00:00${end_year}-${end_month}-${end_day}_10:00:00${end_year}-${end_month}-${end_day}_11:00:00,\"" ${execdir}"tmp.00z.nc" -O ${execdir}"wrfchemi_d01_${end_year}-${end_month}-${end_day}_00:00:00"

    rm -f ${execdir}"tmp.00z.nc"
    echo "Current timestamp is assigned to wrfchemi files"
#
    srun ${execdir}"wrf.exe"    

    cp "wrfout_d01_"$end_year"-"$end_month"-"$end_day"_00:00:00" $path_out"chem_res"
    mkdir $path_out$month0$day0
    mv wrfout_* $path_out$month0$day0
    mv wrfinput_d01  $path_out"wrfinput_d01_"$year"-"$month0"-"$day0"_"$hr":00:00"
    mv wrfbdy_d01  $path_out"wrfbdy_d01_"$year"-"$month0"-"$day0"_"$hr":00:00"
    mv wrflowinp_d01  $path_out"wrflowinp_d01_"$year"-"$month0"-"$day0"_"$hr":00:00"
    mv wrf_diag_* $path_out
    mv namelist.input  $path_out"namelist_"$year"-"$month0"-"$day0"_"$hr":00:00"
    mv rsl.error.0000  $path_out"rslerr_"$year"-"$month0"-"$day0"_"$hr":00:00"
    mv rsl.out.0000  $path_out"rslout_"$year"-"$month0"-"$day0"_"$hr":00:00"

    mkdir $path_out"bc_pp"
    mv am4.*out $path_out"bc_pp"
    mv raqms.*out $path_out"bc_pp"

    echo 'wrf.exe is done'
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
