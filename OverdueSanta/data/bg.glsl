// Author:
// Title:

#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform float u_offset_y;

vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))
                * 43758.5453123);
}

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                        0.366009403784439,  // 0.5*(sqrt(3.0)-1.0)
                        -0.577350269189626,  // -1.0 + 2.0 * C.x
                        0.024390243902439); // 1.0 / 41.0
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);
    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289(i); // Avoid truncation effects in permutation
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
        + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

float level(vec2 st) {
    float n = 0.0;
    for (float i = 1.0; i < 8.0; i ++) {
        float m = pow(2.0, i);
        n += snoise(st * m) * (1.0 / m);
    }
    return n * 0.5 + 0.5;
}

vec3 normal(vec2 st) {
    float d = 0.0001;
    float l0 = level(st);
    float l1 = level(st + vec2(d, 0.0)); // slightly offset the x-coord
    float l2 = level(st + vec2(0.0, d)); // slightly offset the y-coord
    // return normalized vector perpendicular to the surface using the noise values as the elevation of these points
    return normalize(vec3(-(l1 - l0), -(l2 - l0), d));
}

//https://en.wikipedia.org/wiki/Phong_reflection_model
vec3 phong(vec2 st, vec3 normal, vec3 lightPos) {
    vec3 lightDir = normalize(vec3(lightPos - vec3(st, 0.0)));
    float diffuse = max(0.0, dot(normal, lightDir));
    vec3 vReflection = normalize(reflect(-lightDir, normal));
    float specular = pow(max(0.0, dot(normal, vReflection)), 8.0);
    vec3 ambientColor = vec3(0.1,0.0,0.2);
    vec3 diffuseColor = vec3(0.0,0.5,0.2);
    return min(vec3(1.0), ambientColor + diffuseColor * diffuse + specular);
}

vec2 brickTile(vec2 _st, float _zoom){
    _st *= _zoom;

    // Here is where the offset is happening
    _st.x += step(1., mod(_st.y,2.0)) * 0.5;

    return fract(_st);
}

float box(vec2 _st, vec2 _size){
    _size = vec2(0.5)-_size*0.5;
    vec2 uv = smoothstep(_size,_size+vec2(1e-4),_st);
    uv *= smoothstep(_size,_size+vec2(1e-4),vec2(1.0)-_st);
    return uv.x*uv.y;
}

void main() {
    float BRICK_EDGE_WIDTH = 200.0;
    float GRADIENT_WIDTH = u_resolution.x / 2.0;
    vec2 st = gl_FragCoord.xy/u_resolution.xy;
    st.x *= u_resolution.x/u_resolution.y;
    
    float x = gl_FragCoord.x;
    float y = gl_FragCoord.y + u_offset_y;
    
    float t = u_offset_y;

    vec3 color = vec3(0.);
    float edgeDistance = min(x, u_resolution.x - x);
    bool isBrick = edgeDistance <= BRICK_EDGE_WIDTH;
    edgeDistance -= BRICK_EDGE_WIDTH;
    float yRelative = y / u_resolution.y;
    edgeDistance += (sin(yRelative + 60.0) + 1.0) * 2.0;
    edgeDistance += (cos(yRelative + 100.0) + 1.0) * 2.0;
    edgeDistance += (cos(yRelative + 7.0) + 1.0) * 4.0;
    edgeDistance = max(0, edgeDistance);
    //float alpha = 0.5;
    float centerGradientOpacity = 1.0 - max(0.0, GRADIENT_WIDTH-edgeDistance) / GRADIENT_WIDTH;

    gl_FragColor = vec4(color, 1.0);
    
    
    float lightPosX = 0.5, lightPosY = 0.5;
    vec3 col = phong(st, normal(st+ vec2(0, yRelative)), vec3(lightPosX, lightPosY, 1.0));
    float backgroundVal = col.z + col.x + col.y;
    float height = level(st + vec2(0, yRelative));
    col = (backgroundVal * 0.7) * vec3(0.84765625, 0.390625, 0.0859375);
    
    
    if (isBrick) {
        st = brickTile(st + vec2(0.0, yRelative), 10.0);

        
        col = pow(backgroundVal, 0.5) * vec3(0.90625, 0.37890625, 0.1171875) + 0.05;
        col *= box(st, vec2(0.85));
        if (backgroundVal > 0.9)
            col -= backgroundVal * 0.2;
    }
    else {
        col = col * centerGradientOpacity;
    }
    
    gl_FragColor=vec4(col,1);
}
