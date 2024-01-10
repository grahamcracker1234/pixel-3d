// #pragma vertex vert
// #pragma fragment frag
// 
// #include "UnityCG.cginc"
// 
// struct appdata
// {
//     float4 vertex : POSITION;
//     float2 uv : TEXCOORD0;
//     float4 screenPos : TEXCOORD1;
// };
// 
// struct v2f
// {
//     float4 vertex : SV_POSITION;
//     float2 uv : TEXCOORD0;
//     float2 screenPos : TEXCOORD1;
// };
// 
// sampler2D _MainTex;
// float4 _MainTex_ST;
// 
// sampler2D _CameraDepthNormalsTexture;
// 
// v2f vert (appdata v)
// {
//     v2f o;
//     o.vertex = UnityObjectToClipPos(v.vertex);
//     o.uv = TRANSFORM_TEX(v.uv, _MainTex);
//     //o.screenPos = ComputeScreenPos(o.vertex);
//     o.screenPos = v.screenPos;
//     return o;
// }

#pragma vertex vert
#pragma fragment frag

#include "UnityCG.cginc"

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};

struct v2f
{
    float4 vertex : SV_POSITION;
    float2 uv : TEXCOORD0;
};

sampler2D _MainTex;
float4 _MainTex_ST;

sampler2D _CameraDepthNormalsTexture;

v2f vert (appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    return o;
}