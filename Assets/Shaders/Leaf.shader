Shader "Custom/Leaf"
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
        _Extrude("Extrude", Range(0, 1)) = 0.5
    }

     SubShader
     {
        Tags {
            "RenderType" = "TransparentLeaf"
            "PreviewType" = "Plane"
            "LightMode" = "ForwardBase"
        }

        Pass
        {
            Name "Leaf"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "Leaf.hlsl"
            ENDCG
        }
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
