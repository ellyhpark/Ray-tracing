vec3 blinnPhong(in Hit hit, vec3 l, int i) {
    Material m = getMaterial(hit);

    vec3 diffuse = m.albedo * max(0.0, dot(l, hit.n));

    vec3 ks = vec3(1.0); // highlight color
    vec3 h = normalize(l + hit.v);
    vec3 specular = ks * pow(max(0.0, dot(hit.n, h)), m.shininess);

    return clamp(lightsCol[i] * (diffuse + specular), 0.0, 1.0);
}

// referenced Inigo Quilez
// https://iquilezles.org/articles/rmshadows/
float softShadow(vec3 hp, vec3 l, float mint, float k) {
    float penumbra = 1.0;
    float t = mint;
    
    for (int i = 0; i < MAX_MARCH_STEPS && t <= MAX_T; i++) {
        vec3 p = hp + l * t;
        
        #if SCENENUM == 2
            vec4 res = SDF(p, 1.0);
        #else
            vec4 res = SDF(p, 0.0);
        #endif

        float d = abs(res.x);
        if (d < EPS) return 0.0; // ray intersected (shadow case)
        penumbra = min(penumbra, k * d / t);
        t += d;
    }

    return clamp(penumbra, 0.0, 1.0); // ray barely/did not intersect (little/no shadow case)
}

vec3 shade(in Hit hit) {
    // emission
    vec3 ke = vec3(0.0);
    // ambient
    vec3 ka = getMaterial(hit).albedo;
    vec3 Ia = vec3(0.25);

    vec3 shading = ke + ka * Ia;

    for (int i = 0; i < lights.length(); i++) {
        shading += blinnPhong(hit, lights[i], i) * softShadow(hit.p, lights[i], 0.1, 8.0);
    }

    return clamp(shading, 0.0, 1.0); // since shading could be > 1.0
}

vec3 getSkyGradient(vec3 rd) {
    vec3 skyCol = BKGCOL;
    vec3 groundCol = skyCol * 3.0;
    float w = clamp(rd.y, 0.0, 1.0);
    return mix(groundCol, skyCol, w);
}

void applyFog(inout vec3 col, vec3 rd, float t) {
    float fogWeight = exp(t * -FOG_DENSITY); // as t increases, fogWeight goes to 0
    vec3 fog = getSkyGradient(rd);
    col = mix(fog, col, fogWeight);
}