#include "UnityCG.cginc"

struct appdata
{
    float4 vertex : POSITION;
    // float2 uv : TEXCOORD0;
};

struct v2f
{
    float4 pos : SV_POSITION;
    float4 worldPos : TEXCOORD0;
    float4 screenPos : TEXCOORD1;
    float depth : Depth;
    float3 viewDir : TEXCOORD2;
};

sampler2D _MainTex;
float4 _MainTex_ST;

float4 _Color;
float _DepthFadeDist;

// sampler2D _CameraDepthNormalsTexture;
sampler2D _CameraDepthTexture;
float4 _CameraDepthTexture_TexelSize;

float getRawDepth(float2 uv) { 
    return SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, float4(uv, 0.0, 0.0)); 
}
 
// inspired by keijiro's depth inverse projection
// https://github.com/keijiro/DepthInverseProjection
// constructs view space ray at the far clip plane from the screen uv
// then multiplies that ray by the linear 01 depth
float3 viewSpacePosAtScreenUV(float2 uv)
{
    float3 viewSpaceRay = mul(unity_CameraInvProjection, float4(uv * 2.0 - 1.0, 1.0, 1.0) * _ProjectionParams.z);
    float rawDepth = getRawDepth(uv);
    return viewSpaceRay * Linear01Depth(rawDepth);
}
 
float3 viewSpacePosAtPixelPosition(float2 vpos)
{
    float2 uv = vpos * _CameraDepthTexture_TexelSize.xy;
    return viewSpacePosAtScreenUV(uv);
}

v2f vert(appdata v)
{
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    o.screenPos = ComputeScreenPos(o.pos);
    o.depth = o.pos.z;
    // o.viewDir = normalize(UnityWorldSpaceViewDir(v.vertex));
    o.viewDir = UnityWorldSpaceViewDir(v.vertex);

    // float depth;
    // float3 normal;
    // DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, o.screenUV), depth, normal);

    // o.backgroundDepth = depth; 
    // o.backgroundDepth = Linear01Depth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(o.screenUV)).r); 


    // o.backgroundDepth = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(o.pos)));
    // o.backgroundDepth = tex2D(_CameraDepthTexture, o.screenUV);
    return o;
}

fixed4 frag(v2f i) : SV_Target
{
    // float depth;
    // float3 normal;
    // DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, i.screenUV), depth, normal);

    // float backgroundDepth = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenUV)));
    
    float2 screenUV = i.screenPos.xy / i.screenPos.w;
    // float sceneDepth = Linear01Depth(tex2D(_CameraDepthTexture, screenUV));

    float3 viewPos = viewSpacePosAtScreenUV(screenUV);
    float3 sceneWorldPos = mul(unity_CameraToWorld, float4(viewPos.xy, -viewPos.z, 1.0)).xyz;


    // float depth = sceneDepth - i.depth;

    // float3 worldSpaceScenePos = -i.viewDir / i.screenPos.w * sceneDepth + _WorldSpaceCameraPos;
    float depth = (i.worldPos - sceneWorldPos).y / _DepthFadeDist;
    // float depth = saturate(exp(-(i.worldPos - worldSpaceScenePos).g / _DepthFadeDist));

    // float3 worldSpaceScenePos = -i.viewDir / i.screenPos.w * sceneDepth;
    // float depth = (i.worldPos - worldSpaceScenePos).g;

    // float depth = exp(sceneDepth - i.depth);

    // return fixed4(backgroundDepth.xxx, 1);
    // return fixed4(sceneDepth.xxx, 1);
    return fixed4(depth.xxx, 1);
    return fixed4(screenUV * depth, 0, 1);
    return fixed4(screenUV.xy, 0, 1);
}