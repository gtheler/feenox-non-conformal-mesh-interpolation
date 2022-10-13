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

    
To get rid of all the `.msh` and `.vtk` file run the `clean.sh` script.
