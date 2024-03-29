#include "UnityCG.cginc"
#define UNITY_INDIRECT_DRAW_ARGS IndirectDrawIndexedArgs
#include "UnityIndirect.cginc"
#include "Assets/Shaders/Random.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};

struct v2f
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float2 colorTexUV : TEXCOORD1;
    uint instanceID : SV_InstanceID;
    float depth : Depth;
    float4 worldPosition : POSITION1;
    SHADOW_COORDS(2)
};

struct GrassData
{
    float3 position;
    float2 colorTexUV;
};

sampler2D _MainTex;
float4 _MainTex_ST;
sampler2D _ColorTex;
float _AlphaCutout;
float4 _TipColor;
float _TipColorShift;
float _Scale;
float _WindSpeed;
float _WindStrength;

StructuredBuffer<GrassData> _GrassData;
float4 _Rotation;
float _MeshHeight;

float remap(float value, float low1, float high1, float low2, float high2)
{
    return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

float luma(float3 color)
{
    return dot(color, float3(0.2126729, 0.7151522, 0.0721750));
}

// https://gamedev.stackexchange.com/questions/28395/
float3 rotate(float3 v, float4 quaternion)
{
    float3 u = quaternion.xyz;
    float s = quaternion.w;
    return 2 * dot(u, v) * u + (s * s - dot(u, u)) * v + 2 * s * cross(u, v);
}

v2f vert (appdata v, uint svInstanceID : SV_InstanceID)
{   
    InitIndirectDrawArgs(0);
    uint cmdID = GetCommandID(0);
    uint instanceID = GetIndirectInstanceID(svInstanceID);
    
    v2f o;
    float offset = randValue(instanceID) * 20;
    float3 localPosition = v.vertex.xyz + float3(0, _MeshHeight / 2, 0);
    localPosition *= _Scale;
    localPosition.x += sin((_Time.y + offset) * _WindSpeed + localPosition.y - 0.5) * _WindStrength * pow(v.uv.y, 5);
    float4 worldPosition = float4(rotate(localPosition, _Rotation) + _GrassData[instanceID].position, 1);

    o.worldPosition = worldPosition;
    o.pos = UnityObjectToClipPos(worldPosition);
    o.uv = v.uv;
    o.colorTexUV = _GrassData[instanceID].colorTexUV;
    o.instanceID = instanceID;
    o.depth = o.pos.z;
    TRANSFER_SHADOW(o)
    return o;
}

float4 frag(v2f i) : SV_Target
{
    float4 tex = tex2D(_MainTex, i.uv);
    if (tex.a < _AlphaCutout)
        discard;

    float shadow = remap(step(0.75, SHADOW_ATTENUATION(i)), 0, 1, 0.5, 1);
    float4 color = tex2D(_ColorTex, i.colorTexUV) * tex;
    float lum = luma(color.rgb);
    float lumTip = luma(_TipColor.rgb);
    float4 tipColor = lerp(color, _TipColor, _TipColorShift);
    return float4(lerp(color, tipColor, i.uv.y).rgb * shadow, 1);
}