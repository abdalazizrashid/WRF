{
  lib,
  mkShell,
  stdenv,
  cmake,
  ninja,
  gcc,
  gfortran,
  pkg-config,
  autoconf,
  m4,
  netcdffortran,
  curl,
  git,
  tcsh,
  perl,
  netcdf,
  mpi,
  python3,
  hdf5-fortran,
  hdf5-mpi,
  mpich,
  jasper,
  libpng,
  zlib,
  openssl,
  coreutils,
  gnused,
  gnutar,
  findutils,
  gnugrep,
  gzip,
  binutils,
  which,
  useMpi ? false,
  useOpenMP ? false,
  wrfVersion ? "0.0.0"  # Arbitrary version, substituted by the flake
}@inputs:

let
  inherit (lib)
    cmakeBool
    cmakeFeature
    optionals
    strings
  ;

  suffixes =
    lib.optionals useMpi [ "dmpar" ]
    ++ lib.optionals useOpenMP [ "smpar" ]
  ;
 
  # The information for the serial / openmp / mpi / openmp + mpi
  #   1. (serial)   2. (smpar)   3. (dmpar)   4. (dm+sm)   PGI (pgf90/pgcc)
  #   5. (serial)   6. (smpar)   7. (dmpar)   8. (dm+sm)   INTEL (ifort/icc)
  #   9. (serial)  10. (smpar)  11. (dmpar)  12. (dm+sm)   INTEL (ifort/clang)
  #  13. (serial)               14. (dmpar)                GNU (g95/gcc)
  #  15. (serial)  16. (smpar)  17. (dmpar)  18. (dm+sm)   GNU (gfortran/gcc)
  #  19. (serial)  20. (smpar)  21. (dmpar)  22. (dm+sm)   GNU (gfortran/clang)
  #  23. (serial)               24. (dmpar)                IBM (xlf90_r/cc)
  #  25. (serial)  26. (smpar)  27. (dmpar)  28. (dm+sm)   PGI (pgf90/pgcc): -f90=pgf90
  #  29. (serial)  30. (smpar)  31. (dmpar)  32. (dm+sm)   INTEL (ifort/icc): Open MPI
  #  33. (serial)  34. (smpar)  35. (dmpar)  36. (dm+sm)   GNU (gfortran/gcc): Open MPI
  
  pnameSuffix =
    strings.optionalString (suffixes != [])
      "-";
  descriptionSuffix =
    strings.optionalString (suffixes != [])
      ", Using ${strings.concatStringSep ", " suffixes}";

  executableSuffix = stdenv.hostPlatform.extensions.executable;

in
stdenv.mkDerivation (
  finalAttrs: {
    pname = "WRF-${pnameSuffix}";
    version = wrfVersion;
    dontAddPrefix = false;
    # https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compilation_tutorial.php
    src = lib.cleanSourceWith {
      filter = name: type:
        let
          noneOf = builtins.all (x: !x);
          baseName = baseNameOf name;
        in
          noneOf [
            (lib.hasSuffix ".nix" name) # ignore *.nix when computing outPaths
            (lib.hasSuffix ".md" name) # ignore .doc when computing outPaths
            (lib.hasSuffix "." name) # ignore hidden files and dirs
            (baseName == "flake.lock")
          ];
      src = lib.cleanSource ../.;
    };
          
    nativeBuildInputs = [
      gcc
      gfortran
      cmake
      pkg-config
      ninja
      autoconf
      m4
      netcdf
      netcdffortran
      curl
      git
      
    ];
    buildInputs = [
      stdenv
      tcsh
      perl
    ];


    env = {
      NETCDF = netcdffortran;
      NETCDF_classic = 1;
      DIR = "./Build_WRF/LIBRARIES";
      CC = gcc;
      CX = gcc;
      FC = gfortran;
      FCFLAGS = "-m64";
      F77 = gfortran;
      FFLAGS = "-m64";
      JASPERLIB = "${jasper}/grib2/lib";
      JASPERINC = "${jasper}/grib2/include";
      LDFLAGS = "-L${jasper}/grib2/lib";
      CPPFLAGS = "-I${jasper}/grib2/include";
      HDF5 = hdf5-fortran;
      PHDF5 = hdf5-mpi;
    };

    preConfigure = ''
cat << EOF >> wrf_config.cmake
# https://cmake.org/cmake/help/latest/module/FindMPI.html#variables-for-locating-mpi
set( MPI_Fortran_COMPILER "mpif90" )
set( MPI_C_COMPILER       "mpicc" )

# https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_COMPILER.html
set( CMAKE_Fortran_COMPILER "gfortran" )
set( CMAKE_C_COMPILER       "gcc" )

# Our own addition
set( CMAKE_C_PREPROCESSOR       "cpp" )
set( CMAKE_C_PREPROCESSOR_FLAGS   )

# https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_FLAGS_INIT.html
set( CMAKE_Fortran_FLAGS_INIT    " -w -fconvert=big-endian -frecord-marker=4" )
set( CMAKE_C_FLAGS_INIT          " -w -O3   -DMACOS" )

# https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_FLAGS_CONFIG_INIT.html
set( CMAKE_Fortran_FLAGS_DEBUG_INIT    "" )
set( CMAKE_Fortran_FLAGS_RELEASE_INIT  "" )
set( CMAKE_C_FLAGS_DEBUG_INIT    "" )
set( CMAKE_C_FLAGS_RELEASE_INIT  "" )

# Project specifics now
set( WRF_MPI_Fortran_FLAGS  "" )
set( WRF_MPI_C_FLAGS        "" )
set( WRF_ARCH_LOCAL         "-DNONSTANDARD_SYSTEM_SUBR -DMACOS  CONFIGURE_D_CTSM"  )
set( WRF_M4_FLAGS           ""    )
set( WRF_FCOPTIM            "-O2 -ftree-vectorize -funroll-loops"     )
set( WRF_FCNOOPT            "-O0"     )
set( WRF_CORE                         ARW          CACHE STRING "Set by configuration" FORCE )
set( WRF_NESTING                      BASIC        CACHE STRING "Set by configuration" FORCE )
set( WRF_CASE                         EM_REAL      CACHE STRING "Set by configuration" FORCE )
set( USE_MPI                          OFF          CACHE STRING "Set by configuration" FORCE )
set( USE_OPENMP                       OFF          CACHE STRING "Set by configuration" FORCE )
EOF
                   '';
    cmakeFlags = [
      (cmakeFeature "CMAKE_TOOLCHAIN_FILE" "wrf_config.cmake")
      (cmakeBool "USE_MPI" false)
      (cmakeBool "USE_OPENMP" false)
    ];

    passthru = {
      inherit
        useMpi
        useOpenMP
      ;
      shell = mkShell {
        name = "shell-${finalAttrs.finalPackage.name}";
        description = "";
        inputsFrom = [finalAttrs.finalPackage ];
      };
    };

    
  meta = with lib; {
    homepage = "https://github.com//";
    description = "";
    longDescription = ''

  '';
    license = licenses.gpl3;
    maintainers = with maintainers; [  ];
    platforms = platforms.unix;
  };
  }
)
