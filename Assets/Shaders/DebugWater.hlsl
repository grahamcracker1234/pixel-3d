#include "UnityCG.cginc"
#include "UnityLightingCommon.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "HSV.hlsl"
#include "Noise.hlsl"

float _DebugLevel;

struct appdata
{
    float4 vertexOS : POSITION;
};

struct v2f
{
    float4 posCS : SV_POSITION;
    float4 posWS : TEXCOORD0;
    float4 posSS : TEXCOORD1;
    float4 posLS : TEXCOORD3;
    SHADOW_COORDS(2)
};

float _DepthFadeDist;
float4 _DeepColor;
float4 _ShallowColor;
float _ShadeBitDepth;

float _RefractionSpeed;
float _RefractionStrength;
float _RefractionScale;

float _RefractionDepthFix;

sampler2D _CameraDepthTexture;
sampler2D _CameraOpaqueTexture;
sampler2D _CameraMotionVectorsTexture;

float getRawDepth(float2 uv) { 
    return SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, float4(uv, 0, 0)); 
}

float3 getScenePosWS(float2 uv)
{
    // Rendering parameters
    float near = _ProjectionParams.y;
    float far = _ProjectionParams.z;
    float2 orthoSize = unity_OrthoParams.xy;
    float isOrtho = unity_OrthoParams.w;

    float z = getRawDepth(uv);
    float2 uvCS = uv * 2 - 1;

    // Perspective
    float3 rayVSPersp = mul(unity_CameraInvProjection, float4(uvCS, 1, 1) * far);
    float3 posVSPersp = rayVSPersp * Linear01Depth(z);

    // Orthographic
    float3 rayVSOrtho = float3(uvCS * orthoSize, 0);
    #if defined(UNITY_REVERSED_Z)
        float depthOrtho = -lerp(far, near, z);
    #else
        float depthOrtho = -lerp(near, far, z);
    #endif
    float3 posVSOrtho = float3(rayVSOrtho.xy, depthOrtho);

    // Blending
    float3 posVS = lerp(posVSPersp, posVSOrtho, isOrtho);
    float3 scenePosWS = mul(unity_CameraToWorld, float4(posVS.xy, -posVS.z, 1)).xyz;

    // Far plane exclusion
    #if !defined(EXCLUDE_FAR_PLANE)
        float mask = 1;
    #elif defined(UNITY_REVERSED_Z)
        float mask = z > 0;
    #else
        float mask = z < 1;
    #endif

    return scenePosWS * mask;
}

v2f vert(appdata v)
{
    v2f o;
    o.posCS = UnityObjectToClipPos(v.vertexOS);
    o.posWS = mul(unity_ObjectToWorld, v.vertexOS);
    o.posSS = ComputeScreenPos(o.posCS);

    #if defined(DIRECTIONAL_COOKIE)
        o.posLS = mul(unity_WorldToLight, o.posWS);
    #else 
        o.posLS = 0;
    #endif

    TRANSFER_SHADOW(o)

    return o;
}

fixed4 frag(v2f i) : SV_Target
{
    // Original UV and depth
    float2 uv = i.posSS.xy / i.posSS.w;
    float3 scenePosWS = getScenePosWS(uv);
    float waterDepth = (i.posWS - scenePosWS).y;
    float scaledWaterDepth = saturate(exp(-waterDepth / _DepthFadeDist));

    if (_DebugLevel <= -1) {
        float4 dbg_color;
        HSVLerp_half(_DeepColor, _ShallowColor, 0.5, dbg_color);
        return dbg_color;
    }

    if (_DebugLevel <= 0) {
        return float4(1 - waterDepth.xxx, 1);
    }

    if (_DebugLevel <= 1) {
        float dbg_depth = saturate(exp(-waterDepth / _DepthFadeDist));
        return float4(dbg_depth.xxx, 1);
    }

    if (_DebugLevel <= 2) {
        float dbg_depth = saturate(exp(-waterDepth / _DepthFadeDist));
        float4 dbg_color;
        HSVLerp_half(_DeepColor, _ShallowColor, dbg_depth, dbg_color);
        return dbg_color;
    }

    if (_DebugLevel <= 3) {
        float dbg_depth = saturate(exp(-waterDepth / _DepthFadeDist));
        float4 dbg_color;
        HSVLerp_half(_DeepColor, _ShallowColor, dbg_depth, dbg_color);
        dbg_color.rgb = RGBToHSV(dbg_color.rgb);
        dbg_color.yz = floor(dbg_color.yz * _ShadeBitDepth) / _ShadeBitDepth;
        dbg_color.rgb = HSVToRGB(dbg_color.rgb);
        return dbg_color;
    }

    if (_DebugLevel <= 4) {
        float2 dbg_offsetXZ_WS = (Unity_GradientNoise_float(i.posWS.xz / _RefractionScale + -_Time * _RefractionSpeed, 1) * 2 - 1) * _RefractionStrength + i.posWS.xz;
        float4 dbg_offsetWS = float4(dbg_offsetXZ_WS.x, i.posWS.y, dbg_offsetXZ_WS.y, 1);
        float4 dbg_offsetOS = mul(unity_WorldToObject, dbg_offsetWS);
        float4 dbg_offsetCS = UnityObjectToClipPos(dbg_offsetOS);
        float4 dbg_offsetSS = ComputeScreenPos(dbg_offsetCS);
        float2 dbg_offsetUV = dbg_offsetSS.xy / dbg_offsetSS.w;

        float2 dbg_mixUV = dbg_offsetUV;
        float3 dbg_mixScenePosWS = getScenePosWS(dbg_mixUV);
        float dbg_mixWaterDepth = (i.posWS - dbg_mixScenePosWS).y;
        float dbg_depth = saturate(exp(-dbg_mixWaterDepth / _DepthFadeDist));

        float4 dbg_color;
        HSVLerp_half(_DeepColor, _ShallowColor, dbg_depth, dbg_color);
        dbg_color.rgb = RGBToHSV(dbg_color.rgb);
        dbg_color.yz = floor(dbg_color.yz * _ShadeBitDepth) / _ShadeBitDepth;
        dbg_color.rgb = HSVToRGB(dbg_color.rgb);
        return dbg_color;
    }

    if (_DebugLevel <= 5) {
        float2 dbg_offsetXZ_WS = (Unity_GradientNoise_float(i.posWS.xz / _RefractionScale + -_Time * _RefractionSpeed, 1) * 2 - 1) * _RefractionStrength + i.posWS.xz;
        float4 dbg_offsetWS = float4(dbg_offsetXZ_WS.x, i.posWS.y, dbg_offsetXZ_WS.y, 1);
        float4 dbg_offsetOS = mul(unity_WorldToObject, dbg_offsetWS);
        float4 dbg_offsetCS = UnityObjectToClipPos(dbg_offsetOS);
        float4 dbg_offsetSS = ComputeScreenPos(dbg_offsetCS);
        float2 dbg_offsetUV = dbg_offsetSS.xy / dbg_offsetSS.w;

        float2 dbg_mixUV = lerp(uv, dbg_offsetUV, saturate(waterDepth));
        float3 dbg_mixScenePosWS = getScenePosWS(dbg_mixUV);
        float dbg_mixWaterDepth = (i.posWS - dbg_mixScenePosWS).y;
        float dbg_depth = saturate(exp(-dbg_mixWaterDepth / _DepthFadeDist));

        float4 dbg_color;
        HSVLerp_half(_DeepColor, _ShallowColor, dbg_depth, dbg_color);
        dbg_color.rgb = RGBToHSV(dbg_color.rgb);
        dbg_color.yz = floor(dbg_color.yz * _ShadeBitDepth) / _ShadeBitDepth;
        dbg_color.rgb = HSVToRGB(dbg_color.rgb);
        return dbg_color;
    }

    if (_DebugLevel <= 6) {
        float2 dbg_offsetXZ_WS = (Unity_GradientNoise_float(i.posWS.xz / _RefractionScale + -_Time * _RefractionSpeed, 1) * 2 - 1) * _RefractionStrength + i.posWS.xz;
        float4 dbg_offsetWS = float4(dbg_offsetXZ_WS.x, i.posWS.y, dbg_offsetXZ_WS.y, 1);
        float4 dbg_offsetOS = mul(unity_WorldToObject, dbg_offsetWS);
        float4 dbg_offsetCS = UnityObjectToClipPos(dbg_offsetOS);
        float4 dbg_offsetSS = ComputeScreenPos(dbg_offsetCS);
        float2 dbg_offsetUV = dbg_offsetSS.xy / dbg_offsetSS.w;

        float2 dbg_mixUV = lerp(uv, dbg_offsetUV, saturate(waterDepth));
        float3 dbg_mixScenePosWS = getScenePosWS(dbg_mixUV);
        float dbg_mixWaterDepth = (i.posWS - dbg_mixScenePosWS).y;
        float dbg_depth = saturate(exp(-dbg_mixWaterDepth / _DepthFadeDist));

        // bool dbg_shouldRefract = dbg_mixWaterDepth < -1;
        bool dbg_shouldRefract = smoothstep(-_RefractionDepthFix, 0, dbg_mixWaterDepth);
        dbg_depth *= dbg_shouldRefract;

        // return float4(dbg_shouldRefract.xxx, 1);

        float4 dbg_color;
        HSVLerp_half(_DeepColor, _ShallowColor, dbg_depth, dbg_color);
        dbg_color.rgb = RGBToHSV(dbg_color.rgb);
        dbg_color.yz = floor(dbg_color.yz * _ShadeBitDepth) / _ShadeBitDepth;
        dbg_color.rgb = HSVToRGB(dbg_color.rgb);
        return dbg_color;
    }

    // Refraction NEW (world space)
    float2 offsetXZ_WS = (Unity_GradientNoise_float(i.posWS.xz / _RefractionScale + -_Time * _RefractionSpeed, 1) * 2 - 1) * _RefractionStrength + i.posWS.xz;
    float4 offsetWS = float4(offsetXZ_WS.x, i.posWS.y, offsetXZ_WS.y, 1);
    float4 offsetOS = mul(unity_WorldToObject, offsetWS);
    float4 offsetCS = UnityObjectToClipPos(offsetOS);
    float4 offsetSS = ComputeScreenPos(offsetCS);
    float2 offsetUV = offsetSS.xy / offsetSS.w;
    
    // Update UV and depth based on refraction
    float2 mixUV = lerp(uv, offsetUV, saturate(waterDepth));
    float3 mixScenePosWS = getScenePosWS(mixUV);
    float mixWaterDepth = (i.posWS - mixScenePosWS).y;
    float depth = saturate(exp(-mixWaterDepth / _DepthFadeDist));

    // https://forum.unity.com/threads/weird-bug-with-the-refraction-on-my-water-shader.395727/ 
    // https://www.reddit.com/r/godot/comments/1argztb/water_refraction_shader_mask_out_objects_above/
    bool shouldRefract = smoothstep(-_RefractionDepthFix, 0, mixWaterDepth);
    depth *= shouldRefract;

    // Color
    float4 color;
    HSVLerp_half(_DeepColor, _ShallowColor, depth, color);
    color.rgb = RGBToHSV(color.rgb);
    color.yz = floor(color.yz * _ShadeBitDepth) / _ShadeBitDepth;
    color.rgb = HSVToRGB(color.rgb);

    // Shadow (NOT WORKING)
    //// float4 shadow = SHADOW_ATTENUATION(i);
    //// color *= shadow;

    // Cookie
    #if defined(DIRECTIONAL_COOKIE)
        float4 cookieAttenuation = tex2D(_LightTexture0, i.posLS.xy);
    #else
        float4 cookieAttenuation = 1;
    #endif

    // If _CameraOpaqueTexture is used, the following code can be used to blend the water with the scene
    // This would be preferred over using transparent shaders
    //// float4 baseColor = tex2D(_CameraOpaqueTexture, uv);
    //// float4 finalColor = float4(lerp(baseColor.rgb, color.rgb, color.a), 1);
    //// return finalColor * cookieAttenuation;

    return color * cookieAttenuation;
}