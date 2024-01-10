Shader "Custom/Pixel"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float2 _BlockCount;


            fixed4 frag (v2f i) : SV_Target
            {
                float2 blockPos = floor(i.uv * _BlockCount);
                float2 blockCenter = (blockPos + 0.5) / _BlockCount;

                float4 color = tex2D(_MainTex, blockCenter);
                return color;
            }
            ENDCG
        }
    }
}