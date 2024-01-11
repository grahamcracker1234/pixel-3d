// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Test/ReplacementTest"
{
    Properties
    {
        // _MainTex ("Texture", 2D) = "white" {}
        _Color("Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        ZWrite On
        
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float depth : DEPTH;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.depth = o.vertex.z / o.vertex.w;
                // o.depth = -mul(UNITY_MATRIX_MV, v.vertex).z * _ProjectionParams.w;
                // o.depth = o.vertex.zw;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // return fixed4(1, 0, 0, 1);
                return fixed4(i.depth.xxx, 1);
            }
            ENDCG
        }

        GrabPass
        {
            "_GrabTexture"
        }

        Pass {
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            half4 _Color;
            sampler2D _GrabTexture;

            fixed4 frag (v2f i) : SV_Target
            {
                // fixed4 col = tex2D(_GrabTexture, i.uv);
                fixed4 col = tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(i.vertex));

                // return fixed4(1, 0, 0, 1);
                return col * _Color;
            }
            ENDCG
        }
    }
}
