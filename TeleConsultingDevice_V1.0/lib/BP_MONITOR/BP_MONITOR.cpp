#include "BP_MONITOR.h"

BP_MONITOR::BP_MONITOR(int DT, int SCK, int CON, int VLV, int PMP, void (*func)(float, bool))
{
    dt = DT;
    clk = SCK;
    con = CON;
    vlv = VLV;
    pmp = PMP;
    cb = func;
}

void BP_MONITOR::begin()
{
    pinMode(dt, INPUT);
    pinMode(clk, OUTPUT);
    pinMode(con, INPUT_PULLUP);
    pinMode(vlv, OUTPUT);
    pinMode(pmp, OUTPUT);
    digitalWrite(clk, LOW);
    digitalWrite(vlv, LOW);
    sigmaDeltaSetup(0, 78125);
    sigmaDeltaAttachPin(pmp, 0);
    sigmaDeltaWrite(0, 0);
}

bool BP_MONITOR::check(){
    return !digitalRead(con);
}

void BP_MONITOR::measureBP(float *sys, float *dia, float *pr)
{
    inflating = true;
    setPressure(150);
    inflating = false;
    takeReadingsUpto(50);
    releasePressure();
    uint16_t x[size];
    uint32_t y[size];
    uint16_t idx = 0;
    uint16_t prev_i;
    for (int i = 0; i < size; i++)
    {
        if (dp[i] > 0)
        {
            if (i && (i == prev_i + 1))
            {
                if (dp[i] > y[idx - 1])
                {
                    x[idx - 1] = i;
                    y[idx - 1] = dp[i];
                }
            }
            else
            {
                x[idx] = i;
                y[idx++] = dp[i];
            }
            prev_i = i;
        }
    }
    for (int i = 0; i < idx; i++)
    {
        Serial.printf("%3d\t%8d\n", x[i], dp[x[i]]);
    }
    *pr = pulse(x, idx);
    polyfit(x, y, idx, coeff, degree);
    Serial.printf("Y = (%.6f)x^4 + (%.6f)x^3 + (%.6f)x^2 + (%.6f)x + (%.4f)\n", coeff[4], coeff[3], coeff[2], coeff[1], coeff[0]);
    findmax(&x_max, &y_max, coeff, degree, x[idx / 2]);
    Serial.printf("Mean = %.1f mmHg\t", p[(int)round(x_max)] / scale);
    double sys_y = y_max * systolic_factor;
    double dys_y = y_max * diastolic_factor;
    double sys_x_init = (double)x[idx / 4];
    double dys_x_init = (double)x[3 * idx / 4];
    double sys_x = X(sys_y, coeff, degree, prec, sys_x_init);
    double dys_x = X(dys_y, coeff, degree, prec, dys_x_init);
    *sys = p[(int)ceil(sys_x)] / scale;
    *dia = p[(int)ceil(dys_x)] / scale;
    Serial.printf("Systolic = %.1f mmHg\t Diastolic = %.1f mmHg", p[(int)ceil(sys_x)] / 28237.07571, p[(int)ceil(dys_x)] / 28237.07571);
}

void BP_MONITOR::setPressure(int mmHg)
{
    digitalWrite(vlv, HIGH);
    uint32_t set = (int)(mmHg * scale);
    uint8_t pwm = 127;
    while (1)
    {
        delay(100);
        //calculate error
        long int err = set - readPressure();
        //Serial.print("Error: ");
        //Serial.print(err);
        //Serial.print("\tPWM: ");
        //Serial.println(pwm);
        //if set pressure is more increase power to pump
        if (err > 10000)
        {
            if (pwm < 150)
                pwm++;
            sigmaDeltaWrite(0, pwm);
        }

        //if set pressure is less decrease power to pump
        else if (err < -10000)
        {
            if (pwm > 125)
                pwm--;
            sigmaDeltaWrite(0, pwm);
        }

        //if set pressure is near exit
        else
        {
            sigmaDeltaWrite(0, 0);
            break;
        }
    }
}

uint32_t BP_MONITOR::readPressure()
{
    uint32_t res = 0;
    while (digitalRead(dt))
        ;
    for (int i = 24; i > 0; i--)
    {
        digitalWrite(clk, HIGH);
        delayMicroseconds(10);
        digitalWrite(clk, LOW);
        bool bit = digitalRead(dt);
        res <<= 1;
        res |= bit;
        delayMicroseconds(10);
    }
    digitalWrite(clk, HIGH);
    delayMicroseconds(10);
    digitalWrite(clk, LOW);
    delayMicroseconds(10);
    digitalWrite(clk, HIGH);
    delayMicroseconds(10);
    digitalWrite(clk, LOW);
    //Serial.print("Pressure: ");
    cb(res/scale, inflating);
    return res;
}

void BP_MONITOR::takeReadingsUpto(int mmHg)
{
    uint32_t set = (int)(mmHg * scale);
    uint32_t prev = 0;
    uint16_t i = 0;
    while (1)
    {
        if (micros() - prev >= period)
        {
            //Serial.println(micros()-prev);
            prev = micros();
            uint32_t data = readPressure();
            p[i] = data;
            Serial.println(data);
            if (i)
                dp[i] = p[i] - p[i - 1];
                //Serial.println(dp[i]);
            if (data <= set)
                break;
            i++;
        }
    }
    size = i;
}

void BP_MONITOR::releasePressure()
{
    //open valve
    digitalWrite(vlv, LOW);
}

void BP_MONITOR::polyfit(uint16_t *x, uint32_t *y, uint16_t N, double *a, int n)
{
    double X[2 * n + 1]; //Array that will store the values of sigma(xi),sigma(xi^2),sigma(xi^3)....sigma(xi^2n)
    for (int i = 0; i < 2 * n + 1; i++)
    {
        X[i] = 0;
        for (int j = 0; j < N; j++)
            X[i] = X[i] + pow(x[j], i); //consecutive positions of the array will store N,sigma(xi),sigma(xi^2),sigma(xi^3)....sigma(xi^2n)
    }

    double B[n + 1][n + 2]; //B is the Normal matrix(augmented) that will store the equations, 'a' is for value of the final coefficients
    for (int i = 0; i <= n; i++)
        for (int j = 0; j <= n; j++)
            B[i][j] = X[i + j]; //Build the Normal matrix by storing the corresponding coefficients at the right positions except the last column of the matrix

    double Y[n + 1]; //Array to store the values of sigma(yi),sigma(xi*yi),sigma(xi^2*yi)...sigma(xi^n*yi)
    for (int i = 0; i < n + 1; i++)
    {
        Y[i] = 0;
        for (int j = 0; j < N; j++)
            Y[i] = Y[i] + pow(x[j], i) * y[j]; //consecutive positions will store sigma(yi),sigma(xi*yi),sigma(xi^2*yi)...sigma(xi^n*yi)
    }

    for (int i = 0; i <= n; i++)
        B[i][n + 1] = Y[i]; //load the values of Y as the last column of B(Normal Matrix but augmented)
    n = n + 1;              //n is made n+1 because the Gaussian Elimination part below was for n equations, but here n is the degree of polynomial and for n degree we get n+1 equations

    for (int i = 0; i < n; i++) //From now Gaussian Elimination starts(can be ignored) to solve the set of linear equations (Pivotisation)
        for (int k = i + 1; k < n; k++)
            if (B[i][i] < B[k][i])
                for (int j = 0; j <= n; j++)
                {
                    double temp = B[i][j];
                    B[i][j] = B[k][j];
                    B[k][j] = temp;
                }

    for (int i = 0; i < n - 1; i++) //loop to perform the gauss elimination
        for (int k = i + 1; k < n; k++)
        {
            double t = B[k][i] / B[i][i];
            for (int j = 0; j <= n; j++)
                B[k][j] = B[k][j] - t * B[i][j]; //make the elements below the pivot elements equal to zero or elimnate the variables
        }

    for (int i = n - 1; i >= 0; i--) //back-substitution
    {                                //x is an array whose values correspond to the values of x,y,z..
        a[i] = B[i][n];              //make the variable to be calculated equal to the rhs of the last equation
        for (int j = 0; j < n; j++)
            if (j != i) //then subtract all the lhs values except the coefficient of the variable whose value                                   is being calculated
                a[i] = a[i] - B[i][j] * a[j];
        a[i] = a[i] / B[i][i]; //now finally divide the rhs by the coefficient of the variable to be calculated
    }
}

void BP_MONITOR::findmax(double *xptr, double *yptr, double *coeffs, int n, double x_init)
{
    double new_coeffs[n];
    for (int i = 1; i <= n; i++)
        new_coeffs[i - 1] = i * coeffs[i];
    *xptr = X(0, new_coeffs, n - 1, 2, x_init);
    *yptr = f(*xptr, n, coeffs);
}

double BP_MONITOR::X(double y, double *coeffs, int n, int prec, double x_init)
{
    double new_coeffs[n + 1];
    for (int i = 0; i <= n; i++)
    {
        if (i == 0)
            new_coeffs[i] = coeffs[i] - y;
        else
            new_coeffs[i] = coeffs[i];
    }
    double cur_x, prev_x = 0;
    cur_x = x_init - (f(x_init, n, new_coeffs) / df(x_init, n, new_coeffs));
    double error = abs((cur_x - prev_x) * pow(10, prec));
    while (error > 0)
    {
        prev_x = cur_x;
        cur_x = prev_x - (f(prev_x, n, new_coeffs) / df(prev_x, n, new_coeffs));
        error = abs((int)(cur_x - prev_x) * pow(10, prec));
    }
    return cur_x;
}

double BP_MONITOR::f(double x, int n, double *coeffs)
{
    double res = 0;
    for (int i = 0; i <= n; i++)
        res += coeffs[i] * pow(x, i);
    return res;
}

double BP_MONITOR::df(double x, int n, double *coeffs)
{
    double res = 0;
    for (int i = 1; i <= n; i++)
        res += (i)*coeffs[i] * pow(x, i - 1);
    return res;
}

float BP_MONITOR::pulse(uint16_t *x, uint16_t idx) {
    uint32_t sum = 0;
    for (int i = 1; i < idx; i++){
        sum += x[i] - x[i-1];
    }
    float res = sum / (float)(idx-1);
    Serial.println(res);
    res = res * period / 1000;
    return 60000 / res;
}