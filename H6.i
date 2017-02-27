# Hackathon benchmark problems.
# Spinodal Decomposition
# Tee geometry
# No flux boundary condition
# Solution Time Adaptative Time Stepper

#tee geometry
[Mesh]
  #type = FileMesh
  file = tee_mesh.e
  uniform_refine = 3
[]

#Both variables are linear Lagrange shape functions
[Variables]
  [./c]
    order = FIRST
    family = LAGRANGE
    scaling = 3
  [../]
  [./chem_pot]
    order = FIRST
    family = LAGRANGE
  [../]
[]

[AuxVariables]
  [./f_density]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

[AuxKernels]
  [./f_density]
    type = TotalFreeEnergy
    variable = 'f_density'
    f_name = f_loc
    interfacial_vars = 'c'
    kappa_names = 'kappa_c'
  [../]
[]

[Kernels]
  [./chem_pot_dot]
    type = CoupledTimeDerivative
    variable = 'chem_pot'
    v = 'c'
  [../]
  [./coupled_parsed]
    type = SplitCHParsed
    variable = 'c'
    f_name = f_loc
    kappa_name = 'kappa_c'
    w = 'chem_pot'
  [../]
  [./coupled_res]
    type = SplitCHWRes
    variable = 'chem_pot'
    mob_name = 'M'
  [../]
[]

# Initial conditions for c.
[ICs]
  [./IC_c]
    type = FunctionIC
    function = ICFunction
    variable = 'c'
  [../]
[]

[Functions]
  [./ICFunction]
    type = ParsedFunction
    value = 'C0+Epsilon*(cos(0.105*(x+10))*cos(0.11*(y+50))+(cos(0.13*(x+10))*cos(0.087*(y+50)))^2+cos(0.025*(x+10)-0.15*(y+50))*cos(0.07*(x+10)-0.02*(y+50)))'
    vars = 'C0  Epsilon'
    vals = '0.5 0.01'
  [../]
[]

# Definition of the free energy Fbulk
[Materials]
  [./mat]
    type = GenericConstantMaterial
    prop_names = ' kappa_c M'
    prop_values = '2       5'
  [../]
  [./local_free_energy]
    type = DerivativeParsedMaterial
    f_name = f_loc
    args = 'c'
    function = 'RhoS*(c-Calpha)^2*(Cbeta-c)^2'
    constant_names =       'Calpha Cbeta RhoS'
    constant_expressions = '0.3    0.7   5'
    derivative_order = 2
  [../]
  # To determine the fraction of the high concentration phase
  # return 1/200/200 when in a precipitate
  [./precipitate_indicator]
    type = ParsedMaterial
    f_name = prec_ind
    args = c
    function = if(c>0.5,0.000025,0)
  [../]
[]

[Postprocessors]
  [./evaluations]           # Cumulative residual calculations for simulation
    type = NumResidualEvaluations
  [../]
  [./active_time]
    type = RunTime
    time_type = active
  [../]
  [./precipitate_area]
    type = ElementIntegralMaterialProperty
    mat_prop = prec_ind
  [../]
  [./num_features]          # Number of precipitates formed
  type = FeatureFloodCount
  variable = c
  threshold = 0.6
  [../]
  [./concentration]
    type = ElementIntegralVariablePostprocessor
    variable = c
  [../]
  [./f_density]
    type = ElementIntegralVariablePostprocessor
    variable = f_density
  [../]
  [./iterations]            # Number of iterations needed to converge timestep
  type = NumNonlinearIterations
  [../]
  [./nodes]                 # Number of nodes in mesh
    type = NumNodes
  [../]
  [./end_criterion]                 # End Criterion
    type = ElementAverageTimeDerivative
    variable = f_density
  [../]
[]

[UserObjects]
  [./end]
    type = Terminator
    expression = 'abs(end_criterion)<1e-14'
  [../]
[]

[Preconditioning]
  [./c_chem_pot_coupling]
    type = SMP
    full = true
  [../]
[]

[Executioner]
  type = Transient
  solve_type = NEWTON # full Newton Method for Spinodal decomposition
  nl_rel_tol = 1e-8 # 1e-8 given by the paper
  nl_abs_tol = 1e-11 # 1e-11 given by the paper
  end_time = 3000000
  dt=1
  l_max_its = 30
  nl_max_its = 50
  #l_tol = 1e-4
  #nl_rel_step_tol = 1e-5
  #nl_abs_step_tol = 1e-5
  petsc_options_iname = '-pc_type -ksp_gmres_restart -sub_ksp_type -sub_pc_type -pc_asm_overlap'
  petsc_options_value = 'asm      31                  preonly      lu           2'
  timestep_tolerance = 1e-1
  # Mesh Adaptivity: The objective is to have at least 5 elements in interface.
  [./Adaptivity]
    refine_fraction = 0.9
    coarsen_fraction = 0.05
    max_h_level = 2
    initial_adaptivity = 2
  [../]
  # Time Stepper: Using Solution Time Adaptative here.
  # maximum of 5% increase per time step
  [./TimeStepper]
    type = SolutionTimeAdaptiveDT
    dt = 1 #arbitrary
    percent_change = 0.05
  [../]
[]

# It converges faster if all the residuals are at the same magnitude
[Debug]
  show_var_residual_norms = true
[../]

[Outputs]
[./exodus]
  type = Exodus
  sync_times = '1 5 10 20 100 200 500 1000 2000 3000 10000 400000'
  sync_only = true
[../]
  console = true
  csv = true
  [./console]
    type = Console
    max_rows = 10
  [../]
[]
