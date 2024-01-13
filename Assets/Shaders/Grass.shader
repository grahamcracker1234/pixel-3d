Shader "Custom/Grass"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Color("Color", Color) = (0, 1, 0, 1)
        _AlphaCutout("Alpha Cutout", Range(0, 1)) = 0.5
        _WindSpeed("Wind Speed", Range(0, 1)) = 0.5
        _WindStrength("Wind Strength", Range(0, 1)) = 0.5
        _ColorTex("Color Texture", 2D) = "white" {}
    }

     SubShader
     {
        Tags {
            "RenderType" = "Transparent"
            // "Queue" = "Transparent"
            // "RenderType" = "Transparent"
            // "Queue" = "Transparent"
            "PreviewType" = "Plane"
            "LightMode" = "ForwardBase"
        }

        Pass
        {
            Name "Grass"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
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
                float2 worldUV : TEXCOORD1;
                uint instanceID : SV_InstanceID;
                SHADOW_COORDS(2)
            };

            struct GrassData
            {
                float4x4 matrixTRS;
                float2 worldUV;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float _AlphaCutout;
            float _WindSpeed;
            float _WindStrength;
            StructuredBuffer<GrassData> _GrassData;
            sampler2D _ColorTex;

            float remap(float value, float low1, float high1, float low2, float high2)
            {
                return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
            }

            v2f vert (appdata v, uint svInstanceID : SV_InstanceID)
            {   
                InitIndirectDrawArgs(0);
                uint cmdID = GetCommandID(0);
                uint instanceID = GetIndirectInstanceID(svInstanceID);
                
                v2f o;
                float offset = randValue(instanceID) * 20;
                float4 worldPosition = mul(_GrassData[instanceID].matrixTRS, float4(v.vertex.xyz, 1));
                
                worldPosition.x += sin((_Time.y + offset) * _WindSpeed + worldPosition.y - 0.5) * _WindStrength * pow(v.uv.y, 5);
                o.pos = UnityObjectToClipPos(worldPosition);
                o.uv = v.uv;
                o.worldUV = _GrassData[instanceID].worldUV;
                o.instanceID = instanceID;
                TRANSFER_SHADOW(o)
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 tex = tex2D(_MainTex, i.uv);

                if (tex.a < _AlphaCutout)
                    discard;

                // float shadow = SHADOW_ATTENUATION(i);
                // return float4(shadow.xxx, 1);
                float shadow = remap(step(0.75, SHADOW_ATTENUATION(i)), 0, 1, 0.5, 1);
                float4 colorTex = tex2D(_ColorTex, i.worldUV);
                float lum = dot(tex.xyz, float3(0.2126729, 0.7151522, 0.0721750));
                float3 color = lerp(colorTex.rgb, lum * _Color, i.uv.y * _Color.a);
                return float4(color * shadow, 1);
            }
            ENDCG
        }
        // shadow casting support
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
