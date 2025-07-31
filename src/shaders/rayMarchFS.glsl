float plane(vec3 p, vec3 n) {
    return dot(p, n);
}

float sphere(vec3 p, float r) {
    return length(p) - r;
}

// referenced afl_ext
// https://www.shadertoy.com/view/MdXyzX
// and Acerola
// https://www.youtube.com/watch?v=PH9q0HNBjT4
// fractional brownian motion
float getWaves(vec2 position, int iterations) {
    float rand = 0.0;
    float weight = 1.0;
    float frequency = 1.0;
    float sumOfValues = 0.0;
    float sumOfWeights = 0.0;

    // sum of waves (waves with different weight and frequency)
    // iterations = number of waves
    // -> will have finer detail (since weight decreases and frequency increases)
    for (int i = 0; i < iterations; i++) {
        // this gives a random normalized vector
        vec2 direction = vec2(sin(rand), cos(rand));

        float x = dot(direction, position) * frequency + time * 10.0;
        float y = weight * exp(sin(x) - 1.0) * 0.25;

        sumOfValues += y;
        sumOfWeights += weight;

        // for next iteration:

        // domain warping
        float yPrime = y * cos(x);
        position += yPrime;

        weight = mix(weight, 0.0, 0.2); // less than 1
        frequency *= 1.18; // greater than 1
        rand += 1232.399963;
    }

    return sumOfValues / sumOfWeights;
}

float water(vec3 p) {
    float h = getWaves(p.xz, 5);
    return p.y - h;
}

vec2 circleMovement(float speed, float radius) {
    float angle = time * speed;
    angle *= (PI / 180.0);
    return radius * vec2(cos(angle), sin(angle));
}

vec4 opUnion(vec4 d1, vec4 d2) {
    return mix(d2, d1, step( abs(d1.x), abs(d2.x) ));
}

#if SCENENUM == 1
vec4 basicScene(vec3 p) {
    vec4 res = vec4(1000.0);
    vec4 redBall = vec4( sphere(p - vec3(3.0, 1.0, 0.0), 1.0), RED_ID, p.xz );
    res = opUnion(res, redBall);

    vec4 greenBall = vec4( sphere(p - vec3(0.0, 1.0, 0.0), 1.0), GREEN_ID, p.xz );
    res = opUnion(res, greenBall);

    vec4 blueBall = vec4( sphere(p - vec3(-3.0, 1.0, 0.0), 1.0), BLUE_ID, p.xz );
    res = opUnion(res, blueBall);

    vec4 plane = vec4( plane(p - vec3(0.0), vec3(0.0, 1.0, 0.0)), GRAY_ID, p.xz );
    res = opUnion(res, plane);

    return res;
}

#elif SCENENUM == 2
vec4 waterSceneShadow(vec3 p) {
    vec4 res = vec4(1000.0);
    vec2 movement = circleMovement(10.0, 3.0);
    vec4 beachBall = vec4( sphere(p - vec3(movement.x, 1.0, movement.y), 1.0), BEACH_BALL_ID, p.xz );
    res = opUnion(res, beachBall);

    // removed water

    vec4 bottom = vec4( plane(p - vec3(0.0, -3.0, 0.0), vec3(0.0, 1.0, 0.0)), WALL_ID, p.xz );
    res = opUnion(res, bottom);

    return res;
}

vec4 waterScene(vec3 p) {
    vec4 res = vec4(1000.0);
    vec2 movement = circleMovement(10.0, 3.0);
    vec4 beachBall = vec4( sphere(p - vec3(movement.x, 1.0, movement.y), 1.0), BEACH_BALL_ID, p.xz );
    res = opUnion(res, beachBall);

    // included water
    vec4 water = vec4( water(p), WATER_ID, p.xz );
    res = opUnion(res, water);
    // vec4 water = vec4( plane(p - vec3(0.0, -1.0, 0.0), vec3(0.0, 1.0, 0.0)), WATER_ID, p.xz );
    // res = opUnion(res, water);

    vec4 bottom = vec4( plane(p - vec3(0.0, -3.0, 0.0), vec3(0.0, 1.0, 0.0)), WALL_ID, p.xz );
    res = opUnion(res, bottom);

    return res;
}
#endif

vec4 SDF(vec3 p, float isShadow) {
#if SCENENUM == 1
    return basicScene(p);
#elif SCENENUM == 2
    return mix(waterScene(p), waterSceneShadow(p), step(0.5, isShadow));
#endif
}

vec3 getNormal(vec3 p) {
    vec2 h = vec2(EPS, 0.0);
    return normalize(
        vec3(
            SDF(p + h.xyy, 0.0).x - SDF(p - h.xyy, 0.0).x,
            SDF(p + h.yxy, 0.0).x - SDF(p - h.yxy, 0.0).x,
            SDF(p + h.yyx, 0.0).x - SDF(p - h.yyx, 0.0).x
        )
    );
}

void rayMarch(in Ray ray, float mint, inout Hit hit) {
    float t = mint;
    vec4 res;

    for (int i = 0; i < MAX_MARCH_STEPS; i++) {
        vec3 p = ray.o + ray.d * t;
        res = SDF(p, 0.0);
        float d = abs(res.x);
        if (d < EPS || t > MAX_T) break;
        t += d;
    }

    hit.t = t;
    hit.p = ray.o + ray.d * hit.t;
    hit.n = getNormal(hit.p);
    hit.n = mix(hit.n, -hit.n, step(0.0, dot(hit.n, ray.d)));
    hit.v = -ray.d;
    hit.m = res.yzw;
}