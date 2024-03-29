#include "UnityCG.cginc"

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

sampler2D _CameraDepthTexture;

float getRawDepth(float2 uv) { 
    return SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, float4(uv, 0, 0)); 
}

float3 getScenePosWS(float2 uv)
{
    float3 rayVS = mul(unity_CameraInvProjection, float4(uv * 2 - 1, 1, 1) * _ProjectionParams.z);
    float3 posVS = rayVS * Linear01Depth(getRawDepth(uv));
    float3 scenePosWS = mul(unity_CameraToWorld, float4(posVS.xy, -posVS.z, 1)).xyz;
    return scenePosWS;
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
    float depth = saturate(waterDepth / _DepthFadeDist);

    return fixed4(depth.xxx, 1);
}