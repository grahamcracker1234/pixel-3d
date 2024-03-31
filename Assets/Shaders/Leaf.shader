Shader "Custom/Leaf"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _AlphaCutout("Alpha Cutout", Range(0, 1)) = 0.5

        [MaterialToggle] _UseShadeTex ("Use Shade Texture", Float) = 0
        _ShadeTex ("Shade Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _DarknessColor ("Darkness Color", Color) = (0.5,0.5,0.5,1)
        _DarknessMidpoint ("Darkness Midpoint", Range(0, 1)) = 0.5
        _ShadowThreshold ("Shadow Threshold", Range(0, 1)) = 0.5
        _ShadeBitDepth ("Shade Bit Depth", Range(0, 15)) = 5

        _TipColor("Tip Color", Color) = (0, 0, 0, 1)
        _TipColorShift("Tip Color Shift", Range(0, 1)) = 0.2
        _Scale("Scale", Range(0, 3)) = 0.5
        _WindSpeed("Wind Speed", Range(0, 1)) = 0.5
        _WindStrength("Wind Strength", Range(0, 1)) = 0.5
        _Extrude("Extrude", Range(-5, 5)) = 0.5
    }

     SubShader
     {
        Tags {
            // "RenderType" = "Opaque"
            "RenderType" = "TransparentLeaf"
            "PreviewType" = "Plane"
        }

        Pass
        {
            Name "Leaf"

            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            // #include "Leaf.hlsl"
            #include "LeafCel.hlsl"
            ENDCG
        }

        Pass
        {
            Name "LeafAdd"

            Tags { "LightMode" = "ForwardAdd" }

            CGPROGRAM
            #pragma multi_compile_lightpass
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            // #include "Leaf.hlsl"
            #include "LeafCel.hlsl"
            ENDCG
        }

        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
