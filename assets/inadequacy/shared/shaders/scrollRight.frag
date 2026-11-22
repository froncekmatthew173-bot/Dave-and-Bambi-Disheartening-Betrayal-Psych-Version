#pragma header

// Horizontally scrolls a sprite's texture to the left and wraps it repeatedly.
// For the wrap to look seamless, the source image should tile horizontally.
uniform float uOffset;

void main()
{
    vec2 uv = openfl_TextureCoordv;
    uv.x = fract(uv.x + uOffset);
    gl_FragColor = flixel_texture2D(bitmap, uv);
}