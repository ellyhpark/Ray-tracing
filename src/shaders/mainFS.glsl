varying vec2 vUv;

uniform mat4 camProjectionMatrixInverse;
uniform mat4 camWorldMatrix;

uniform vec3 lights[1];
uniform vec3 lightsCol[1];

uniform float time;

uniform sampler2D textures[2];

#define RAY_TWO 1
#define RAY_THREE 0

#define EPS 0.001
#define PI 3.14159265359
#define AIR_IOR 1.0003
#define GLASS_IOR 1.5
#define WATER_IOR 1.333
#define PLASTIC_IOR 1.460

#define MAX_MARCH_STEPS 500
#define MAX_T 64.0
#define BKGCOL vec3(0.2667, 0.5569, 0.8863)*0.5
#define FOG_DENSITY 0.0025

// material IDs:
#define RED_ID 1.0
#define GREEN_ID 2.0
#define BLUE_ID 3.0
#define GRAY_ID 4.0
#define WATER_ID 5.0
#define BEACH_BALL_ID 6.0
#define WALL_ID 7.0

struct Ray {
    vec3 o;
    vec3 d;
};

struct Material {
    vec3 albedo;
    float shininess;
    float ior;
    float transparency;
};

struct Hit {
    float t;
    vec3 p;
    vec3 n;
    vec3 v;
    vec3 m; // m.x = material ID, m.yz = uv
};

struct Direct {
    vec3 shadow;
};

struct Indirect {
    vec3 reflection;
    vec3 refraction;
};

#include rayMarchFS.glsl

#include materialsFS.glsl

#include lightCalcFS.glsl

#include rayTraceFS.glsl

void main() {
    // to world space and perspective frustum
    vec4 fragPos = vec4(vUv * 2.0 - 1.0, -1.0, 1.0); // from uv to clip space
    fragPos = camWorldMatrix * (camProjectionMatrixInverse * fragPos); // to world space
    Ray ray;
    ray.o = cameraPosition;
    ray.d = normalize(fragPos.xyz / fragPos.w - ray.o);

    // we have ro and rd (per fragment)

    vec3 color = rayTrace(ray);
    color = pow(color, vec3(1.0 / 2.2)); // gamma correction
    gl_FragColor = vec4(color, 1.0);
}