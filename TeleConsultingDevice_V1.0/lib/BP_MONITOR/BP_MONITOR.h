#ifndef BP_MONITOR_H
#define BP_MONITOR_H

#include "Arduino.h"

class BP_MONITOR {
    int dt;
    int clk;
    int con;
    int vlv;
    int pmp;
    void (*cb)(float, bool); 

    static const int degree = 4;
    static const int prec = 4;
    static const uint16_t period = 50000;
    const float scale = 28237.07571;
    const float systolic_factor = 0.593;
    const float diastolic_factor = 0.717;

    uint32_t p[1024];
    int dp[1024];
    uint16_t size;
    double coeff[degree+1];
    double x_max, y_max;
    bool inflating = false;

    public:
    BP_MONITOR(int DT, int SCK, int CON, int VLV, int PMP, void (*func)(float, bool));

    bool check();

    void begin();

    void measureBP(float* sys, float* dia, float* pr);

    void setPressure(int mmHg);

    void takeReadingsUpto(int mmHg);

    uint32_t readPressure();

    void releasePressure();

    void polyfit(uint16_t* x, uint32_t* y, uint16_t N, double* a, int n);

    void findmax(double* xptr, double* yptr, double* coeffs, int n, double x_init);

    double X(double y, double* coeffs, int n, int prec, double x_init);

    double f(double x, int n, double* coeffs);

    double df(double x, int n, double* coeffs);

    float pulse(uint16_t* x, uint16_t idx);

};

#endif