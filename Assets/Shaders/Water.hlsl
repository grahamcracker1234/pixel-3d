#include "UnityCG.cginc"

struct appdata
{
    float4 vertex : POSITION;
};

struct v2f
{
    float4 pos : SV_POSITION;
    float4 worldPos : TEXCOORD0;
    float4 screenPos : TEXCOORD1;
    float depth : Depth;
};

sampler2D _MainTex;
float4 _MainTex_ST;

float4 _Color;
float _DepthFadeDist;

sampler2D _CameraDepthTexture;

bool isOrthographicCamera() {
	return unity_OrthoParams.w;
}

float getRawDepth(float2 uv) { 
    return SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, float4(uv, 0, 0)); 
}
 
// inspired by keijiro's depth inverse projection
// https://github.com/keijiro/DepthInverseProjection
// constructs view space ray at the far clip plane from the screen uv
// then multiplies that ray by the linear 01 depth
float3 viewSpacePosAtScreenUV(float2 uv)
{
    float3 viewPos = mul(unity_CameraInvProjection, float4(uv * 2 - 1, 1, 1) * _ProjectionParams.z);
    float rawDepth = getRawDepth(uv);
    return viewPos * Linear01Depth(rawDepth);
}

float3 getSceneWorldPos(float2 uv)
{
    if (isOrthographicCamera()) {
        float near = _ProjectionParams.y;
        float far = _ProjectionParams.z;
        float rawDepth = getRawDepth(uv);
        float distance = rawDepth * (far - near);
        // float distance = rawDepth * (far - near) + near;
        return mul(unity_CameraToWorld, float4(uv * 2 - 1, distance, 1)).xyz;
        return mul(unity_CameraToWorld, float4(uv * 2 - 1, distance, 1)).xyz;
    }
    float3 viewPos = viewSpacePosAtScreenUV(uv);
    float3 sceneWorldPos = mul(unity_CameraToWorld, float4(viewPos.xy, -viewPos.z, 1)).xyz;
    return sceneWorldPos;
}

v2f vert(appdata v)
{
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    o.screenPos = ComputeScreenPos(o.pos);
    o.depth = o.pos.z;
    return o;
}

fixed4 frag(v2f i) : SV_Target
{

    // float backgroundDepth = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenUV)));
    
    float2 screenUV = i.screenPos.xy / i.screenPos.w;
    // float sceneDepth = Linear01Depth(tex2D(_CameraDepthTexture, screenUV));

    float3 sceneWorldPos = getSceneWorldPos(screenUV);

    // if (isOrthographicCamera()) {
        // return fixed4(sceneWorldPos.yyy, 1);
    // }

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