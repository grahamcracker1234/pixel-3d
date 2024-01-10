Shader "Custom/ImprovedOutline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Name "Outline"

            CGPROGRAM
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

            uniform int _ConvolutionScale;
            uniform float _DepthThreshold;
            uniform float _NormalThreshold;
            uniform float _DepthNormalThreshold;
            uniform float _DepthNormalThresholdScale;

            float3 _ViewDir;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            #define SAMPLE_DEPTH_NORMAL(uv, name) \
                float name##Depth; \
                float3 name##Normal; \
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uv), name##Depth, name##Normal);

            #define EDGE_PASS(uv, name) \
                float2 name = edgePass(uv); \
                float name##Depth = name.x; \
                float name##Normal = name.y;

            // https://roystan.net/articles/outline-shader/
            // https://en.wikipedia.org/wiki/Roberts_cross
            float2 edgePass(float2 uv)
            {
                // Convolution scaling and offsets
                float halfScaleFloor = floor(_ConvolutionScale * 0.5);
                float halfScaleCeil = ceil(_ConvolutionScale * 0.5);
                float2 offset = 1 / _ScreenParams.xy;

                // UVs for convolution sampling
                float2 bottomLeftUV = uv + offset.xy * -halfScaleFloor;
                float2 topRightUV = uv + offset.xy * halfScaleCeil;
                float2 bottomRightUV = uv + offset.xy * float2(halfScaleCeil, -halfScaleFloor);
                float2 topLeftUV = uv + offset.xy * float2(-halfScaleFloor, halfScaleCeil);

                // Sample depth and normal
                SAMPLE_DEPTH_NORMAL(uv, center);
                SAMPLE_DEPTH_NORMAL(bottomLeftUV, bottomLeft);
                SAMPLE_DEPTH_NORMAL(topRightUV, topRight);
                SAMPLE_DEPTH_NORMAL(bottomRightUV, bottomRight);
                SAMPLE_DEPTH_NORMAL(topLeftUV, topLeft);

                // Calculate the steep angle threshold
                float angle = 1 - dot(centerNormal, float3(0, 0, 1));
                float steepAngleThreshold01 = saturate((angle - _DepthNormalThreshold) / (1 - _DepthNormalThreshold));
                float steepAngleThreshold = steepAngleThreshold01 * _DepthNormalThresholdScale + 1;

                // Calculate the depth edge
                float diagDepth0 = bottomLeftDepth - topRightDepth;
                float diagDepth1 = bottomRightDepth - topLeftDepth;
                float edgeDepth = sqrt(diagDepth0 * diagDepth0 + diagDepth1 * diagDepth1) * 100;
                float depthThreshold = _DepthThreshold * centerDepth * steepAngleThreshold;
                edgeDepth = edgeDepth > depthThreshold ? 1 : 0;
                
                // Calculate the normal edge
                float3 diagNormal0 = bottomLeftNormal - topRightNormal;
                float3 diagNormal1 = bottomRightNormal - topLeftNormal;
                float edgeNormal = sqrt(dot(diagNormal0, diagNormal0) + dot(diagNormal1, diagNormal1));
                edgeNormal = edgeNormal > _NormalThreshold ? 1 : 0;
                
                // Return both edges
                return float2(edgeDepth, edgeNormal);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float colorShift = 0.5;
                fixed4 color = tex2D(_MainTex, i.uv);

                fixed4 outlineColor = lerp(color, fixed4(0, 0, 0, 1), colorShift);
                fixed4 inlineColor = lerp(color, fixed4(1, 1, 1, 1), colorShift);

                EDGE_PASS(i.uv, edge);

                // Any depth overrides normal
                edgeNormal = step(edgeDepth, 0) * edgeNormal;

                color = lerp(color, outlineColor, edgeDepth);
                color = lerp(color, inlineColor, edgeNormal);

                return float4(color.rgb, 1);
            }
            ENDCG
        }
    }
}
