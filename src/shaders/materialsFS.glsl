// referenced DMGregory
// https://gamedev.stackexchange.com/questions/197931/how-can-i-correctly-map-a-texture-onto-a-sphere
vec3 equirectangularMap(in sampler2D tex, in Hit hit) {
    // 0 <= u, v <= 1
    // atan(y, x) returns the angle between the positive x-axis and the vector (x, y)
    float u = 0.5 - atan(hit.n.z, hit.n.x) / (2.0 * PI);
    float v = 0.5 + asin(hit.n.y) / PI;
    vec2 customUV = vec2(u, v);

    return texture(tex, customUV).rgb;
}

Material getMaterial(in Hit hit) {
    Material material;

    if (hit.m.x == RED_ID) {
        material.albedo = vec3(1.0, 0.0, 0.0);
        material.shininess = 32.0;
        material.ior = GLASS_IOR;
        material.transparency = 0.0;
    }
    else if (hit.m.x == GREEN_ID) {
        material.albedo = vec3(0.0, 1.0, 0.0);
        material.shininess = 32.0;
        material.ior = GLASS_IOR;
        material.transparency = 0.0;
    }
    else if (hit.m.x == BLUE_ID) {
        material.albedo = vec3(0.0, 0.0, 1.0);
        material.shininess = 32.0;
        material.ior = GLASS_IOR;
        material.transparency = 0.0;
    }
    else if (hit.m.x == GRAY_ID) {
        material.albedo = vec3(0.5);
        material.shininess = 32.0;
        material.ior = PLASTIC_IOR;
        material.transparency = 0.0;
    }
    else if (hit.m.x == WATER_ID) {
        material.albedo = vec3(0.0293, 0.0698, 0.1717);
        material.shininess = 32.0;
        material.ior = WATER_IOR;
        material.transparency = 0.35;
    }
    else if (hit.m.x == BEACH_BALL_ID) {
        material.albedo = equirectangularMap(textures[0], hit);
        material.shininess = 32.0;
        material.ior = PLASTIC_IOR;
        material.transparency = 0.1;
    }
    else if (hit.m.x == WALL_ID) {
        material.albedo = texture(textures[1], hit.m.yz * 0.1).rgb;
        material.shininess = 32.0;
        material.ior = PLASTIC_IOR;
        material.transparency = 0.0;
    }

    return material;
}