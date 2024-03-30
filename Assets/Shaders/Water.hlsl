#include "UnityCG.cginc"
#include "UnityLightingCommon.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "HSV.hlsl"
#include "Noise.hlsl"

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

    // v.vertexOS.y += sin(_Time.y * 0.5) * 0.1;
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

    // Refraction
    float2 offsetUV = (Unity_GradientNoise_float(uv / _RefractionScale + _Time * _RefractionSpeed, 1) * 2 - 1) * _RefractionStrength + uv;

    // Update UV and depth based on refraction
    uv = lerp(uv, offsetUV, saturate(waterDepth));
    scenePosWS = getScenePosWS(uv);
    waterDepth = (i.posWS - scenePosWS).y;
    float depth = saturate(exp(-waterDepth / _DepthFadeDist));

    // Color
    float4 color;
    HSVLerp_half(_DeepColor, _ShallowColor, depth, color);
    color.rgb = RGBToHSV(color.rgb);
    color.yz = floor(color.yz * _ShadeBitDepth) / _ShadeBitDepth;
    color.rgb = HSVToRGB(color.rgb);

    // Shadow
    float4 shadow = SHADOW_ATTENUATION(i);
    return shadow;
    color *= shadow;

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