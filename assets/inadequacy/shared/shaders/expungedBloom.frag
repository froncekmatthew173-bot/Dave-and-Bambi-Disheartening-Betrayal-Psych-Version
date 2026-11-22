#pragma header

uniform float bloomStrength;
uniform float exposure;

vec3 saturate(vec3 x)
{
    return clamp(x, 0.0, 1.0);
}

vec3 getColor(vec2 uv)
{
    return texture2D(bitmap, uv).rgb;
}

vec3 brightPass(vec3 color)
{
    float brightness = max(
        max(color.r, color.g),
        color.b
    );

    // Much higher threshold so normal pixels don't bloom.
    float mask = smoothstep(0.75, 1.0, brightness);

    return color * mask;
}

vec3 getBloom(vec2 uv)
{
    vec2 texel = 1.0 / openfl_TextureSize;

    vec3 bloom = vec3(0.0);

    // Small blur
    bloom += brightPass(getColor(uv + texel * vec2( 2.0,  0.0))) * 0.08;
    bloom += brightPass(getColor(uv + texel * vec2(-2.0,  0.0))) * 0.08;
    bloom += brightPass(getColor(uv + texel * vec2( 0.0,  2.0))) * 0.08;
    bloom += brightPass(getColor(uv + texel * vec2( 0.0, -2.0))) * 0.08;

    bloom += brightPass(getColor(uv + texel * vec2( 4.0,  4.0))) * 0.05;
    bloom += brightPass(getColor(uv + texel * vec2(-4.0,  4.0))) * 0.05;
    bloom += brightPass(getColor(uv + texel * vec2( 4.0, -4.0))) * 0.05;
    bloom += brightPass(getColor(uv + texel * vec2(-4.0, -4.0))) * 0.05;

    return bloom;
}

void main()
{
    vec2 uv = openfl_TextureCoordv;

    vec4 source = texture2D(bitmap, uv);

    vec3 color = source.rgb;

    // Very small exposure adjustment.
    color *= exposure;

    // Subtle bloom.
    color += getBloom(uv) * bloomStrength;

    // Keep the normal game colors intact.
    color = saturate(color);

    gl_FragColor = vec4(color, source.a);
}