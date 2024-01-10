Shader "Custom/Outline"
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
//                o.uv = v.uv;
                return o;
            }

            float4 sobelPass(float2 uv, float thickness)
            {
                float depth;
                float3 normal;
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uv), depth, normal);

                float3 offset = float3(1 / _ScreenParams.xy, 0) * thickness;

                float leftDepth;
                float3 leftNormal;
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uv - offset.xz), leftDepth, leftNormal);
                float rightDepth;
                float3 rightNormal;
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uv + offset.xz), rightDepth, rightNormal);
                float upDepth;
                float3 upNormal;
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uv + offset.zy), upDepth, upNormal);
                float downDepth;
                float3 downNormal;
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uv - offset.zy), downDepth, downNormal);

                float sobelDepth = abs(leftDepth - depth) + abs(rightDepth - depth) +
                                   abs(upDepth - depth)   + abs(downDepth - depth);

                float3 sobelNormal = abs(leftNormal - normal) + abs(rightNormal - normal) +
                                     abs(upNormal - normal)   + abs(downNormal - normal);
                
                return float4(sobelNormal, sobelDepth);
            }

            float _OutlineWidth;

            fixed4 frag (v2f i) : SV_Target
            {
                //float thickness = 1;
                float colorShift = 0.5;

                fixed4 color = tex2D(_MainTex, i.uv);

                float4 sobel = sobelPass(i.uv, _OutlineWidth);
                float sobelDepth = round(saturate(sobel.w * 10));
                //return float4(sobelDepth.xxx, 1);

                fixed4 outlineColor = lerp(color, fixed4(0, 0, 0, 1), colorShift);

                float sobelNormal = round(saturate(sobel.x + sobel.y + sobel.z));
                //return fixed4(sobelNormal.xxx, 1);

                // return fixed4(sobelDepth, sobelNormal, 0, 1);

                fixed4 inlineColor = lerp(color, fixed4(1, 1, 1, 1), colorShift);

                //float totalSobel = saturate(max(sobelDepth, sobelNormal));
                //return fixed4(totalSobel.xxx, 1);

                // Depth overrides normal
                sobelNormal = sobelDepth > 0 ? 0 : sobelNormal;

                color = lerp(color, outlineColor, sobelDepth);
                color = lerp(color, inlineColor, sobelNormal);
                return fixed4(color.rgb, 1);

            }
            ENDCG
        }
    }
}
