#include "mex.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

double calc_distance(double[], int, int, int, int);
double calc_Phi(double[], int, double, int, int);
void calc_fApEn(int, int, double, int, double[], double[]);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){

    // inputs, in order
    int m;
    int tau;
    double r;
    int N ;
    double *u = mxMalloc(N*sizeof(double));

	// output
    double *fApEn;

    int mrows;
    int ncols;

    /* Check for proper number of arguments */
    if (nrhs != 5) {
    mexErrMsgTxt("Wrong amount of inputs");
    }

	/* Check for right type of inputs */

    mrows = mxGetM(prhs[0]);
    ncols = mxGetN(prhs[0]);
    if (!mxIsInt32(prhs[0]) || mxIsComplex(prhs[0]) || !(mrows == 1 && ncols == 1)) {
        mexErrMsgTxt("Input m must be a non-complex scalar integer.");
    }

    mrows = mxGetM(prhs[1]);
    ncols = mxGetN(prhs[1]);
    if (!mxIsInt32(prhs[1]) || mxIsComplex(prhs[1]) || !(mrows == 1 && ncols == 1)) {
        mexErrMsgTxt("Input tau must be a non-complex scalar integer.");
    }

    mrows = mxGetM(prhs[2]);
    ncols = mxGetN(prhs[2]);
    if (!mxIsDouble(prhs[2]) || mxIsComplex(prhs[2]) || !(mrows == 1 && ncols == 1)) {
        mexErrMsgTxt("Input r must be a non-complex scalar double.");
    }

    mrows = mxGetM(prhs[3]);
    ncols = mxGetN(prhs[3]);
    if (!mxIsInt32(prhs[3]) || mxIsComplex(prhs[3]) || !(mrows == 1 && ncols == 1)) {
        mexErrMsgTxt("Input N must be a non-complex scalar integer.");
    }

	/* Read inputs */
    m = (int) mxGetScalar(prhs[0]);
    tau = (int) mxGetScalar(prhs[1]);
    r = mxGetScalar(prhs[2]);
    N = (int) mxGetScalar(prhs[3]);
    u = mxGetPr(prhs[4]);

	/* Prepare output data. A pointer points to the location of fApEn */
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    fApEn = mxGetPr(plhs[0]);

    /* Call the fApEn subroutine */
    calc_fApEn(m, tau, r, N, u, fApEn);
}


void calc_fApEn(int m, int tau, double r, int N, double *u, double *fApEn){
    *fApEn = calc_Phi(u, N, r, m, tau) - calc_Phi(u, N, r, (m+1), tau);
}

double calc_distance(double *u, int i, int j, int m, int tau){

	double *d = mxMalloc(m*sizeof(double));
	double max_d;

	int k;
	for (k = 0; k<(m); k++){
		d[k] = u[i+k*tau] - u[j+k*tau];
	}

	max_d = fabs(d[0]);

	for (k = 0; k<m; k++){
		d[k] = fabs(d[k]);
		if (d[k] > max_d)
			max_d = d[k];
	}

    mxFree(d);

	return max_d;
}

double calc_mu(double distance, double r){

    double x;
    double mu;

    x = distance/r;

    mu = 0;
    if (x >= 0 && x <= 1)
        mu = 0.5*(2.0-pow(x,2));
    else if (x>1 && x<=2)
        mu = 0.5*(pow((2.0-x),2));

    return mu;
}


double calc_Phi(double *u, int N, double r, int m, int tau){

    double d;
    int i;
    int j;
    double Phi;
    int loop_end = (N-(m-1)*tau);

    double sum_ln_Ci = 0;
    double Ci;

	// calc_Ci
    for (i = 0; i < loop_end; i++){

        double sum_D = 0;

        for (j = 0; j < loop_end; j++){
            d = calc_distance(u, i, j, m, tau);
            sum_D = sum_D + calc_mu(d, r);
        }
        Ci = (1/((double)loop_end))*sum_D;

        sum_ln_Ci = sum_ln_Ci + log(Ci);
    }

    // calc_Phi
    Phi = (1/((double)loop_end))*sum_ln_Ci;
    return Phi;
}
