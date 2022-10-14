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
populating source mesh 10 with f(x,y,z)... 0.03 seconds

creating source mesh 20................... 0.57 seconds
populating source mesh 20 with f(x,y,z)... 0.16 seconds

creating source mesh 30................... 2.33 seconds
populating source mesh 30 with f(x,y,z)... 0.68 seconds

creating source mesh 40...................  6.83 seconds
populating source mesh 40 with f(x,y,z)... 1.93 seconds

creating source mesh 50................... 14.10 seconds
populating source mesh 50 with f(x,y,z)... 3.92 seconds

interpolating from 10 to 10... 0.05 seconds
interpolating from 10 to 20... 0.24 seconds
interpolating from 10 to 30... 0.94 seconds
interpolating from 10 to 40... 2.26 seconds
interpolating from 10 to 50... 4.42 seconds

interpolating from 20 to 10... 0.16 seconds
interpolating from 20 to 20... 0.25 seconds
interpolating from 20 to 30... 1.05 seconds
interpolating from 20 to 40... 2.47 seconds
interpolating from 20 to 50... 4.83 seconds

interpolating from 30 to 10... 0.73 seconds
interpolating from 30 to 20... 1.03 seconds
interpolating from 30 to 30... 1.55 seconds
interpolating from 30 to 40... 3.13 seconds
interpolating from 30 to 50... 5.72 seconds

interpolating from 40 to 10... 1.65 seconds
interpolating from 40 to 20... 1.88 seconds
interpolating from 40 to 30... 2.67 seconds
interpolating from 40 to 40... 3.56 seconds
interpolating from 40 to 50... 7.20 seconds

interpolating from 50 to 10... 3.38 seconds
interpolating from 50 to 20... 3.60 seconds
interpolating from 50 to 30... 4.39 seconds
interpolating from 50 to 40... 6.21 seconds
interpolating from 50 to 50... 7.54 seconds

errors
--------------------------------------------------
src     dst     L2      max     nodes   elements
10      10      9.8e-02 7.0e-06 1201    4979
10      20      5.3e-02 2.9e-01 7411    37089
10      30      3.6e-02 3.2e-01 22992   123264
10      40      2.9e-02 3.0e-01 51898   289824
10      50      2.4e-02 3.3e-01 98243   560473

20      10      9.8e-02 1.1e-05 1201    4979
20      20      5.0e-02 7.0e-06 7411    37089
20      30      3.4e-02 1.5e-01 22992   123264
20      40      2.6e-02 1.6e-01 51898   289824
20      50      2.1e-02 1.6e-01 98243   560473

30      10      9.8e-02 5.4e-02 1201    4979
30      20      5.0e-02 8.2e-02 7411    37089
30      30      3.3e-02 7.0e-06 22992   123264
30      40      2.5e-02 1.1e-01 51898   289824
30      50      2.1e-02 1.1e-01 98243   560473

40      10      9.8e-02 2.7e-02 1201    4979
40      20      5.0e-02 7.3e-02 7411    37089
40      30      3.3e-02 6.6e-02 22992   123264
40      40      2.5e-02 7.2e-06 51898   289824
40      50      2.0e-02 8.2e-02 98243   560473

50      10      9.8e-02 3.9e-02 1201    4979
50      20      5.0e-02 5.4e-02 7411    37089
50      30      3.3e-02 6.3e-02 22992   123264
50      40      2.5e-02 6.2e-02 51898   289824
50      50      2.0e-02 7.2e-06 98243   560473
$
```

    
To get rid of all the `.msh` and `.vtk` file run the `clean.sh` script.

The timings include all the steps from reading the meshes and writing the VTKs.
Even more, the `WRITE_MESH` step perform both the

 1. non-conformal interpolation of the data
 2. writing into the output VTK
 
To try to have a more granular timing, the script `time.sh` uses the `interpolate_timed.fee` input that tries to measure the wall time of the different steps:

```feenox
# read the function f(x,y,z) from the nodes of the source mesh
start = clock()
READ_MESH cube-$1-src.msh DIM 3 READ_FUNCTION f
wall_read_src = clock() - start

# read the dest mesh
start = clock()
READ_MESH cube-$2.msh
wall_read_dst = clock() - start

f_ref(x,y,z) = x + 2*y + 3*z + 4

# reference time to write a constant in a vtk
start = clock()
WRITE_MESH one.vtk MESH cube-$2.msh     1
wall_write_one = clock() - start


# interpolation + writing
start = clock()
WRITE_MESH cube-$1-$2-dst.vtk MESH cube-$2.msh     f
wall_write_f = clock() - start

PRINT $1 $2 %.3f wall_read_src wall_read_dst wall_write_one wall_write_f  wall_write_f-wall_write_one 0.5*(wall_write_f+wall_write_f-wall_write_one)
```

To try to separate the time needed to perform the interpolation from the time needed to write the VTK, a reference `WRITE_MESH` is performed where the data written is a constant (equal to one). Estimating the actual time needed to perform the interpolation as the difference between the two `WRITE_MESH` may be too optimistic, so the average of the two times is also printed as an estimation:


```
$ ./time.sh 
src     dst     readsrc readdst wrtone  wrtf    diff    average
10      10      0.016   0.014   0.021   0.019   -0.001  0.009
10      10      0.014   0.022   0.008   0.020   0.012   0.016
10      20      0.014   0.117   0.033   0.046   0.014   0.030
10      30      0.013   0.515   0.124   0.158   0.034   0.096
10      40      0.014   1.501   0.297   0.397   0.099   0.248
10      50      0.014   3.100   0.593   0.780   0.187   0.484

20      10      0.103   0.008   0.007   0.009   0.002   0.006
20      20      0.102   0.070   0.036   0.038   0.002   0.020
20      30      0.105   0.474   0.134   0.210   0.076   0.143
20      40      0.102   1.429   0.293   0.483   0.190   0.337
20      50      0.110   3.100   0.624   1.006   0.381   0.693

30      10      0.541   0.010   0.009   0.014   0.005   0.009
30      20      0.538   0.077   0.042   0.082   0.040   0.061
30      30      0.551   0.480   0.129   0.136   0.007   0.072
30      40      0.542   1.444   0.307   0.598   0.291   0.444
30      50      0.545   3.069   0.595   1.199   0.605   0.902

40      10      1.557   0.011   0.009   0.016   0.007   0.011
40      20      1.554   0.090   0.040   0.084   0.044   0.064
40      30      1.563   0.466   0.132   0.297   0.166   0.231
40      40      1.528   1.417   0.301   0.344   0.043   0.194
40      50      1.628   3.180   0.611   1.412   0.800   1.106

50      10      3.300   0.011   0.009   0.017   0.008   0.013
50      20      3.376   0.076   0.036   0.113   0.077   0.095
50      30      3.289   0.501   0.140   0.357   0.217   0.287
50      40      3.275   1.473   0.314   0.849   0.535   0.692
50      50      3.393   3.212   0.683   0.806   0.123   0.464
$
```
