Shader "Custom/PixelPerfectOutline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Off ZWrite Off ZTest Always

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
            sampler2D _CameraDepthTexture;

            float2 _ScreenSize;

            float _DepthThreshold;
            float _NormalThreshold;
            float3 _NormalEdgeBias;

            float _AngleThreshold;
            float _AngleFactorScale;

            bool _DebugOutline;

            float4 _OutlineColor;
            float4 _EdgeColor;
            float _ColorShift;

            #define SAMPLE_DEPTH_NORMAL(uv, name) \
                float name##Depth; \
                float3 name##Normal; \
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uv), name##Depth, name##Normal);

            struct PassValue
            {
                float depth;
                float normal;
            };

            float getDepthDiff(float depth, float neighborDepth)
            {
                return neighborDepth - depth;
                return saturate(neighborDepth - depth);
            }

            float getNormalDiff(float3 normal, float3 neighborNormal, float depth, float neighborDepth)
            {
                float3 normalDiff = normal - neighborNormal;
                float normalBiasDiff = dot(normalDiff, _NormalEdgeBias);
                float normalIndicator = saturate(smoothstep(-0.1, 0.1, normalBiasDiff));

                float depthDiff = neighborDepth - depth;
                float depthIndicator = saturate(sign(depthDiff * .25 + .0025));

                return (1 - dot(normal, neighborNormal)) * normalIndicator * depthIndicator;
            }

            // Sources:
            // https://roystan.net/articles/outline-shader/
            // https://www.youtube.com/watch?v=LRDpEnpWohM
            // https://www.youtube.com/watch?v=jFevm02NJ5M
            // https://github.com/KodyJKing/three.js/blob/outlined-pixel-example/examples/jsm/postprocessing/RenderPixelatedPass.js
            PassValue edgePass(float2 uv)
            {
                // Convolution offset sizes
                float2 offset = 1 / _ScreenSize;

                // UVs for convolution sampling
                float2 top = uv + offset * float2(0, 1);
                float2 bottom = uv + offset * float2(0, -1);
                float2 left = uv + offset * float2(-1, 0);
                float2 right = uv + offset * float2(1, 0);

                // Sample depth and normal
                SAMPLE_DEPTH_NORMAL(uv, center);
                SAMPLE_DEPTH_NORMAL(top, top);
                SAMPLE_DEPTH_NORMAL(bottom, bottom);
                SAMPLE_DEPTH_NORMAL(left, left);
                SAMPLE_DEPTH_NORMAL(right, right);

                // Calculate the angle threshold
                float angle = 1 - dot(centerNormal, float3(0, 0, 1));
                float angleThreshold = saturate((angle - _AngleThreshold) / (1 - _AngleThreshold));
                float angleFactor = angleThreshold * _AngleFactorScale + 1;

                // Calculate the depth edge
                float depthDiff = 0;
                depthDiff += getDepthDiff(centerDepth, topDepth);
                depthDiff += getDepthDiff(centerDepth, bottomDepth);
                depthDiff += getDepthDiff(centerDepth, leftDepth);
                depthDiff += getDepthDiff(centerDepth, rightDepth);
                float depthThreshold = _DepthThreshold * centerDepth * angleFactor;
                float depth = step(depthThreshold, depthDiff);

                // Calculate the normal edge
                float normalDiff = 0;
                normalDiff += getNormalDiff(centerNormal, topNormal, centerDepth, topDepth);
                normalDiff += getNormalDiff(centerNormal, bottomNormal, centerDepth, bottomDepth);
                normalDiff += getNormalDiff(centerNormal, leftNormal, centerDepth, leftDepth);
                normalDiff += getNormalDiff(centerNormal, rightNormal, centerDepth, rightDepth);
                float normal = step(_NormalThreshold, normalDiff);

                PassValue edge = { depth, normal };
                return edge;
            }

            v2f vert(appdata v)
            {
                v2f o = { UnityObjectToClipPos(v.vertex), TRANSFORM_TEX(v.uv, _MainTex) };
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float4 color = tex2D(_MainTex, i.uv);
                float4 outlineColor = float4(lerp(color.rgb, _OutlineColor.rgb, _OutlineColor.a), 1);
                float4 edgeColor = float4(lerp(color.rgb, _EdgeColor.rgb, _EdgeColor.a), 1);

                PassValue edge = edgePass(i.uv);

                if (_DebugOutline) return float4(edge.depth, edge.normal, 0, 1);

                // Any depth overrides normal
                edge.normal = step(edge.depth, 0) * edge.normal;

                color = lerp(color, outlineColor, edge.depth);
                color = lerp(color, edgeColor, edge.normal);

                return color;
            }

            ENDCG
        }
    }
    Fallback Off
}
