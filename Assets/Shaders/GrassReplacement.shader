Shader "Custom/GrassReplacement"
{
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
                
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return 0;
            }
            
            ENDCG
        }
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" }
                
        UsePass "Custom/Grass/GRASS"

        UsePass "Custom/Grass/GRASSADD"
    }
    SubShader
    {
        Tags { "RenderType" = "TransparentLeaf" }

        CGPROGRAM
        #define GRASS_REPLACEMENT 1
        ENDCG
                
        UsePass "Custom/Leaf/LEAF"

        UsePass "Custom/Leaf/LEAFADD"
    }
}
