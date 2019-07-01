#include "mex.h"
#include "math.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    mwSize ncols, index, persp, dims[3];
    double *coord3new, *coord3;
    float aspectRatio;
    int s, p, ndims, xSign, zSign, offset;
    double rot, r, rnew;
    // int dims[3];
    
    // Get aspect ratio of window
    aspectRatio = 1.8;
    
    // viewing parameters
    s = 1;
    p = 1;
    
    // inputs
    ncols = mxGetN(prhs[0]);
    coord3 = mxGetPr(prhs[0]);
    
    // outputs
    ndims = 3;
    dims[0] = 3;
    dims[1] = ncols;
    dims[2] = 4;    //SET NUMBER OF MONITORS HERE
    plhs[0] = mxCreateNumericArray(ndims, dims, mxDOUBLE_CLASS, mxREAL);
    coord3new = mxGetPr(plhs[0]);    
    
    // coordinate transformations (4 perspectives)
    rot = (2 * 3.1416) / dims[2];   // radians of rotation
    double rotMat[2][2] = {
        {cos(rot), -sin(rot)}, 
        {sin(rot), cos(rot)}
        };       // rotation matrix

    // perspective transformation loop
    // -----------------------------
    for (persp = 0; persp < dims[2]; persp++) {
        offset = 3 * ncols * persp;     // monitor number offset
        for (index = 0; index < ncols; index++) {        
            coord3new[offset+3*index] = s * coord3[3*index] / coord3[3*index + 1];      // monitor x value
            coord3new[offset+3*index+1] = s * coord3[3*index + 2] / coord3[3*index + 1];  // monitor y value 
            // check if point is visible and if not, clip the point
            if (coord3[3*index + 1] <= 0) {
                coord3new[offset+3*index+2] = 0; // invisible (clipping needed)
                xSign = (coord3[3*index] > 0) ? 1 : -1;
                zSign = (coord3[3*index + 2] > 0) ? 1 : -1;
                // here is the clipping
                coord3new[offset+3*index] = p * xSign * aspectRatio;
                coord3new[offset+3*index+1] = p * zSign;
            }
            else {
                coord3new[offset+3*index+2] = 1; // visible (no clipping needed)
            }            
        }
        // coord3 = rotMat * coord3;
    }
    
    return;
}