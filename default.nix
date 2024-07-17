{
  pkgs ? import <nixpkgs> {}
}:
pkgs.stdenv.mkDerivation rec {
  pname = "WRF";
  version = "";
  doCheck = true;
  # https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compilation_tutorial.php

  src = pkgs.fetchFromGitHub {
    owner = "abdalazizrashid";
    repo = pname;
    rev = "0a11865f97680fdd6865b278ea29d910e5db3ed7";
    fetchSubmodules = true;
    sha256 = "6q2h2ol90D01Ik75x683qMsWignrOZ6o/ttcBBHDOWs=";
  };
  
  nativeBuildInputs = [
    pkgs.gcc
    pkgs.gfortran
    pkgs.cmake
    pkgs.pkg-config
    pkgs.ninja
    pkgs.autoconf
    pkgs.m4
    pkgs.netcdffortran
    pkgs.curl
    pkgs.git
    
  ];
  buildInputs = [
    pkgs.stdenv
    pkgs.tcsh
    pkgs.perl
    pkgs.netcdf
    pkgs.mpi
    pkgs.python3
    pkgs.hdf5-fortran
    pkgs.hdf5-mpi
    pkgs.mpich
    pkgs.jasper
    pkgs.libpng
    pkgs.zlib
    pkgs.openssl
    pkgs.netcdf
    pkgs.coreutils
    pkgs.gnused
    pkgs.gnutar
    pkgs.findutils
    pkgs.gnugrep
    pkgs.gzip
    pkgs.gnused
    pkgs.binutils
    pkgs.gnutar
    pkgs.which
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


  shellHook = ''
    mkdir Build_WRF TESTS
  '';
  
  patchPhase = ''
  sed -i 's/ $I_really_want_to_output_grib2_from_WRF = "FALSE" ;/ $I_really_want_to_output_grib2_from_WRF = "TRUE" ;/' arch/Config.pl
  '';

  #   ------------------------------------------------------------------------
  # Please select from among the following Darwin ARCH options:

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

  # Compile for nesting? (0=no nesting, 1=basic, 2=preset moves, 3=vortex following) [default 0]:

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


  meta = with pkgs.lib; {
    homepage = "https://github.com//";
    description = "";
    longDescription = ''

  '';
  license = licenses.gpl3;
  maintainers = with maintainers; [  ];
  platforms = platforms.unix;
  };
}
  
