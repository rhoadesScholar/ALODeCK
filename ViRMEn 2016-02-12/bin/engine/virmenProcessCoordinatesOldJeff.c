#include "mex.h"
#include "math.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    double *coord3, *coord3new, *pos, *z;
    mwSize ncols, index, row, offset, perspNum;
    double c, s;
    double temp;
    
    perspNum = *mxGetPr(prhs[2]);
    ncols = mxGetN(prhs[0]);
    
    coord3 = mxGetPr(prhs[0]);
    pos = mxGetPr(prhs[1]);
    
    plhs[0] = mxCreateDoubleMatrix(3,ncols*perspNum,mxREAL);
    coord3new = mxGetPr(plhs[0]);
    
    plhs[1] = mxCreateDoubleMatrix(1,ncols*perspNum,mxREAL);
    z = mxGetPr(plhs[1]);
    
    for ( index = 0; index < ncols; index++ ) {
        for ( row = 0; row < 3; row++ ) {
            coord3new[3*index+row] = coord3[3*index+row]-pos[row];
        }
        // z[index] = sqrt(coord3new[3*index]*coord3new[3*index] + coord3new[3*index+1]*coord3new[3*index+1] + coord3new[3*index+2]*coord3new[3*index+2]);
        for (offset = 0; offset < perspNum*3*ncols; offset+=3*ncols) {
            z[offset + index] = sqrt(coord3new[3*index]*coord3new[3*index] + coord3new[3*index+1]*coord3new[3*index+1] + coord3new[3*index+2]*coord3new[3*index+2]);
        }
    }
    
    if (perspNum == 1){
        if (pos[3] != 0) {
            c = cos(-pos[3]);
            s = sin(-pos[3]);
            for ( index = 0; index < ncols; index++ ) {
                temp = c*coord3new[3*index] - s*coord3new[3*index+1];
                coord3new[3*index+1] = s*coord3new[3*index] + c*coord3new[3*index+1];
                coord3new[3*index] = temp;
            }
        }
    }
    else {
        for (offset = 0; offset < perspNum*3*ncols; offset+=3*ncols) {
            if (pos[3] != 0) {
                c = cos(-pos[3]);
                s = sin(-pos[3]);
                for ( index = 0; index < ncols; index++ ) {
                    temp = c*coord3new[3*index] - s*coord3new[3*index+1];
                    coord3new[offset + 3*index+2] = coord3new[3*index+2];
                    coord3new[offset + 3*index+1] = s*coord3new[3*index] + c*coord3new[3*index+1];
                    coord3new[offset + 3*index] = temp;
                    // z[offset + index] = z[index];
                }
            }
            pos[3] = pos[3] + (2*3.1416)/perspNum; //rotate perspective
        }
    }
    return;
}