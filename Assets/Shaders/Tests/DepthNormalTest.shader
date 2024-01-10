Shader "Test/DepthNormalTest"
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
            Name "Depth Normal Test"
            
            CGPROGRAM
            #include "Assets/Shaders/Core.cginc"

            fixed4 frag (v2f i) : SV_Target
            {
                float thickness = 1;
                float colorShift = 0.5;

                fixed4 color = tex2D(_MainTex, i.uv);

                float depth;
                float3 normal;
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, i.uv), depth, normal);

                return fixed4(normal * pow(1 - depth, 3) * 1.5, 1);
                //return fixed4(normal, 1);
                //return fixed4(normal, 1);
            }
            ENDCG
        }
    }
}
