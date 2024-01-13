Shader "VoxelShader"
{
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #define UNITY_INDIRECT_DRAW_ARGS IndirectDrawIndexedArgs
            #include "UnityIndirect.cginc"

            uniform int _GridWidth;
            uniform int _GridHeight;
            uniform float _Spacing;
            uniform float4x4 _ObjectToWorld;

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 color : COLOR0;
            }; 

            StructuredBuffer<float3> _Colors;

            v2f vert(appdata_base v, uint svInstanceID : SV_InstanceID)
            {
                InitIndirectDrawArgs(0);
                v2f o;
                uint cmdID = GetCommandID(0);
                uint instanceID = GetIndirectInstanceID(svInstanceID);
                float x = instanceID % _GridWidth;
                float z = instanceID / _GridWidth;
                
                float3 gridPosition = float3(x - _GridWidth / 2, 0, z - _GridHeight / 2) * _Spacing;
                float4 wpos = mul(_ObjectToWorld, v.vertex + float4(gridPosition, 0));

                o.pos = mul(UNITY_MATRIX_VP, wpos);
                // Alternating green color based on instance ID
                // Checkerboard pattern
                bool isEven = ((x + z) % 2) == 0;
                o.color = isEven ? float4(0.0, 1.0, 0.0, 1.0) : float4(0.0, 0.5, 0.0, 1.0); // Adjust green tones as desired

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return i.color;
            }
            ENDCG
        }
    }
}