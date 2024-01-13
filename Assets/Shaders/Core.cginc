float remap(float value, float low1, float high1, float low2, float high2)
{
    return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

// sRBG to luma
// https://en.wikipedia.org/wiki/Luma_(video)
float luminance(float3 color)
{
    return dot(color, float3(0.299, 0.587, 0.114));
}

float luminance(float4 color)
{
    return luminance(color.rgb);
}