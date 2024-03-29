Shader "Custom/Water"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Color("Color", Color) = (0, 0, 0, 1)
        _DepthFadeDist("Depth Fade Distance", Range(0, 10)) = 1
    }

     SubShader
     {
        Tags {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
        }

        ZWrite Off

        Pass
        {

            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "Water.hlsl"
            ENDCG
        }


        Pass
        {
            Tags { "LightMode" = "ForwardAdd" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "Water.hlsl"
            ENDCG
        }
    }
}
