# Mapping of functions of space defined over non-conformal meshes

This repository illustrates how FeenoX can read a field defined over an unstructured grid (e.g. a temperature distribution coming from a heat conduction computation) and evaluate it any other aribtrary locations (e.g. the nodes of another non-conformal grid^[For a thermo-mechanical computation, these arbitrary locations would be the Gauss points of the mechanical grid.]).

To run the cases you need

 1. [Gmsh](http://gmsh.info/), and
 2. [FeenoX](https://www.seamplex.com/feenox/).
 3. The binary `time` tool (not Bash’s internal `time`)

These three dependencies ought to be available as commands named `gmsh`, `feenox` and `/usr/bin/time` respectively.
The binaries provided in the webpages above manually copied to `/usr/local/bin` (as root) are enough.

The base geometry is a unitary cube $[0,1]\times[0,1]\times[0,1]$ created in Gmsh with:

```
SetFactory("OpenCASCADE");
Box(1) = {0, 0, 0, 1, 1, 1};
```

The `run.sh` scripts performs three different steps:

 1. It creates five meshes with $n=10, 20, 30, 40, 50$ elements per side using Gmsh out of the base geometry `cube.geo`. Each of these five meshes `cube-n.msh` is read by FeenoX and a new mesh file named `cube-n-src.msh` is created with a scalar field `f` defined as $f(x) =  x + 2y + 3z + 4$:
 
    ```feenox
    # read the base mesh
    READ_MESH cube-$1.msh

    # define an algebraic function
    f(x,y,z) = x + 2*y + 3*z + 4

    # evaluate it at the nodes and write it into a "source" mesh
    WRITE_MESH cube-$1-src.msh f
    ```
    
 2. For each combination $n_i=10,\dots,50$ and $n_o=10,\dots,50$, the mesh `cube-ni-src.msh` is read (along with the function $f(x,y,z)$ defined at the nodes of the source mesh). Then, a VTK file named `cube-ni-no-dst.vtk` is created with two nodal fields:

    1. the function $f(x,y,z)$ interpolated from the input mesh
    2. the absolute value of the difference between $f(x,y,z)$ and the reference algebraic function $f_\text{ref}(x,y,z) = x + 2y + 3z + 4$:

    ```feenox
    # read the function f(x,y,z) from the nodes of the source mesh
    READ_MESH cube-$1-src.msh DIM 3 READ_FUNCTION f
    
    # read the dest mesh
    READ_MESH cube-$2.msh
    
    f_ref(x,y,z) = x + 2*y + 3*z + 4
    
    # evaluate f(x,y,z) at the nodes of the dest mesh and write it into $1 -> $2
    # throw in the absolute error as well
    WRITE_MESH cube-$1-$2-dst.vtk f abs(f(x,y,z)-f_ref(x,y,z)) MESH cube-$2.msh 
    ```

 3. Finally, for each VTK file, the L2 and maximum errors between the interpolated and the reference functions are computed:
 
    ```feenox
    # the reference function
    f(x,y,z) = x + 2*y + 3*z + 4
    
    # read the f from the dst vtk
    READ_MESH cube-$1-$2-dst.vtk DIM 3 READ_FIELD f AS f_msh
    
    # compute max and L2 errors
    INTEGRATE (f_msh(x,y,z)-f(x,y,z))^2 RESULT error_l2
    FIND_EXTREMA abs(f_msh(x,y,z)-f(x,y,z)) NODES MAX error_max
    PRINT $1 $2 %.1e error_l2 error_max %g nodes elements
    ```

Here is a sample output of running `run.sh`:

```terminal
$ ./run.sh
creating source mesh 10................... 0.11 seconds
populating source mesh 10 with f(x,y,z)... 0.01 seconds

creating source mesh 20................... 0.57 seconds
populating source mesh 20 with f(x,y,z)... 0.09 seconds

creating source mesh 30................... 2.34 seconds
populating source mesh 30 with f(x,y,z)... 0.60 seconds

creating source mesh 40................... 7.56 seconds
populating source mesh 40 with f(x,y,z)... 2.02 seconds

creating source mesh 50................... 14.27 seconds
populating source mesh 50 with f(x,y,z)... 3.71 seconds

interpolating from 10 to 10... 0.02 seconds
interpolating from 10 to 20... 0.16 seconds
interpolating from 10 to 30... 0.74 seconds
interpolating from 10 to 40... 2.01 seconds
interpolating from 10 to 50... 4.13 seconds

interpolating from 20 to 10... 0.12 seconds
interpolating from 20 to 20... 0.22 seconds
interpolating from 20 to 30... 0.94 seconds
interpolating from 20 to 40... 2.46 seconds
interpolating from 20 to 50... 5.41 seconds

interpolating from 30 to 10... 0.73 seconds
interpolating from 30 to 20... 1.00 seconds
interpolating from 30 to 30... 1.66 seconds
interpolating from 30 to 40... 3.57 seconds
interpolating from 30 to 50... 6.31 seconds

interpolating from 40 to 10... 1.87 seconds
interpolating from 40 to 20... 2.10 seconds
interpolating from 40 to 30... 3.00 seconds
interpolating from 40 to 40... 3.56 seconds
interpolating from 40 to 50... 7.28 seconds

interpolating from 50 to 10... 3.39 seconds
interpolating from 50 to 20... 3.69 seconds
interpolating from 50 to 30... 4.58 seconds
interpolating from 50 to 40... 6.43 seconds
interpolating from 50 to 50... 7.46 seconds

errors
--------------------------------------------------
src     dst     L2      max     nodes   elements
10      10      9.6e-03 7.0e-06 1201    4979
10      20      2.8e-03 2.9e-01 7411    37089
10      30      1.3e-03 3.2e-01 22992   123264
10      40      8.3e-04 3.0e-01 51898   289824
10      50      5.9e-04 3.3e-01 98243   560473

20      10      9.6e-03 1.1e-05 1201    4979
20      20      2.5e-03 7.0e-06 7411    37089
20      30      1.2e-03 1.5e-01 22992   123264
20      40      6.8e-04 1.6e-01 51898   289824
20      50      4.5e-04 1.6e-01 98243   560473

30      10      9.6e-03 5.4e-02 1201    4979
30      20      2.5e-03 8.2e-02 7411    37089
30      30      1.1e-03 7.0e-06 22992   123264
30      40      6.5e-04 1.1e-01 51898   289824
30      50      4.2e-04 1.1e-01 98243   560473

40      10      9.6e-03 2.7e-02 1201    4979
40      20      2.5e-03 7.3e-02 7411    37089
40      30      1.1e-03 6.6e-02 22992   123264
40      40      6.3e-04 7.2e-06 51898   289824
40      50      4.1e-04 8.2e-02 98243   560473

50      10      9.6e-03 3.9e-02 1201    4979
50      20      2.5e-03 5.4e-02 7411    37089
50      30      1.1e-03 6.3e-02 22992   123264
50      40      6.3e-04 6.2e-02 51898   289824
50      50      4.0e-04 7.2e-06 98243   560473
```

    
To get rid of all the `.msh` and `.vtk` file run the `clean.sh` script.
