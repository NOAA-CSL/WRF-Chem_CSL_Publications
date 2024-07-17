! RAR: modified to handle the new SOA mechanism based on the VBS approach and multi-generational
! VOC oxidation mechanism
! Correspondence between RACM_BEK_VCP and SAPRC-99 SOA precursors
! 1) OLT -> OLE1
! 2) OLI -> OLE2
! 3) TOL -> ARO1
! 4) XYL -> ARO2
! 5) CSL -> ARO2
! 6) HC5 -> ALK4
! 7) HC8 -> ALK5
! 8) ISO -> ISO
! 9) API -> TERP
!10) LIM -> TERP
!11) SESQ-> SESQ
!
if(p_nu0.gt.1)then

     ! OLT
     roltho =   RCONST(75)
     rolto3 =   RCONST(124)
     roltno3 =  RCONST(139)

     ! OLI
     roliho =   RCONST(76)
     rolio3  =  RCONST(125)
     rolino3 =  RCONST(140)

     ! TOL
     rtolho =   RCONST(80)
     rbenho =   RCONST(79)

     ! XYL
     rxylho  =  RCONST(81)
     rxyoho  =  RCONST(82)

     ! CSL
     rcslho  =  RCONST(103)
     rcslno3 =  RCONST(153)
     rphenho  =  RCONST(102)
     rphenno3 =  RCONST(152)

     ! HC5
     rhc5ho  =  RCONST(72)

     ! HC8
     rhc8ho  =  RCONST(73)

     ! ISO
     risoho  =  RCONST(83)
     risoo3  =  RCONST(127)
     risono3 =  RCONST(142)

     ! API
     rapiho  =  RCONST(84)
     rapio3  =  RCONST(128)
     rapino3 =  RCONST(143)

     ! LIM
     rlimho  =  RCONST(85)
     rlimo3  =  RCONST(129)
     rlimno3 =  RCONST(144)

     ! SESQ
     rsesqho  =  RCONST(526)
     rsesqo3  =  RCONST(527)
     rsesqno3 =  RCONST(528)

     ! Isoprene radical
     risopno  =  RCONST(185)
     risopho2 =  RCONST(224)
     risopmo2 =  RCONST(259)
     risopaco3=  RCONST(294)
     risopisop=  0.0

     ! production from anthropogenic VOCs
     PRDROG(PALK4)= rhc5ho*var(ind_hc5)*var(ind_ho)
     PRDROG(PALK5)= rhc8ho*var(ind_hc8)*var(ind_ho)

     PRDROG(POLE1)= roltho*var(ind_olt)*var(ind_ho) + rolto3*var(ind_olt)*var(ind_o3) + roltno3*var(ind_olt)*var(ind_no3)
     PRDROG(POLE2)= roliho*var(ind_oli)*var(ind_ho) + rolio3*var(ind_oli)*var(ind_o3) + rolino3*var(ind_oli)*var(ind_no3)

     PRDROG(PARO1)= rtolho*var(ind_tol)*var(ind_ho)
     PRDROG(PARO1)= PRDROG(PARO1) + rbenho*var(ind_ben)*var(ind_ho)

     PRDROG(PARO2)= rxylho*var(ind_xyl)*var(ind_ho)
     PRDROG(PARO2)= PRDROG(PARO2) + rxyoho*var(ind_xyo)*var(ind_ho)
     PRDROG(PARO2)= PRDROG(PARO2) + rcslho*var(ind_csl)*var(ind_ho) + rcslno3*var(ind_csl)*var(ind_no3)
     PRDROG(PARO2)= PRDROG(PARO2) + rphenho*var(ind_phen)*var(ind_ho) + rphenno3*var(ind_phen)*var(ind_no3)

     ! Biogenic
     PRDROG(PISOP)= risoho*var(ind_iso)*var(ind_ho) + risoo3*var(ind_iso)*var(ind_o3) + risono3*var(ind_iso)*var(ind_no3)

     PRDROG(PTERP)= rapiho*var(ind_api)*var(ind_ho) + rapio3*var(ind_api)*var(ind_o3) + rapino3*var(ind_api)*var(ind_no3)
     PRDROG(PTERP)= PRDROG(PTERP) + rlimho*var(ind_lim)*var(ind_ho) + rlimo3*var(ind_lim)*var(ind_o3) + rlimno3*var(ind_lim)*var(ind_no3)

     PRDROG(PSESQ)= rsesqho*var(ind_sesq)*var(ind_ho) + rsesqo3*var(ind_sesq)*var(ind_o3) + rsesqno3*var(ind_sesq)*var(ind_no3)

! RAR: to calculate the branching ratios to determine high NOx versus low NOx

     PRDROG(PBRCH)= risopno*var(ind_no)

     ! VDROG carrying the branching ratios
     if (PRDROG(PBRCH)>1.E-12) then
        ro2loss= PRDROG(PBRCH) + risopho2*var(ind_ho2) + risopmo2*var(ind_mo2) + risopaco3*var(ind_aco3)
        VDROG3_VBS( i,k,j,LDROG_VBS )= MIN( 1.D0,(PRDROG(PBRCH)/ro2loss) )
     else
         VDROG3_VBS( i,k,j,LDROG_VBS )= 0.
     end if

     DO n = 1, LDROG_VBS-1
        VDROG3_VBS( i,k,j,n ) =  oconv* PRDROG( n ) * DTSTEPC
        VDROG3_VBS( i,k,j,n ) =  MAX( 0., VDROG3_VBS( i,k,j,n ) )
     ENDDO
endif

! RAR: debugging
!if (i==8 .AND. j==18) then
!   if (k==1) then
!        write(*,*)'rhch5ho',rhc5ho,'rhc8ho',rhc8ho,'rhc8ho',roltho,'roliho',roliho, &
!                  'rtolho',rtolho,'rxylho',rxylho,'rsesqno3',rsesqno3
!        write(*,*)'ind_tol',ind_tol,'var(ind_tol)',var(ind_tol)
!        write(*,*)'ind_ho',ind_ho,'var(ind_ho)',var(ind_ho)
!        write(*,*)'ind_iso',ind_iso,'risoho',risoho
!        write(*,*)'PRDROG(PBRCH)', PRDROG(PBRCH),'ro2loss=',ro2loss        
!        write(*,*)'VDROG3(8,1,18,:)', VDROG3(i,k,j,:)
!   end if
!end if
!
!if (j==18 .AND. k==1) then
!        write(*,*)'VDROG3(:,18,1,:)', VDROG3(i,k,j,:)
!end if
