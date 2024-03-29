#include "UnityCG.cginc"
#include "HSV.hlsl"

struct appdata
{
    float4 vertexOS : POSITION;
};

struct v2f
{
    float4 posCS : SV_POSITION;
    float4 posWS : TEXCOORD0;
    float4 posSS : TEXCOORD1;
};

float _DepthFadeDist;
float4 _DeepColor;
float4 _ShallowColor;
float _ShadeBitDepth;

sampler2D _CameraDepthTexture;

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
    return o;
}

fixed4 frag(v2f i) : SV_Target
{
    float2 uv = i.posSS.xy / i.posSS.w;
    float3 scenePosWS = getScenePosWS(uv);
    float waterDepth = (i.posWS - scenePosWS).y;
    float depth = waterDepth / _DepthFadeDist;

    depth = saturate(exp(-depth));
    
    // return fixed4(depth.xxx, 1);

    // float4 color = lerp(_DeepColor, _ShallowColor, depth);
    float4 color;
    HSVLerp_half(_DeepColor, _ShallowColor, depth, color);
    // float4 color = lerp(_DeepColor, _ShallowColor, depth);

    color.rgb = RGBToHSV(color.rgb);

    // color.x = floor(color.x * _ShadeBitDepth) / _ShadeBitDepth;
    color.y = floor(color.y * _ShadeBitDepth) / _ShadeBitDepth;
    color.z = floor(color.z * _ShadeBitDepth) / _ShadeBitDepth;

    color.rgb = HSVToRGB(color.rgb);

    return color;
}