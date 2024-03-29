Shader "Custom/Grass"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _AlphaCutout("Alpha Cutout", Range(0, 1)) = 0.5
        _ColorTex("Color Texture", 2D) = "white" {}
        _TipColor("Tip Color", Color) = (0, 0, 0, 1)
        _TipColorShift("Tip Color Shift", Range(0, 1)) = 0.2
        _Scale("Scale", Range(0, 3)) = 0.5
        _WindSpeed("Wind Speed", Range(0, 1)) = 0.5
        _WindStrength("Wind Strength", Range(0, 1)) = 0.5
    }

     SubShader
     {
        Tags {
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
            // "LightMode" = "ForwardBase"
        }

        Pass
        {
            Name "Grass"

            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "Grass.hlsl"
            ENDCG
        }


        Pass
        {
            Name "GrassAdd"

            Tags { "LightMode" = "ForwardAdd" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "Grass.hlsl"
            ENDCG
        }

        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
