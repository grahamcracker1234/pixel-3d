Shader "Custom/Grass"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _AlphaCutout("Alpha Cutout", Range(0, 1)) = 0.5
        _Color("Color", Color) = (1, 1, 1, 1)
    }

     SubShader
     {
        Tags {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "PreviewType" = "Plane"
        }

        Pass
        {
            Name "Grass"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float depth : DEPTH;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(float, _AlphaCutout)
            UNITY_INSTANCING_BUFFER_END(Props)

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.depth = o.vertex.z;
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                float4 color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                float alphaCutout = UNITY_ACCESS_INSTANCED_PROP(Props, _AlphaCutout);
                float4 tex = tex2D(_MainTex, i.uv);
                float lum = dot(tex.xyz, float3(0.2126729, 0.7151522, 0.0721750));

                if (tex.a < alphaCutout)
                    discard;
                
                // color.rgb *= lum;
                return float4(color.rgb * lum, color.a);
            }
            ENDCG
        }
    }
}
