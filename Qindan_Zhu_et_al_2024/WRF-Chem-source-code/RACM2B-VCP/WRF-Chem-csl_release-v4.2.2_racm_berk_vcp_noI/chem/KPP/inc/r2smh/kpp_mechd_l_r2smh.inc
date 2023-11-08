REAL(KIND=dp) :: roltho,rolto3,roltno3,roliho,rolio3,rolino3,rtolho,rxylho,    &
                 rbenho,rxyoho,rphenho,rphenno3,                               &
                 rcslho,rcslno3,rhc5ho,rhc8ho,risoho,risoo3,risono3,           &
                 rapiho,rapio3,rapino3,rlimho,rlimo3,rlimno3,                  &
                 rsesqho,rsesqo3,rsesqno3,                                     &
                 risopno,risopho2,risopmo2,risopaco3,risopisop

REAL(KIND=dp) , DIMENSION(ldrog_vbs)  :: PRDROG
REAL(KIND=dp) :: ro2loss 

! for nrc_2o5

REAL( KIND = dp ) :: rc_n2o5

REAL(kind=dp) :: es, qvs, rh

INTEGER, SAVE :: icall

REAL(kind=dp), parameter :: rho_sulf = 1.7e3_dp 
REAL(kind=dp), parameter :: rho_orgc = 1.8e3_dp 
REAL(kind=dp), parameter :: rho_bc   = 1.0e3_dp 
REAL(kind=dp) :: aer_so4, aer_oc2, aer_bc2
