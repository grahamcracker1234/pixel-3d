// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "Custom/Cel"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ShadeTex ("Shade Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _DarknessColor ("Darkness Color", Color) = (0.5,0.5,0.5,1)
        _DarknessMidpoint ("Darkness Midpoint", Range(0, 1)) = 0.5
        _ShadowThreshold ("Shadow Threshold", Range(0, 1)) = 0.5
        _ShadeBitDepth ("Shade Bit Depth", Range(0, 15)) = 5
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            // "LightMode" = "ForwardBase"
        }
        
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

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
                float3 worldPos : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float3 normal : NORMAL;
                SHADOW_COORDS(2)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _ShadeTex;
            float4 _Color;
            float4 _DarknessColor;
            float _DarknessMidpoint;
            float _ShadowThreshold;
            float _ShadeBitDepth;

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
                shade = screen(shade, _DarknessColor);

                float4 shadow = SHADOW_ATTENUATION(i);
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
                // return float4(atten.xxx, 1);
                // return _LightColor0;
                return float4(diffuseReflection, 1);
            }
            ENDCG
        }

        // https://en.wikibooks.org/wiki/Cg_Programming/Unity/Cookies
        Pass {    
            Tags { "LightMode" = "ForwardAdd" } 

            CGPROGRAM
            #pragma multi_compile_lightpass
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
                float3 worldPos : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float4 posLight : TEXCOORD3;
                float3 normal : NORMAL;
                SHADOW_COORDS(2)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _ShadeTex;
            float4 _Color;
            float4 _DarknessColor;
            float _DarknessMidpoint;
            float _ShadowThreshold;
            float _ShadeBitDepth;

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
                shade = screen(shade, _DarknessColor);

                float4 shadow = SHADOW_ATTENUATION(i);
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

            v2f vert(appdata v) 
            {
                v2f o;

                float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.posLight = mul(unity_WorldToLight, posWorld);
                o.pos = UnityObjectToClipPos(v.vertex);

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                TRANSFER_SHADOW(o)
                
                return o;
            }

            // https://en.wikibooks.org/wiki/GLSL_Programming/Unity/Multiple_Lights
            float4 frag(v2f i) : COLOR
            {
                fixed4 sample = tex2D(_MainTex, i.uv);

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

                float4 cookieAttenuation = tex2D(_LightTexture0, i.posLight.xy);
                
                // return cookieAttenuation;
                // return float4(diffuseReflection, 1);
                return float4(diffuseReflection, 1) * cookieAttenuation;
            }

            ENDCG
        }

        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}

// // Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

// Shader "Custom/Cel"
// {
//     Properties
//     {
//         _MainTex ("Texture", 2D) = "white" {}
//         _ShadeTex ("Shade Texture", 2D) = "white" {}
//         _Color ("Color", Color) = (1,1,1,1)
//         _DarknessColor ("Darkness Color", Color) = (0.5,0.5,0.5,1)
//         _DarknessMidpoint ("Darkness Midpoint", Range(0, 1)) = 0.5
//         _ShadowThreshold ("Shadow Threshold", Range(0, 1)) = 0.5
//         _ShadeBitDepth ("Shade Bit Depth", Range(0, 15)) = 5
//     }
//     SubShader
//     {
//         Tags
//         {
//             "RenderType" = "Opaque"
//             // "LightMode" = "ForwardBase"
//         }
        
//         Pass
//         {
//             Tags { "LightMode" = "ForwardBase" }

//             CGPROGRAM
//             #pragma vertex vert
//             #pragma fragment frag
//             #pragma multi_compile_fwdbase
//             // #pragma multi_compile _LIGHT_COOKIES
//             // #pragma multi_compile_fwdadd
//             // #pragma multi_compile DIRECTIONAL DIRECTIONAL_COOKIE POINT SPOT
//             #include "UnityCG.cginc"
//             #include "UnityLightingCommon.cginc"
//             #include "Lighting.cginc"
//             #include "AutoLight.cginc"

//             // #define DIRECTIONAL_COOKIE
//             // #define SHADOWS_SCREEN
//             // #define SHADOWS_SHADOWMASK
//             // #define UNITY_NO_SCREENSPACE_SHADOWS

//             sampler2D _LightTexture0; 

//             struct appdata
//             {
//                 float4 vertex : POSITION;
//                 float2 uv : TEXCOORD0;
//                 float3 normal : NORMAL;
//             };

//             struct v2f
//             {
//                 float4 pos : SV_POSITION;
//                 float3 worldPos : TEXCOORD0;
//                 float2 uv : TEXCOORD1;
//                 float3 normal : NORMAL;
//                 SHADOW_COORDS(2)
//             };

//             sampler2D _MainTex;
//             float4 _MainTex_ST;

//             sampler2D _ShadeTex;
//             float4 _Color;
//             float4 _DarknessColor;
//             float _DarknessMidpoint;
//             float _ShadowThreshold;
//             float _ShadeBitDepth;

//             float remap(float value, float low1, float high1, float low2, float high2)
//             {
//                 return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
//             }

//             // Blend modes
//             #define multiply(a, b) a * b
//             #define screen(a, b) 1 - (1 - a) * (1 - b)
//             #define overlay(a, b) (2 * a * b) * step(0.5, a) + (1 - 2 * (1 - a) * (1 - b)) * (1 - step(0.5, a))
//             #define hardLight(a, b) overlay(b, a)
//             #define blend(a, b, mode) float3(mode(a.r, b.r), mode(a.g, b.g), mode(a.b, b.b))

//             float grayscale(float3 color)
//             {
//                 return dot(color, float3(0.299, 0.587, 0.114));
//             }

//             float3 celShading(v2f i, float attenuation, float4 color, float4 lightColor, float3 lightDir)
//             {
//                 // Shading texture
//                 // float intensity = remap(dot(i.normal, lightDir), -1, 1, 0, 1);
//                 // float4 shade = tex2D(_ShadeTex, float2(intensity, attenuation));
//                 // shade = screen(shade, _DarknessColor);

//                 float midpoint = remap(_DarknessMidpoint, 0, 1, -1, 1);
//                 float intensity = remap(max(midpoint, dot(i.normal, lightDir)), midpoint, 1, 0, 1);
//                 float4 shade = floor(intensity * _ShadeBitDepth) / _ShadeBitDepth;
//                 shade = screen(shade, _DarknessColor);

//                 float4 shadow = SHADOW_ATTENUATION(i);
//                 shadow = step(_ShadowThreshold, shadow);
//                 #if 0
//                     shadow = screen(shadow, _DarknessColor);
//                 #else
//                     // Remove shadows from the opposite side from light
//                     shadow = dot(i.normal, lightDir) < 0 ? 1 : screen(shadow, _DarknessColor);
//                 #endif

//                 float4 diffuse = color * shade * shadow * lightColor;
//                 return diffuse.rgb;
//             }

//             float3 celShadingDirectional(v2f i, float4 color, float4 lightDir, float4 lightColor)
//             {
//                 return celShading(i, 1, color, lightColor, lightDir.xyz);
//             }

//             float3 celShadingPoint(v2f i, float4 color, float4 lightPos, float4 lightColor)
//             {
//                 float3 vertexToLight = lightPos.xyz - i.worldPos;
//                 float3 lightDir = normalize(vertexToLight);
//                 float sqLength = dot(vertexToLight, vertexToLight);
//                 float attenuation = 1 / (1 + sqLength * lightPos.a);
//                 return celShading(i, attenuation, color, lightColor, lightDir);
//             }

//             v2f vert (appdata v)
//             {
//                 v2f o;
//                 o.pos = UnityObjectToClipPos(v.vertex);
//                 o.uv = TRANSFORM_TEX(v.uv, _MainTex);
//                 o.normal = UnityObjectToWorldNormal(v.normal);
//                 o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
//                 TRANSFER_SHADOW(o)
//                 return o;
//             }

//             // https://en.wikibooks.org/wiki/GLSL_Programming/Unity/Multiple_Lights
//             fixed4 frag (v2f i) : SV_Target
//             {
//                 fixed4 sample = tex2D(_MainTex, i.uv);

//                 // Light positions and attenuations
//                 float4 lightPos[4] = {
//                     float4(unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x, unity_4LightAtten0.x),
//                     float4(unity_4LightPosX0.y, unity_4LightPosY0.y, unity_4LightPosZ0.y, unity_4LightAtten0.y),
//                     float4(unity_4LightPosX0.z, unity_4LightPosY0.z, unity_4LightPosZ0.z, unity_4LightAtten0.z),
//                     float4(unity_4LightPosX0.w, unity_4LightPosY0.w, unity_4LightPosZ0.w, unity_4LightAtten0.w),
//                 };

//                 // In ForwardBase pass, _WorldSpaceLightPos0 is always directional light
//                 float3 diffuseReflection = celShadingDirectional(i, _Color, _WorldSpaceLightPos0, _LightColor0);
//                 // for (int j = 0; j < 4; j++)
//                 // {
//                 //     float3 d = celShadingPoint(i, _Color, lightPos[j], unity_LightColor[j], shadow);
//                 //     diffuseReflection = float3(max(diffuseReflection.r, d.r), max(diffuseReflection.g, d.g), max(diffuseReflection.b, d.b));
//                 // }
//                     // diffuseReflection = blend(diffuseReflection, celShadingPoint(i, _Color, lightPos[j], unity_LightColor[j], 0), max);
//                     // diffuseReflection = max(diffuseReflection, celShadingPoint(i, _Color, lightPos[j], unity_LightColor[j], shadow));
//                 // return float4(atten.xxx, 1);
//                 // return _LightColor0;
//                 return float4(diffuseReflection, 1);
//             }
//             ENDCG
//         }

//               Pass {    
//          Tags { "LightMode" = "ForwardAdd" } 
//             // pass for additional light sources
//         //  Blend One One // additive blending 
//         // Blend DstColor Zero // Multiplicative
 
//          CGPROGRAM
 
//          #pragma multi_compile_lightpass
 
//          #pragma vertex vert  
//          #pragma fragment frag 
 
//          #include "UnityCG.cginc"
//          uniform float4 _LightColor0; 
//             // color of light source (from "Lighting.cginc")
//          uniform float4x4 unity_WorldToLight; // transformation 
//             // from world to light space (from Autolight.cginc)
//          #if defined (DIRECTIONAL_COOKIE) || defined (SPOT)
//             uniform sampler2D _LightTexture0; 
//                // cookie alpha texture map (from Autolight.cginc)
//          #elif defined (POINT_COOKIE)
//             uniform samplerCUBE _LightTexture0; 
//                // cookie alpha texture map (from Autolight.cginc)
//          #endif
 
//          // User-specified properties
//          uniform float4 _Color; 
//          uniform float4 _SpecColor; 
//          uniform float _Shininess;
 
//          struct vertexInput {
//             float4 vertex : POSITION;
//             float3 normal : NORMAL;
//          };
//          struct vertexOutput {
//             float4 pos : SV_POSITION;
//             float4 posWorld : TEXCOORD0;
//                // position of the vertex (and fragment) in world space 
//             float4 posLight : TEXCOORD1;
//                // position of the vertex (and fragment) in light space
//             float3 normalDir : TEXCOORD2;
//                // surface normal vector in world space
//          };
 
//          vertexOutput vert(vertexInput input) 
//          {
//             vertexOutput output;
 
//             float4x4 modelMatrix = unity_ObjectToWorld;
//             float4x4 modelMatrixInverse = unity_WorldToObject;

//             output.posWorld = mul(modelMatrix, input.vertex);
//             output.posLight = mul(unity_WorldToLight, output.posWorld);
//             output.normalDir = normalize(
//                mul(float4(input.normal, 0.0), modelMatrixInverse).xyz);
//             output.pos = UnityObjectToClipPos(input.vertex);
//             return output;
//          }
 
//          float4 frag(vertexOutput input) : COLOR
//          {
//             float3 normalDirection = normalize(input.normalDir);
 
//             float3 viewDirection = normalize(
//                _WorldSpaceCameraPos - input.posWorld.xyz);
//             float3 lightDirection;
//             float attenuation = 1.0;
//                // by default no attenuation with distance

//             #if defined (DIRECTIONAL) || defined (DIRECTIONAL_COOKIE)
//                lightDirection = normalize(_WorldSpaceLightPos0.xyz);
//             #elif defined (POINT_NOATT)
//                lightDirection = normalize(
//                   _WorldSpaceLightPos0 - input.posWorld.xyz);
//             #elif defined(POINT)||defined(POINT_COOKIE)||defined(SPOT)
//                float3 vertexToLightSource = 
//                   _WorldSpaceLightPos0.xyz - input.posWorld.xyz;
//                float distance = length(vertexToLightSource);
//                attenuation = 1.0 / distance; // linear attenuation 
//                lightDirection = normalize(vertexToLightSource);
//             #endif
 
//             float3 diffuseReflection = 
//                attenuation * _LightColor0.rgb * _Color.rgb
//                * max(0.0, dot(normalDirection, lightDirection));
 
//             float3 specularReflection;
//             if (dot(normalDirection, lightDirection) < 0.0) 
//                // light source on the wrong side?
//             {
//                specularReflection = float3(0.0, 0.0, 0.0); 
//                   // no specular reflection
//             }
//             else // light source on the right side
//             {
//                specularReflection = attenuation * _LightColor0.rgb 
//                   * _SpecColor.rgb * pow(max(0.0, dot(
//                   reflect(-lightDirection, normalDirection), 
//                   viewDirection)), _Shininess);
//             }
 
//             float cookieAttenuation = 1.0; 
//                // by default no cookie attenuation
//             #if defined (DIRECTIONAL_COOKIE)
//                cookieAttenuation = tex2D(_LightTexture0, 
//                   input.posLight.xy).a;
//             #elif defined (POINT_COOKIE)
//                cookieAttenuation = texCUBE(_LightTexture0, 
//                   input.posLight.xyz).a;
//             #elif defined (SPOT)
//                cookieAttenuation = tex2D(_LightTexture0, 
//                   input.posLight.xy / input.posLight.w 
//                   + float2(0.5, 0.5)).a;
//             #endif

//             // cookieAttenuation = tex2D(_LightTexture0, input.posLight.xy);

//             return tex2D(_LightTexture0, input.posLight.xy);
//             return float4(input.posLight.xy, 0.0, 1.0);
//             return float4(cookieAttenuation * (diffuseReflection + specularReflection), 1.0);
//          }
 
//          ENDCG
//       }

//         UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
//     }
// }
