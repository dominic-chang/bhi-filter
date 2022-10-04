#define M_PI radians(180.)
//3.1415926535897932384626433832795
#define D1MACH1 1.175494351e-38
#define D1MACH2 3.402823466e+38
#define D1MACH3 1e-7

uniform sampler2D texture1;
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
    float scale = 10.0; // size of disk
    float scale2 = 50.;//size of horizon
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

    //gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
    float phi = M_PI/2.*(1.+sign(costheta)) + M_PI*(1.-sign(y)) + sign(y)*acos(costheta*cosvarphi/sqrt(1.0-pow(sin(theta)*cosvarphi, 2.0)));
    float phi2 = phi + M_PI;


    if (mag*mag > 27.){
        float deltapsi = psimax(mag) - M_PI;
        vec2 texcrd = (gl_FragCoord.xy/uResolution.xy - vec2(0.5, 0.5));
        float texcrd2rad = length(texcrd);
        float new_length = tan(atan(texcrd2rad)-deltapsi)/(texcrd2rad);
        vec2 texcrd3 = new_length*texcrd/scale + vec2(0.5, 0.5);
        gl_FragColor = texture2D(texture1, texcrd);
        //gl_FragColor = vec4(sin(deltapsi));


        
    } else {
        gl_FragColor = vec4(0., 0., 0., 1.);
    }
    
}