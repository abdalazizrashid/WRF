{
  lib,
  mkShell,
  stdenv,
  cmake,
  ninja,
  gcc,
  gfortran,
  #pkgs-config,
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
      netcdffortran
      curl
      git
      
    ];
    buildInputs = [
      stdenv
      tcsh
      perl
    ];


    
#  preConfigurePhases = ["testCompilers"];

  # testCompilers = ''
  #   curl -k https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/Fortran_C_tests.tar -o Fortran_C_tests.tar
  #   tar -xvf Fortran_C_tests.tar
  # '';
  env = {
    NETCDF = pkgs.netcdffortran;
    NETCDF_classic = 1;
    DIR = "./Build_WRF/LIBRARIES";
    CC = pkgs.gcc;
    CX = pkgs.gcc;
    FC = pkgs.gfortran;
    FCFLAGS = "-m64";
    F77 = pkgs.gfortran;
    FFLAGS = "-m64";
    JASPERLIB = "${pkgs.jasper}/grib2/lib";
    JASPERINC = "${pkgs.jasper}/grib2/include";
    LDFLAGS = "-L${pkgs.jasper}/grib2/lib";
    CPPFLAGS = "-I${pkgs.jasper}/grib2/include";
    HDF5 = pkgs.hdf5-fortran;
    PHDF5 = pkgs.hdf5-mpi;
  };


  # shellHook = ''
  #   mkdir Build_WRF TESTS
  # '';
  
  patchPhase = ''
  sed -i 's/ $I_really_want_to_output_grib2_from_WRF = "FALSE" ;/ $I_really_want_to_output_grib2_from_WRF = "TRUE" ;/' arch/Config.pl
  '';

  configurePhase = ''
    mkdir Build_WRF TESTS
    ./configure << EOF
    35
    1
    EOF
  '';

  buildPhase = ''
             ./compile em_real
  '';


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
