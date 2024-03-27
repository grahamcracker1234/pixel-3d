Shader "Custom/Clouds"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FineDetail ("Texture", 2D) = "white" {}
        _MediumDetail ("Texture", 2D) = "white" {}
        _LargeDetail ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
            Name "Outline"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            // sampler2D 

            sampler2D _FineDetail;
            sampler2D _MediumDetail;
            sampler2D _LargeDetail;

            float _Coverage;
            float _Thickness;
            float _Speed;
            float _Direction;

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

            float remap(float value, float low1, float high1, float low2, float high2)
            {
                return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
            }

            v2f vert(appdata v)
            {
                v2f o = { UnityObjectToClipPos(v.vertex), TRANSFORM_TEX(v.uv, _MainTex) };
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float dir = remap(_Direction, 0, 360, 0, 6.28319);
                float speed = _Speed / 100;

                float2 uv = i.uv;
                uv.x += _Time.y * speed * cos(dir);
                uv.y += _Time.y * speed * sin(dir);

                float fine = tex2D(_FineDetail, uv).a;
                float medium = tex2D(_MediumDetail, uv).a;
                float large = tex2D(_LargeDetail, uv).a;

                // float alpha = large;
                float alpha = fine * medium * large;
                alpha = alpha > _Coverage ? 1 : alpha;
                alpha = 1 - (1 - alpha) * (_Thickness);



                // return float4(1, 1, 1, 1);
                return float4(alpha.xxx, 1);
            }

            ENDCG
        }
    }
    Fallback Off
}
