! calculate relative humidity
!

  es  = 1000._dp*0.6112_dp*exp(17.67_dp*(t_phy(i,k,j)-273.15_dp)/(t_phy(i,k,j)- 29.65_dp))
  qvs = es / ( p_phy(i,k,j) - es )


  rh =  moist(i,k,j,P_QV) / qvs
  rh = MIN ( MAX ( rh, 0._dp), 1._dp)

!
! set aerosol concentrations
!
  if( p_so4ai > param_first_scalar ) then
!     aer_so4 = chem(i,k,j,p_sulf)*1.e-6_dp*96.0_dp/29.0_dp*rho_phy(i,k,j)/rho_sulf
      aer_so4 = 1.e-9_dp * &
                (chem(i,k,j,p_so4ai) + chem(i,k,j,p_so4aj) + &
                 chem(i,k,j,p_nh4ai) + chem(i,k,j,p_nh4aj))  &
                * rho_phy(i,k,j)/rho_sulf
  else
    aer_so4 = 0._dp
  endif
  if( p_asoa1i > param_first_scalar ) then
    aer_oc2 = 1.e-9_dp * &
	   (0.5 * (chem(i,k,j, p_orgpaj)      + &
	   chem(i,k,j, p_orgpai))      + &
           chem(i,k,j, p_asoa1i)              + &
           chem(i,k,j, p_asoa2i)              + &
           chem(i,k,j, p_asoa3i)              + &
           chem(i,k,j, p_asoa4i)              + &
           chem(i,k,j, p_bsoa1i)              + &
           chem(i,k,j, p_bsoa2i)              + &
           chem(i,k,j, p_bsoa3i)              + &
	   chem(i,k,j, p_bsoa4i)              + &
           chem(i,k,j, p_asoa1j)              + &
           chem(i,k,j, p_asoa2j)              + &
           chem(i,k,j, p_asoa3j)              + &
           chem(i,k,j, p_asoa4j)              + &
           chem(i,k,j, p_bsoa1j)              + &
           chem(i,k,j, p_bsoa2j)              + &
           chem(i,k,j, p_bsoa3j)              + &
           chem(i,k,j, p_bsoa4j))             * &
           rho_phy(i,k,j)/rho_orgc
  else
    aer_oc2 = 0._dp
  endif
  if( p_eci > param_first_scalar ) then
    aer_bc2 = 0.2 * 1.e-9_dp * &
              (chem(i,k,j,p_eci) + chem(i,k,j,p_ecj)) &
              * rho_phy(i,k,j)/rho_bc
  else
    aer_bc2 = 0._dp
  endif

!! Why not sea salt?
!! any dust?
