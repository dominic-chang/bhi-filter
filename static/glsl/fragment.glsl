#define M_PI radians(180.)
#define D1MACH1 1.175494351e-38
#define D1MACH2 3.402823466e+38
#define D1MACH3 1e-7

uniform sampler2D textureft;
uniform vec2 uResolution;
uniform float theta;
varying vec2 vUv;



vec2 c_p(vec2 x, vec2 y){
    return vec2(x[0]+y[0], x[1]+y[1]);
}

vec2 c_m(vec2 x, vec2 y){
    return vec2(x[0]*y[0] - x[1]*y[1] , x[0]*y[1] + x[1]*y[0]);
}

vec2 c_d(vec2 x, vec2 y){
    return c_m(x, vec2(y[0], -y[1]))/(pow(y[0], 2.)+pow(y[1],2.));
}

vec2 c_pow(vec2 x, float y){
    float mag = pow(sqrt(x[0]*x[0] + x[1]*x[1]), y);
    float angle = y*(atan(x[1],x[0]));
    return vec2(mag*cos(angle), mag*sin(angle));
}



float DRF(float X, float Y, float Z){

    float ERRTOL = pow(4.0*D1MACH3, 1.0/6.0);
    float LOLIM  = 5.0 * D1MACH1;
    float UPLIM  = D1MACH2/5.0;
    float C1 = 1.0/24.0;
    float C2 = 3.0/44.0;
    float C3 = 1.0/14.0;

    float ans = 0.0;
    if(min(min(X,Y),Z) < 0.0) {
        return ans;
    }

    if(max(max(X,Y),Z) > UPLIM){
        return ans;
    }

    if(min(min(X+Y,X+Z),Y+Z) < LOLIM){
        return ans;
    }

    float XN = X;
    float YN = Y;
    float ZN = Z;
    float MU = 0.;
    float XNDEV = 0.;
    float YNDEV = 0.;
    float ZNDEV = 0.;

    while(true){
        MU = (XN+YN+ZN)/3.0;
        XNDEV = 2.0 - (MU+XN)/MU;
        YNDEV = 2.0 - (MU+YN)/MU;
        ZNDEV = 2.0 - (MU+ZN)/MU;
        float EPSLON = max(max(abs(XNDEV),abs(YNDEV)),abs(ZNDEV));
        if(EPSLON < ERRTOL){break;}
        float XNROOT = sqrt(XN);
        float YNROOT = sqrt(YN);
        float ZNROOT = sqrt(ZN);
        float LAMDA = XNROOT*(YNROOT+ZNROOT) + YNROOT*ZNROOT;
        XN = (XN+LAMDA)*0.250;
        YN = (YN+LAMDA)*0.250;
        ZN = (ZN+LAMDA)*0.250;
    }

    float E2 = XNDEV*YNDEV - ZNDEV*ZNDEV;
    float E3 = XNDEV*YNDEV*ZNDEV;
    float S  = 1.0 + (C1*E2-0.10-C2*E3)*E2 + C3*E3;
    ans = S/sqrt(MU);

    return ans;
}

float rawF(float sinphi, float m){
    float sinphi2 = pow(sinphi, 2.0);
    float drf = DRF(1. - sinphi2, 1. - m*sinphi2, 1.);
    return sinphi*drf;
}

float K(float m){ return DRF(0., 1. - m, 1.);}

float F(float phi, float m){
    if(abs(phi) > M_PI/2.0){
        // Abramowitz & Stegun (17.4.3)
        float phi2 = phi + M_PI/2.0;
        float angle = (phi2/M_PI);
        return 2.0*floor(phi2 / M_PI)*K(m) - rawF(cos((angle - floor(angle))*M_PI), m);
    }
    return rawF(sin(phi), m);
}

float am(float u, float m, float tol){

    float ambuf[10];
    if(u == 0.){return 0.;}

    float sqrt_tol = sqrt(tol);
    if(m < sqrt_tol){
        // A&S 16.13.4
        return u - 0.25*m*(u - 0.5*sin(2.0*u));
    }
    float m1 = 1. - m;
    if(m1 < sqrt_tol){
        // A&S 16.15.4
        float t = tanh(u);
        return asin(t) + 0.25*m1*(t - u*(1. - pow(t, 2.)))*cosh(u);
    }

    float a = 1.;
    float b = sqrt(m1);
    float c = sqrt(m);
    int n = 0;
    while(abs(c) > tol){
        if(n>=10){ return 1.0/0.0;}
        float atemp = 0.5*(a+b);
        float btemp = sqrt(a*b); 
        float ctemp = 0.5*(a-b);
        a = atemp;
        b = btemp;
        c = ctemp;
        ambuf[n] = c/a;
        n = n + 1;
    }

    float phi = a*u*pow(2.,float(n));
    for(int i = n-1; i >= 0; i--){
        phi = 0.5*(phi + asin(ambuf[i]*sin(phi)));
    }
    return phi;
}

float sn(float u, float m){
    bool lt0 = m < 0.;
    bool gt1 = m > 1.;
    if (!(lt0) && !(gt1)){
        float phi = am(u, m, D1MACH3*2.);
        return sin(phi);
    } else if(lt0) {
        float mu1 = 1.0/(1.-m);
        float mu = -m*mu1;
        float sqrtmu1 = sqrt(mu1);
        float v = u/sqrtmu1;
        float phi = am(v, mu, D1MACH3*2.);

        float s = sin(phi);

        return sqrtmu1*s/sqrt(1.-mu*pow(s,2.));

    } else {
        float mu = 1. / m;
        float v = u * sqrt(m);
        float phi = am(v, mu, D1MACH3*2.);

        return sqrt(mu)*sin(phi);
    }
}

float cn(float u, float m){
    bool lt0 = m < 0.;
    bool gt1 = m > 1.;
    if (!(lt0) && !(gt1)){
        float phi = am(u, m, D1MACH3*2.);
        return cos(phi);
    } else if(lt0) {
        float mu1 = 1.0/(1.-m);
        float mu = -m*mu1;
        float sqrtmu1 = sqrt(mu1);
        float v = u/sqrtmu1;
        float phi = am(v, mu, D1MACH3*2.);

        float s = sin(phi);

        return cos(phi)/sqrt(1.-mu*pow(s,2.));

    } else {
        float mu = 1. / m;
        float v = u * sqrt(m);
        float phi = am(v, mu, D1MACH3*2.);

        return sqrt(1.- mu*pow(sin(phi),2.));
    }
}

float rsin(float mag, float psi){
    vec2 q = vec2(2.*mag*mag, 0.);
    vec2 p = vec2(-mag*mag, 0.);
    vec2 C1 = c_pow(-q/2. + c_pow(c_pow(q, 2.)/4. + c_pow(p, 3.)/27., 1./2.), 1./3.);
    vec2 C2 = c_m(C1, vec2(-1./2., sqrt(3.)/2.));
    vec2 C3 = c_m(C1, vec2(-1./2., -sqrt(3.)/2.));
    vec2 v4 = C1 - c_d(p, 3.*C1);
    vec2 v1 = C2 - c_d(p, 3.*C2);
    vec2 v3 = C3 - c_d(p, 3.*C3);

    vec2 v32 = v3;
    vec2 v21 = -v1;
    vec2 v41 = v4 - v1;
    vec2 v31 = v3 - v1;
    vec2 v42 = v4;


    float A = pow(c_m(v32, v42)[0], 0.5);
    float B = pow(c_m(v31, v41)[0], 0.5);
    
    
    float arg = sqrt(A*B)*(psi)/mag;
    if(mag*mag < 27.){
        float ellk = (pow(A + B, 2.) - pow(v1[0], 2.)) / (4.*A*B);
        float fo =F(acos((A-B)/(A+B)), ellk) ;
        if(arg < fo ){
            float can = cn(fo - arg, ellk);
            float num = -A*v1[0] + (A*v1[0])*can;
            float den = -A + B + (A+B)*can;
            return num/den;
        } else {return 0.0;}
    } else {

        float ellk = v32[0]*v41[0] / (v31[0]*v42[0]);
        float fo = F(asin(sqrt(v31[0]/v41[0])), ellk);
        if(arg < 4.*fo ){
            float san = v41[0]*pow(sn(fo - sqrt(v31[0]*v42[0])*psi/(2.*mag), ellk), 2.0);
            float num = v31[0]*v4[0]-v3[0]*san;
            float den = v31[0]-san;
            return num/den;
        } else {return 0.0;}
    }
}

float psimax(float mag){
    vec2 q = vec2(2.*mag*mag, 0.);
    vec2 p = vec2(-mag*mag, 0.);
    vec2 C1 = c_pow(-q/2. + c_pow(c_pow(q, 2.)/4. + c_pow(p, 3.)/27., 1./2.), 1./3.);
    vec2 C2 = c_m(C1, vec2(-1./2., sqrt(3.)/2.));
    vec2 C3 = c_m(C1, vec2(-1./2., -sqrt(3.)/2.));
    vec2 v4 = C1 - c_d(p, 3.*C1);
    vec2 v1 = C2 - c_d(p, 3.*C2);
    vec2 v3 = C3 - c_d(p, 3.*C3);

    vec2 v32 = v3;
    vec2 v21 = -v1;
    vec2 v41 = v4 - v1;
    vec2 v31 = v3 - v1;
    vec2 v42 = v4;


    
    float ellk = v32[0]*v41[0] / (v31[0]*v42[0]);
    return 4.*mag*F(asin(sqrt(v31[0]/v41[0])), ellk)/sqrt(v31[0]*v42[0]);
}


void main() {
    float scale = 15.0; // size of disk
    float scale2 = 40.;//size of horizon
    vec2 uv = 2. * scale2 * ((gl_FragCoord.xy ) / uResolution.xy - vec2(0.5 ,0.5)); 
    float x = uv.x;
    float y = uv.y;
    float mag = length(uv);
    float cosvarphi = x/mag;
    float costheta = cos(theta);
    float sinvarphi = sign(costheta)*y/mag;



    float tanvarphi = sinvarphi/abs(cosvarphi);
    float psi = acos(-((sin(theta)*tanvarphi) / 
        (pow(pow(costheta,2.0) + pow(tanvarphi,2.0), .5))));

    float rs = 0.0;
    float rs1 = 0.0;
    float phi = M_PI/2.*(1.+sign(costheta)) + M_PI*(1.-sign(y)) + sign(y)*acos(costheta*cosvarphi/sqrt(1.0-pow(sin(theta)*cosvarphi, 2.0)));
    float phi2 = phi + M_PI;


    if (mag*mag > 27.){
        rs = rsin(mag, psi);
        rs1 = rsin(mag, M_PI+ psi);


        float deltapsi = psimax(mag) - M_PI;
        vec2 texcrd = (gl_FragCoord.xy/uResolution.xy - vec2(0.5, 0.5));
        float texcrd2rad = length(texcrd);
        float new_length = tan(atan(texcrd2rad)-deltapsi)/(texcrd2rad);
        vec2 texcrd3 = new_length*texcrd/vec2(1.,3.) + vec2(0.5, 0.5+theta/(2.*M_PI));
        texcrd3 = vec2(texcrd3[0]- floor(texcrd3[0]), texcrd3[1]- floor(texcrd3[1]));
        gl_FragColor = texture2D(textureft, texcrd3);


        
    } else {
        rs = rsin(mag, psi);
        rs1 = rsin(mag, M_PI + psi);
        gl_FragColor = vec4(0., 0., 0., 1.);
    }
    
    if(rs < 2.0){
        gl_FragColor = vec4(0., 0., 0., 1.);
        return;
    }
    
    if (rs > 7.0 && rs < scale) {
        vec2 uv2 = rs*vec2(cos(phi),sin(phi))/(2.0*scale)  + vec2(0.5, 0.5) ;

    }
    if (rs1 > 7.0 && rs1 < scale){
        vec2 uv3 = rs1*vec2(cos(phi),sin(phi))/(2.0*scale)  + vec2(0.5, 0.5) ;
    }
}