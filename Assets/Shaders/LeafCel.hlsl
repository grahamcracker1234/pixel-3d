#define UNITY_INDIRECT_DRAW_ARGS IndirectDrawIndexedArgs

#include "UnityCG.cginc"
#include "UnityIndirect.cginc"
#include "UnityLightingCommon.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "Assets/Shaders/Random.cginc"

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
};

struct v2f
{
    float4 pos : SV_POSITION;
    float3 worldPos : TEXCOORD0;
    float2 uv : TEXCOORD1;
    float4 posLight : TEXCOORD3;
    float3 normal : NORMAL;
    uint instanceID : SV_InstanceID;
    SHADOW_COORDS(2)
};

struct LeafData
{
    float3 position;
    float3 normal;
};

sampler2D _MainTex;
float4 _MainTex_ST;
float _AlphaCutout;
float _Scale;
float _WindSpeed;
float _WindStrength;
float _Extrude;

sampler2D _ShadeTex;
bool _UseShadeTex;

float4 _Color;
float4 _DarknessColor;
float _DarknessMidpoint;
float _ShadowThreshold;
float _ShadeBitDepth;

StructuredBuffer<LeafData> _LeafData;
float4 _Rotation;

float remap(float value, float low1, float high1, float low2, float high2)
{
    return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

// Blend modes
#define multiply(a, b) a * b
#define screen(a, b) 1 - (1 - a) * (1 - b)
#define overlay(a, b) (2 * a * b) * step(0.5, a) + (1 - 2 * (1 - a) * (1 - b)) * (1 - step(0.5, a))
#define hardLight(a, b) overlay(b, a)
#define blend(a, b, mode) float3(mode(a.r, b.r), mode(a.g, b.g), mode(a.b, b.b))

float grayscale(float3 color)
{
    return dot(color, float3(0.299, 0.587, 0.114));
}

float3 celShading(v2f i, float attenuation, float4 color, float4 lightColor, float3 lightDir)
{
    // Shading texture
    // float intensity = remap(dot(i.normal, lightDir), -1, 1, 0, 1);
    // float4 shade = tex2D(_ShadeTex, float2(intensity, attenuation));
    // shade = screen(shade, _DarknessColor);

    float midpoint = remap(_DarknessMidpoint, 0, 1, -1, 1);
    float intensity = remap(max(midpoint, dot(i.normal, lightDir)), midpoint, 1, 0, 1);
    float4 shade = floor(intensity * _ShadeBitDepth) / _ShadeBitDepth;
    if (_UseShadeTex)
    {
        intensity = remap(dot(i.normal, lightDir), -1, 1, 0, 1);
        shade = tex2D(_ShadeTex, float2(intensity, attenuation));
    }
    shade = screen(shade, _DarknessColor);

    // TODO: Shadow attenuation
    // float4 shadow = SHADOW_ATTENUATION(i);
    float4 shadow = 1;
    shadow = step(_ShadowThreshold, shadow);
    #if 0
        shadow = screen(shadow, _DarknessColor);
    #else
        // Remove shadows from the opposite side from light
        shadow = dot(i.normal, lightDir) < 0 ? 1 : screen(shadow, _DarknessColor);
    #endif

    float4 diffuse = color * shade * shadow * lightColor;
    return diffuse.rgb;
}

float3 celShadingDirectional(v2f i, float4 color, float4 lightDir, float4 lightColor)
{
    return celShading(i, 1, color, lightColor, lightDir.xyz);
}

float3 celShadingPoint(v2f i, float4 color, float4 lightPos, float4 lightColor)
{
    float3 vertexToLight = lightPos.xyz - i.worldPos;
    float3 lightDir = normalize(vertexToLight);
    float sqLength = dot(vertexToLight, vertexToLight);
    float attenuation = 1 / (1 + sqLength * lightPos.a);
    return celShading(i, attenuation, color, lightColor, lightDir);
}

// https://gamedev.stackexchange.com/questions/28395/
float3 rotate(float3 v, float4 quaternion)
{
    float3 u = quaternion.xyz;
    float s = quaternion.w;
    return 2 * dot(u, v) * u + (s * s - dot(u, u)) * v + 2 * s * cross(u, v);
}

v2f vert(appdata v, uint svInstanceID : SV_InstanceID) 
{
    InitIndirectDrawArgs(0);
    uint cmdID = GetCommandID(0);
    uint instanceID = GetIndirectInstanceID(svInstanceID);

    float offset = randValue(instanceID) * 20;
    float3 localPosition = v.vertex.xyz;
    localPosition *= _Scale;
    localPosition.x += sin((_Time.y + offset) * _WindSpeed + localPosition.y - 0.5) * _WindStrength * pow(v.uv.y, 5);
    float4 worldPosition = float4(rotate(localPosition, _Rotation) + _LeafData[instanceID].position, 1);
    // float3 normal = rotate(_LeafData[instanceID].normal, _Rotation);
    float3 normal = _LeafData[instanceID].normal;
    worldPosition.xyz += normal * _Extrude;

    float3 vertex = mul(unity_WorldToObject, worldPosition).xyz;

    v2f o;
    o.pos = UnityObjectToClipPos(vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    o.normal = normal;
    o.worldPos = worldPosition;
    TRANSFER_SHADOW(o)
    
    #if defined(DIRECTIONAL_COOKIE)
        float4 posWorld = mul(unity_ObjectToWorld, worldPosition);
        o.posLight = mul(unity_WorldToLight, posWorld);
    #else 
        o.posLight = 0;
    #endif
    
    return o;
}

// https://en.wikibooks.org/wiki/GLSL_Programming/Unity/Multiple_Lights
float4 frag(v2f i) : COLOR
{
    
    fixed4 sample = tex2D(_MainTex, i.uv);
    if (sample.a < _AlphaCutout)
    discard;

    // return float4(i.normal, 1);

    #if defined(GRASS_REPLACEMENT)
        return float(0, 0, 0, 0);
    #endif

    // Light positions and attenuations
    float4 lightPos[4] = {
        float4(unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x, unity_4LightAtten0.x),
        float4(unity_4LightPosX0.y, unity_4LightPosY0.y, unity_4LightPosZ0.y, unity_4LightAtten0.y),
        float4(unity_4LightPosX0.z, unity_4LightPosY0.z, unity_4LightPosZ0.z, unity_4LightAtten0.z),
        float4(unity_4LightPosX0.w, unity_4LightPosY0.w, unity_4LightPosZ0.w, unity_4LightAtten0.w),
    };

    // In ForwardBase pass, _WorldSpaceLightPos0 is always directional light
    float3 diffuseReflection = celShadingDirectional(i, _Color, _WorldSpaceLightPos0, _LightColor0);
    // for (int j = 0; j < 4; j++)
    // {
    //     float3 d = celShadingPoint(i, _Color, lightPos[j], unity_LightColor[j], shadow);
    //     diffuseReflection = float3(max(diffuseReflection.r, d.r), max(diffuseReflection.g, d.g), max(diffuseReflection.b, d.b));
    // }
    // diffuseReflection = blend(diffuseReflection, celShadingPoint(i, _Color, lightPos[j], unity_LightColor[j], 0), max);
    // diffuseReflection = max(diffuseReflection, celShadingPoint(i, _Color, lightPos[j], unity_LightColor[j], shadow));
    
    #if defined(DIRECTIONAL_COOKIE)
        float4 cookieAttenuation = tex2D(_LightTexture0, i.posLight.xy);
    #else
        float4 cookieAttenuation = 1;
    #endif
    
    // return cookieAttenuation;
    // return float4(diffuseReflection, 1);
    return float4(diffuseReflection, 1) * cookieAttenuation;
}