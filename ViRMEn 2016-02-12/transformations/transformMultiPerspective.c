#include "mex.h"
#include "math.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    mwSize ncols, index, dims[3], window;
    double *coord3new, *coord3, *aspectRatios;
    int s, p, ndims, xSign, zSign, offset;
    
    // viewing parameters
    s = 1;
    p = 1;
    
    // inputs
    aspectRatios = mxGetPr(prhs[2]);
    ncols = mxGetN(prhs[0]);
    coord3 = mxGetPr(prhs[0]);
    
    // outputs
    ndims = 3;
    dims[0] = 3;
    dims[2] = *mxGetPr(prhs[1]);
    dims[1] = ncols/dims[2];
    plhs[0] = mxCreateNumericArray(ndims, dims, mxDOUBLE_CLASS, mxREAL);
    coord3new = mxGetPr(plhs[0]);    
    
    // // perspective transformation loop
    // // -----------------------------
    for (index = 0; index < ncols; index++) {        
        window = floor(index/ncols);
        coord3new[3*index] = s * coord3[3*index] / coord3[3*index + 1];      // monitor x value
        coord3new[3*index+1] = s * coord3[3*index + 2] / coord3[3*index + 1];  // monitor y value 
        // check if point is visible and if not, clip the point
        if (coord3[3*index + 1] <= 0) {
            coord3new[3*index+2] = 0; // invisible (clipping needed)
            xSign = (coord3[3*index] >= 0) ? 1 : -1;
            zSign = (coord3[3*index + 2] >= 0) ? 1 : -1;
            // here is the clipping
            coord3new[3*index] = p * xSign * aspectRatios[window];
            coord3new[3*index+1] = p * zSign;
        }
        else {
            coord3new[3*index+2] = 1; // visible (no clipping needed)
        }            
    }
    
    return;
}