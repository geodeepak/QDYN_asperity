!define problem

module problem_class

  use fault_stress, only : kernel_type
  use mesh, only : mesh_type, spectral_mesh_type

  implicit none

  public

 ! timeseries outputs: at every time step, but only macroscopic quantities
  type ot_type
    double precision :: lcold, lcnew, llocnew, llocold, v_th, pot, pot_rate
    double precision, dimension(:), allocatable :: xsta, ysta, zsta, v_pre, v_pre2
    integer :: unit=0, ic=0, ntout=0, ivmax=0
    integer :: ivmaxglob=0 ! For MPI
    integer, dimension(:), allocatable :: iot, iasp
  end type ot_type

  type oxptr
    double precision, pointer :: p(:) => null()
  end type oxptr

 ! snapshot outputs: at every fault point, but only at few selected times
  type ox_type
    integer :: ntout=0, nox=-1, nox_dyn=-1, nrup=-1
    integer :: unit=-1, ox_dyn_unit=-1, QSB_unit_pre=-1, QSB_unit_post=-1
    integer :: count, dyn_count, dyn_stat, i_ox_dyn
    integer :: nwout, nwout_dyn, nxout, nxout_dyn
    double precision :: pot_pre
    double precision, dimension(:), allocatable :: tau_max, t_rup, v_max, t_vmax
    character(len=256) :: header
    character(len=16), dimension(:), allocatable :: fmt
    type(oxptr), dimension(:), allocatable :: objects_glob, objects_loc, &
                                              objects_dyn, objects_ox, &
                                              objects_rup
  end type ox_type

  ! SEISMIC: structure that holds the CNS model parameters
  ! See input.f90 for a description of the parameters
  type cns_type
    double precision, dimension(:), allocatable :: &
      a_tilde, mu_tilde_star, H, L, & ! Granular flow and microstructural params
      y_gr_star, phi_c, phi0, lambda, &
      A, n, m, A_bulk, n_bulk, m_bulk ! Creep mechanism parameters
    integer :: N_creep=-1 ! Number of active creep mechanisms
  end type cns_type
  ! End of the CNS model structure

  ! SEISMIC: structure that holds the thermal pressurisation (TP) model parameters
  ! See input.f90 for a description of the parameters
  ! Spectral mesh parameters (Dlogl, lw_max, Nl) are hard-coded in mesh.f90
  type tp_type
    type (spectral_mesh_type) :: mesh
    double precision, pointer :: P(:) => null(), T(:) => null()
    double precision, dimension(:), allocatable :: &
      rhoc, inv_rhoc, beta, eta, k_t, k_p, l, w, inv_w, P_a, T_a, &
      Pi, Theta, PiTheta, Omega, dP_dt, Theta_prev, PiTheta_prev, &
      alpha_th, alpha_hy, Lam, Lam_prime, Lam_T, phi_b, dilat_factor
    double precision :: t_prev=0d0
  end type tp_type
  ! End of the TP model structure

  ! SEISMIC: requested features structure
  ! stress_coupling: normal stress variations at subduction interfaces
  ! tp: thermal pressurisation
  ! cohesion: time-dependent cohesion (CNS model)
  ! localisation: localisation of deformation (CNS model)
  type features_type
    integer :: stress_coupling, tp, localisation
  end type features_type
  ! End of features structure

  ! SEISMIC: Runge-Kutta-Fehlberg solver parameters
  type rk45_type
    integer :: iflag
    double precision, dimension(:), allocatable :: work
    integer, dimension(:), allocatable :: iwork
  end type rk45_type
  ! End of features structure

  ! SEISMIC: Runge-Kutta-Fehlberg solver parameters
  type rk45_2_type
    double precision, dimension(5) :: t_coeffs
    double precision, dimension(5) :: error_coeffs
    double precision, dimension(19) :: coeffs
    double precision, dimension(:), allocatable :: k1, k2, k3, k4, k5, k6
    double precision, dimension(:), allocatable :: dy1, dy2, dy3, dy4, dy5, dy6
    double precision, dimension(:), allocatable :: y_new, h, e
  end type rk45_2_type
  ! End of features structure

  ! Structure for (unit)testing
  type test_type
    logical :: test_mode = .false.
    logical :: test_passed = .true.
  end type test_type
  ! End of testing structure

  type problem_type
    type (mesh_type) :: mesh
    type (kernel_type) :: kernel
    ! Basic variables
    ! Allocate ox output variables as pointers
    ! NOTE: if theta2 needs to be in output sequence, add here
    double precision, pointer ::  tau(:) => null(), dtau_dt(:) => null(), &
                                  sigma(:) => null(), slip(:) => null(), &
                                  v(:) => null(), theta(:) => null()
    double precision, dimension(:), allocatable :: dtheta_dt, dtheta2_dt
    double precision, dimension(:), allocatable :: theta2, alpha
   ! Boundary conditions
    integer :: i_sigma_cpl=0, finite=0
   ! Friction properties
    double precision, dimension(:), allocatable ::  a, b, dc, v1, v2, &
                                                    mu_star, v_star, &
                                                    theta_star, coh, v_pl
    integer :: itheta_law=1, i_rns_law=1, neqs=3
   ! Elastic properties
    double precision :: beta=0d0, smu=0d0, lam=0d0, D=0d0, H=0d0, zimpedance=0d0
   ! Periodic loading
    double precision :: Tper=0d0, Aper=0d0, Omper=0d0
   ! Time solver
    double precision :: t_prev=0d0, time=0d0, dt_try=0d0, dt_did=0d0, &
                        dt_next=0d0, dt_max=0d0, tmax, acc
    integer :: NSTOP, itstop=-1, it=0
    double precision :: vmaxglob
   ! For outputs
    type (ot_type) :: ot
    type (ox_type) :: ox
   ! For MPI outputs
    double precision, pointer ::  tau_glob(:) => null(), dtau_dt_glob(:) => null(), &
                                  sigma_glob(:) => null(), slip_glob(:) => null(), &
                                  v_glob(:) => null(), theta_glob(:) => null(), &
                                  P_glob(:) => null(), T_glob(:) => null()
    double precision, dimension(:), allocatable ::  tau_max_glob, t_rup_glob, &
                                                    v_max_glob, t_vmax_glob
    logical :: allocated_glob = .false.
   ! QSB
    double precision :: DYN_M,DYN_th_on,DYN_th_off
    integer :: DYN_FLAG,DYN_SKIP
    ! Flag for unit testing
    logical :: test_mode = .false.

    ! SEISMIC: added structures
    type (cns_type) :: cns_params
    type (tp_type) :: tp
    type (features_type) :: features
    type (rk45_type) :: rk45
    type (rk45_2_type) :: rk45_2
    type (test_type) :: test
  end type problem_type

end module problem_class
