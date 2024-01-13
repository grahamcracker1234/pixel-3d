Shader "Custom/NewToon"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _AttenuationThreshold ("Attenuation Threshold", Range(0, 1)) = 0
        _ShadeBitDepth ("Shade Bit Depth", Range(0, 15)) = 5
        _MaxDarkness ("Max Darkness", Range(0, 1)) = 0.5
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
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                SHADOW_COORDS(2)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float _AttenuationThreshold;
            float _ShadeBitDepth;
            float _MaxDarkness;

            float remap(float value, float low1, float high1, float low2, float high2)
            {
                return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
            }

            float grayscale(float3 color)
            {
                return dot(color, float3(0.299, 0.587, 0.114));
            }

            // float3 toonShading(v2f i, float attenuation, float4 color, float4 lightColor, float3 lightDir)
            // {
            //     float3 diffuseReflection = step(_AttenuationThreshold, attenuation) * color.rgb * lightColor.rgb * max(0, dot(i.normal, lightDir));
            //     float3 maxGrayscale = grayscale(_Color.rgb);
            //     float3 grayscaleColor = remap(grayscale(diffuseReflection), 0, maxGrayscale, 0, 1);
            //     float3 quantizedColor = floor(grayscaleColor * _ShadeBitDepth) / _ShadeBitDepth;
            //     float3 brightenedColor = remap(quantizedColor, 0, 1, _MaxDarkness, 1);
            //     return brightenedColor * color.rgb;
            // }

            float3 toonShading(v2f i, float attenuation, float4 color, float4 lightColor, float3 lightDir)
            {
                float3 diffuseReflection = step(_AttenuationThreshold, attenuation) * color.rgb * lightColor.rgb * max(0, dot(i.normal, lightDir));
                float3 maxGrayscale = grayscale(_Color.rgb);
                float3 grayscaleColor = remap(grayscale(diffuseReflection), 0, maxGrayscale, 0, 1);
                float3 quantizedColor = floor(grayscaleColor * _ShadeBitDepth) / _ShadeBitDepth;
                float3 brightenedColor = remap(quantizedColor, 0, 1, _MaxDarkness, 1);
                return brightenedColor * color.rgb * lightColor.rgb;
            }

            float3 toonShadingDirectional(v2f i, float4 color, float4 lightDir, float4 lightColor)
            {
                return toonShading(i, 1, color, lightColor, lightDir.xyz);
            }

            float3 toonShadingPoint(v2f i, float4 color, float4 lightPos, float4 lightColor)
            {
                float3 vertexToLight = lightPos.xyz - i.worldPos;
                float3 lightDir = normalize(vertexToLight);
                float sqLength = dot(vertexToLight, vertexToLight);
                float attenuation = 1 / (1 + sqLength * lightPos.a);
                return toonShading(i, attenuation, color, lightColor, lightDir);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                TRANSFER_SHADOW(o)
                return o;
            }

            // https://en.wikibooks.org/wiki/GLSL_Programming/Unity/Multiple_Lights
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 sample = tex2D(_MainTex, i.uv);
                float shadow = remap(step(0.75, SHADOW_ATTENUATION(i)), 0, 1, 0.5, 1);
                float4 color = sample * _Color * shadow;

                // Light positions and attenuations
                float4 lightPos[4] = {
                    float4(unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x, unity_4LightAtten0.x),
                    float4(unity_4LightPosX0.y, unity_4LightPosY0.y, unity_4LightPosZ0.y, unity_4LightAtten0.y),
                    float4(unity_4LightPosX0.z, unity_4LightPosY0.z, unity_4LightPosZ0.z, unity_4LightAtten0.z),
                    float4(unity_4LightPosX0.w, unity_4LightPosY0.w, unity_4LightPosZ0.w, unity_4LightAtten0.w)
                };

                // In ForwardBase pass, _WorldSpaceLightPos0 is always directional light
                float3 diffuseReflection = toonShadingDirectional(i, color, _WorldSpaceLightPos0, _LightColor0);
                // for (int j = 0; j < 4; j++)
                    // diffuseReflection = max(diffuseReflection, toonShadingPoint(i, color, lightPos[j], unity_LightColor[j]));
                return float4(diffuseReflection, 1);
            }
            ENDCG
        }
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
