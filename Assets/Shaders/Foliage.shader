Shader "Custom/Foliage"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Blend ("Blend", Range(0, 1)) = 0.5
        _Extrude ("Extrude", Range(0, 10)) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "LightMode" = "ForwardBase"
        }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float3 normal : NORMAL;
                SHADOW_COORDS(2)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Blend;
            float _Extrude;

            #define remap(v, l1, h1, l2, h2) l2 + (v - l1) * (h2 - l2) / (h1 - l1);

            // float remap(float value, float low1, float high1, float low2, float high2)
            // {
            //     return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
            // }

            v2f vert (appdata v)
            {

                float2 uv = TRANSFORM_TEX(v.uv, _MainTex);
                // uv = remap(uv, 0, 1, -1, 1);

                float3 offset = float3(uv, 0);      
                
                // #if 0
                //     // Tangent space
                //     float3 bitangent = cross(v.normal, v.tangent.xyz) / v.tangent.w;
                //     float3x3 tangent_object = transpose(float3x3(v.tangent.xyz, bitangent, v.normal));
                //     offset = normalize(mul(tangent_object, offset));

                //     #if 1
                //         // Extrude is scaling
                //         v.vertex.xyz *= 1 + _Extrude;
                //         v.vertex.xyz += offset * _Blend;
                //     #else
                //         // Extrude is extrude
                //         v.vertex.xyz += offset * _Blend + v.normal * _Extrude;
                //     #endif
                // #else
                //     // offset = 
                //     // offset = mul(UNITY_MATRIX_V, float4(offset, 0)).xyz;
                //     // offset = mul(float4(offset, 0), UNITY_MATRIX_MV).xyz;

                //     // float3 bitangent = cross(v.normal, v.tangent.xyz) / v.tangent.w;
                //     // float3x3 tangent_object = transpose(float3x3(v.tangent.xyz, bitangent, v.normal));
                //     // offset = normalize(mul(tangent_object, offset));

                //     // v.vertex.xyz += offset * _Blend + v.normal * _Extrude;
                    
                //     // Billboard effect
                //     float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                //     v.vertex = mul(UNITY_MATRIX_V, worldPos);

                //     float3 cameraRight = float3(unity_CameraToWorld._m00, unity_CameraToWorld._m01, unity_CameraToWorld._m02);
                //     float3 cameraUp = float3(unity_CameraToWorld._m10, unity_CameraToWorld._m11, unity_CameraToWorld._m12);
                //     worldPos.xyz += cameraRight * v.vertex.x + cameraUp * v.vertex.y;
                //     o.vertex = UnityObjectToClipPos(worldPos);
                //     // v.vertex = UnityObjectToClipPos(viewPos);
                // #endif
                // // offset = mul(float4(offset, 0), unity_ObjectToWorld).xyz;

                v2f o;
                
                // // Billboard effect
                // float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                // float4 viewPos = mul(UNITY_MATRIX_V, worldPos);
                // o.pos = UnityObjectToClipPos(viewPos);

                // // Align quad with camera
                // float3 cameraRight = float3(unity_CameraToWorld._m00, unity_CameraToWorld._m01, unity_CameraToWorld._m02);
                // float3 cameraUp = float3(unity_CameraToWorld._m10, unity_CameraToWorld._m11, unity_CameraToWorld._m12);
                // worldPos.xyz += cameraRight * v.vertex.x + cameraUp * v.vertex.y;
                // o.pos = UnityObjectToClipPos(worldPos);

                //                 // Calculate the world position of the quad's center
                // float4 centerWorldPos = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));

                // // Calculate the world position of the current vertex
                // float4 vertexWorldPos = mul(unity_ObjectToWorld, v.vertex);

                // // Calculate direction vectors for the billboard
                // float3 cameraRight = float3(unity_CameraToWorld._m00, unity_CameraToWorld._m01, unity_CameraToWorld._m02);
                // float3 cameraUp = float3(unity_CameraToWorld._m10, unity_CameraToWorld._m11, unity_CameraToWorld._m12);

                // // Adjust vertex position to face the camera
                // float3 adjustedPos = centerWorldPos.xyz 
                //                      + cameraRight * (vertexWorldPos.x - centerWorldPos.x)
                //                      + cameraUp * (vertexWorldPos.y - centerWorldPos.y);

                // // Convert to clip space
                // o.pos = UnityObjectToClipPos(float4(adjustedPos, 1.0));

                // Compute rotation to align quad's normal with camera view direction
                // float3 viewDir = normalize(UnityWorldSpaceViewDir(v.vertex));
                // float3 alignedDir = float3(0, 0, 1); // Assuming quad's original normal is (0, 0, 1)
                // quaternion rot = quaternion.LookRotation(alignedDir, viewDir);

                // // Rotate vertex around center
                // float3 centeredVertex = v.vertex.xyz - float3(0.5, 0.5, 0); // Assuming center is at (0.5, 0.5)
                // centeredVertex = mul(rot, centeredVertex);
                // float4 worldPos = mul(unity_ObjectToWorld, float4(centeredVertex + float3(0.5, 0.5, 0), 1));


                // Calculate view direction in world space
                float3 viewDir = normalize(UnityWorldSpaceViewDir(v.normal));
                
                // Construct a rotation matrix to align quad's forward (z) with view direction
                float3 up = float3(0, 1, 0); // World up vector
                float3 right = normalize(cross(up, viewDir));
                up = cross(viewDir, right);
                float4x4 rotationMatrix = float4x4(
                    float4(right, 0),
                    float4(up, 0),
                    float4(viewDir, 0),
                    float4(0, 0, 0, 1)
                );

                // Rotate vertex around center
                float3 centeredVertex = v.vertex.xyz - float3(0.5, 0.5, 0); // Center at (0.5, 0.5)
                centeredVertex = mul(rotationMatrix, float4(centeredVertex, 1)).xyz;
                float4 worldPos = mul(unity_ObjectToWorld, float4(centeredVertex + float3(0.5, 0.5, 0), 1));

                // Convert to clip space
                o.pos = UnityObjectToClipPos(lerp(v.vertex, worldPos, _Blend));

                // o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                TRANSFER_SHADOW(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return float4(i.uv, 0, 1);
            }
            ENDCG
        }
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}