Shader "Custom/Foliage"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Blend ("Blend", Range(0, 1)) = 0.5
        _Extrude ("Extrude", Range(0, 10)) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "LightMode" = "ForwardBase"
        }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float3 normal : NORMAL;
                SHADOW_COORDS(2)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Blend;
            float _Extrude;

            #define remap(v, l1, h1, l2, h2) l2 + (v - l1) * (h2 - l2) / (h1 - l1);

            // float remap(float value, float low1, float high1, float low2, float high2)
            // {
            //     return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
            // }

            v2f vert (appdata v)
            {

                float2 uv = TRANSFORM_TEX(v.uv, _MainTex);
                uv = remap(uv, 0, 1, -1, 1);

                float3 offset = float3(uv, 0);      
                
                // Tangent space
                #if 0
                    float3 bitangent = cross(v.normal, v.tangent.xyz) / v.tangent.w;
                    float3x3 tangent_object = transpose(float3x3(v.tangent.xyz, bitangent, v.normal));
                    offset = normalize(mul(tangent_object, offset));
                #else
                    // offset = 
                    offset = mul(UNITY_MATRIX_V, float4(offset, 0)).xyz;
                    // offset = mul(float4(offset, 0), UNITY_MATRIX_MV).xyz;
                #endif
                // offset = mul(float4(offset, 0), unity_ObjectToWorld).xyz;

                v.vertex.xyz += offset * _Blend + v.normal * _Extrude;

                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                TRANSFER_SHADOW(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return float4(i.uv, 0, 1);
            }
            ENDCG
        }
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
