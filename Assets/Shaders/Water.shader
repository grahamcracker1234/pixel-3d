Shader "Custom/Water"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _DeepColor("Deep Color", Color) = (0, 0, 1, 1)
        _ShallowColor("Shallow Color", Color) = (0, 1, 0, 1)
        _DepthFadeDist("Depth Fade Distance", Range(0, 10)) = 1
        _ShadeBitDepth ("Shade Bit Depth", Range(0, 15)) = 5
        _RefractionSpeed("Refraction Speed", Range(0, 1)) = 0.5
        _RefractionStrength("Refraction Strength", Range(0, 1)) = 0.5
        _RefractionScale("Refraction Scale", Range(0, 1)) = 0.5
    }

     SubShader
     {
        Tags {
            "Queue" = "Transparent"
            "RenderType" = "Opaque"
            "PreviewType" = "Plane"
        }

        ZWrite On

        Blend SrcAlpha OneMinusSrcAlpha

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
            #pragma multi_compile_lightpass
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "Water.hlsl"
            ENDCG
        }

        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
