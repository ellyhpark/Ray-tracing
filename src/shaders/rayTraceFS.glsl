void getReflectRay(in Ray incidentRay, in Hit hit, out Ray secondRay) {
    secondRay.o = hit.p;
    secondRay.d = reflect(incidentRay.d, hit.n);
}

void getRefractRay(in Ray incidentRay, in Hit hit, out Ray secondRay, float nr) {
    secondRay.o = hit.p;
    secondRay.d = refract(incidentRay.d, hit.n, nr);
}

float getR0(float ni, float nt) {
    return ((ni - nt) / (ni + nt)) * ((ni - nt) / (ni + nt));
}

float schlick(float R0, in Hit hit) {
    return R0 + (1.0 - R0) * pow( 1.0 - clamp(dot(hit.v, hit.n), 0.0, 1.0), 5.0 );
}

#if RAY_TWO
// return the result of shadow ray only
vec3 rayTraceSecond(in Ray ray) {
    Hit hit;
    rayMarch(ray, 0.1, hit);
    if (hit.t > MAX_T) return getSkyGradient( ray.d );

    // direct illumination
    // shadow
    Direct direct;
    direct.shadow = shade(hit);

    applyFog(direct.shadow, ray.d, hit.t);
    return direct.shadow;
}

#elif RAY_THREE
// return the result of shadow ray only
vec3 rayTraceThird(in Ray ray) {
    Hit hit;
    rayMarch(ray, 0.1, hit);
    if (hit.t > MAX_T) return getSkyGradient( ray.d );

    // direct illumination
    // shadow
    Direct direct;
    direct.shadow = shade(hit);

    applyFog(direct.shadow, ray.d, hit.t);
    return direct.shadow;
}

vec3 rayTraceSecond(in Ray ray) {
    Hit hit;
    rayMarch(ray, 0.1, hit);
    if (hit.t > MAX_T) return getSkyGradient( ray.d );

    // direct illumination
    // shadow
    Direct direct;
    direct.shadow = shade(hit);

    // indirect illumination
    Indirect indirect;
    Ray rayThird;
    Material m = getMaterial(hit);
    // reflection
    getReflectRay(ray, hit, rayThird);
    indirect.reflection = (1.0 - m.transparency) * rayTraceThird(rayThird);
    // refraction
    // iors.x = ni, iors.y = nt
    vec2 iors = mix( vec2(AIR_IOR, m.ior), vec2(m.ior, AIR_IOR), step(0.0, dot(hit.n, ray.d)) );
    getRefractRay(ray, hit, rayThird, (iors.x / iors.y));
    indirect.refraction = m.transparency * rayTraceThird(rayThird);

    // Fresnel term (Schlick's approximation)
    float F = schlick(getR0(iors.x, iors.y), hit);
    vec3 color = (direct.shadow + indirect.refraction) * (1.0 - F)
            + (indirect.reflection * F);

    applyFog(color, ray.d, hit.t);
    return color;
}
#endif

vec3 rayTrace(in Ray ray) {
    Hit hit;
    rayMarch(ray, 0.1, hit);
    if (hit.t > MAX_T) return getSkyGradient( ray.d );

    // direct illumination
    // shadow
    Direct direct;
    direct.shadow = shade(hit);

    // indirect illumination
    Indirect indirect;
    Ray raySecond;
    Material m = getMaterial(hit);
    // reflection
    getReflectRay(ray, hit, raySecond);
    indirect.reflection = (1.0 - m.transparency) * rayTraceSecond(raySecond);
    // refraction
    // iors.x = ni, iors.y = nt
    vec2 iors = mix( vec2(AIR_IOR, m.ior), vec2(m.ior, AIR_IOR), step(0.0, dot(hit.n, ray.d)) );
    getRefractRay(ray, hit, raySecond, (iors.x / iors.y));
    indirect.refraction = (m.transparency) * rayTraceSecond(raySecond);

    // Fresnel term (Schlick's approximation)
    float F = schlick(getR0(iors.x, iors.y), hit);
    vec3 color = (direct.shadow + indirect.refraction) * (1.0 - F)
            + (indirect.reflection * F);

    applyFog(color, ray.d, hit.t);
    return color;
}