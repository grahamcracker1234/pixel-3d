Shader "Custom/AltOutline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        CGINCLUDE
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
        sampler2D _ErosionDepthTexture;

        uniform int _ConvolutionScale;
        uniform float _DepthThreshold;
        uniform float _NormalThreshold;
        uniform float _DepthNormalThreshold;
        uniform float _DepthNormalThresholdScale;

        v2f vert(appdata v)
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

        // https://en.wikipedia.org/wiki/Erosion_(morphology)
        float2 erosionPass(float2 uv)
        {
            // Convolution scaling and offsets
            float2 offset = 1 / _ScreenParams.xy;

            // UVs for convolution sampling
            float2 blUV = uv + offset.xy * float2(-1, -1);
            float2 bcUV = uv + offset.xy * float2( 0, -1);
            float2 brUV = uv + offset.xy * float2( 1, -1);
            float2 clUV = uv + offset.xy * float2(-1,  0);
            float2 ccUV = uv + offset.xy * float2( 0,  0);
            float2 crUV = uv + offset.xy * float2( 1,  0);
            float2 tlUV = uv + offset.xy * float2(-1,  1);
            float2 tcUV = uv + offset.xy * float2( 0,  1);
            float2 trUV = uv + offset.xy * float2( 1,  1);

            // Sample depth and normal
            SAMPLE_DEPTH_NORMAL(blUV, bl);
            SAMPLE_DEPTH_NORMAL(bcUV, bc);
            SAMPLE_DEPTH_NORMAL(brUV, br);
            SAMPLE_DEPTH_NORMAL(clUV, cl);
            SAMPLE_DEPTH_NORMAL(ccUV, cc);
            SAMPLE_DEPTH_NORMAL(crUV, cr);
            SAMPLE_DEPTH_NORMAL(tlUV, tl);
            SAMPLE_DEPTH_NORMAL(tcUV, tc);
            SAMPLE_DEPTH_NORMAL(trUV, tr);

            float maxDepth = 0;
            maxDepth = max(maxDepth, blDepth);
            maxDepth = max(maxDepth, bcDepth);
            maxDepth = max(maxDepth, brDepth);
            maxDepth = max(maxDepth, clDepth);
            maxDepth = max(maxDepth, ccDepth);
            maxDepth = max(maxDepth, crDepth);
            maxDepth = max(maxDepth, tlDepth);
            maxDepth = max(maxDepth, tcDepth);
            maxDepth = max(maxDepth, trDepth);

            return float2(ccDepth, maxDepth);
        }

        #define SAMPLE_EROSION_DEPTH_NORMAL(uv, name) \
            float name##EDepth = tex2D(_ErosionDepthTexture, uv); \
            float name##Depth; \
            float3 name##Normal; \
            DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uv), name##Depth, name##Normal);

        #define EDGE_PASS(uv, name) \
                float3 name = edgePass(uv); \
                float name##EDepth = name.x; \
                float name##Depth = name.y; \
                float name##Normal = name.z;
        
        // https://roystan.net/articles/outline-shader/
        // https://en.wikipedia.org/wiki/Sobel_operator
        float3 edgePass(float2 uv)
        {
            // Convolution scaling and offsets
            //float halfScaleFloor = floor(_ConvolutionScale * 0.5);
            //float halfScaleCeil = ceil(_ConvolutionScale * 0.5);
            float2 offset = 1 / _ScreenParams.xy;

            // UVs for convolution sampling
            float2 blUV = uv + offset.xy * float2(-1, -1);
            float2 bcUV = uv + offset.xy * float2( 0, -1);
            float2 brUV = uv + offset.xy * float2( 1, -1);
            float2 clUV = uv + offset.xy * float2(-1,  0);
            float2 ccUV = uv + offset.xy * float2( 0,  0);
            float2 crUV = uv + offset.xy * float2( 1,  0);
            float2 tlUV = uv + offset.xy * float2(-1,  1);
            float2 tcUV = uv + offset.xy * float2( 0,  1);
            float2 trUV = uv + offset.xy * float2( 1,  1);

            // Sample depth and normal
            SAMPLE_EROSION_DEPTH_NORMAL(blUV, bl);
            SAMPLE_EROSION_DEPTH_NORMAL(bcUV, bc);
            SAMPLE_EROSION_DEPTH_NORMAL(brUV, br);
            SAMPLE_EROSION_DEPTH_NORMAL(clUV, cl);
            SAMPLE_EROSION_DEPTH_NORMAL(ccUV, cc);
            SAMPLE_EROSION_DEPTH_NORMAL(crUV, cr);
            SAMPLE_EROSION_DEPTH_NORMAL(tlUV, tl);
            SAMPLE_EROSION_DEPTH_NORMAL(tcUV, tc);
            SAMPLE_EROSION_DEPTH_NORMAL(trUV, tr);

            // Calculate the steep angle threshold
            float angle = 1 - dot(ccNormal, float3(0, 0, 1));
            float steepAngleThreshold01 = saturate((angle - _DepthNormalThreshold) / (1 - _DepthNormalThreshold));
            float steepAngleThreshold = steepAngleThreshold01 * _DepthNormalThresholdScale + 1;

            // Calculate the erosion depth edge
            float horizontalEDepth = tlEDepth + 2 * clEDepth + blEDepth - trEDepth - 2 * crEDepth - brEDepth;
            float verticalEDepth = tlEDepth + 2 * tcEDepth + trEDepth - blEDepth - 2 * bcEDepth - brEDepth;
            float edgeEDepth = sqrt(horizontalEDepth * horizontalEDepth + verticalEDepth * verticalEDepth) * 25;
            float eDepthThreshold = _DepthThreshold * ccEDepth * steepAngleThreshold;
            edgeEDepth = edgeEDepth > eDepthThreshold ? 1 : 0;

            // Calculate the depth edge
            float horizontalDepth = tlDepth + 2 * clDepth + blDepth - trDepth - 2 * crDepth - brDepth;
            float verticalDepth = tlDepth + 2 * tcDepth + trDepth - blDepth - 2 * bcDepth - brDepth;
            float edgeDepth = sqrt(horizontalDepth * horizontalDepth + verticalDepth * verticalDepth) * 25;
            float depthThreshold = _DepthThreshold * ccDepth * steepAngleThreshold;
            edgeDepth = edgeDepth > depthThreshold ? 1 : 0;

            // Calculate the normal edge
            float3 horiontalNormal = tlNormal + 2 * clNormal + blNormal - trNormal - 2 * crNormal - brNormal;
            float3 verticalNormal = tlNormal + 2 * tcNormal + trNormal - blNormal - 2 * bcNormal - brNormal;
            float edgeNormal = sqrt(dot(horiontalNormal, horiontalNormal) + dot(verticalNormal, verticalNormal));
            edgeNormal = edgeNormal > _NormalThreshold ? 1 : 0;

            return float3(edgeEDepth, edgeDepth, edgeNormal);
        }
        ENDCG

        Pass
        {
            Name "Erosion Depth Map"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            fixed4 frag(v2f i) : SV_Target
            {
                float2 erosion = erosionPass(i.uv);
                float centerDepth = erosion.x;
                float maxDepth = erosion.y;

                return maxDepth;
            }
            ENDCG
        }

        Pass
        {
            Name "Outline"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            fixed4 frag(v2f i) : SV_Target
            {
                float colorShift = 0.5;
                fixed4 color = tex2D(_MainTex, i.uv);

                fixed4 outlineColor = lerp(color, fixed4(0, 0, 0, 1), colorShift);
                fixed4 inlineColor = lerp(color, fixed4(1, 1, 1, 1), colorShift);

                EDGE_PASS(i.uv, edge);

                //float total = max(edgeDepth, edgeNormal);
                //return total > 0 ? float4(color.rgb, 1) : float4(0, 0, 0, 0);

                // Any depth or erosion depth overrides normal
                edgeNormal = step(edgeDepth, 0) * edgeNormal;
                edgeNormal = step(edgeEDepth, 0) * edgeNormal;

                color = lerp(color, outlineColor, edgeEDepth);
                color = lerp(color, inlineColor, edgeNormal);

                return float4(color.rgb, 1);
            }
            ENDCG
        }
    }
}
