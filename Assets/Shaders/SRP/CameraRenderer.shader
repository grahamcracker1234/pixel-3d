Shader "Hidden/Custom RP/Camera Renderer" {
	SubShader {
		Cull Off
		ZTest Always
		ZWrite Off
		
		HLSLINCLUDE
		#include "Assets/ShaderLibrary/Common.hlsl"
		#include "CameraRendererPasses.hlsl"
		ENDHLSL

		Pass {
			Name "Copy"

			Blend [_CameraSrcBlend] [_CameraDstBlend]

			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex DefaultPassVertex
				#pragma fragment CopyPassFragment
			ENDHLSL
		}

		Pass {
			Name "Copy Depth"

			ColorMask 0
			ZWrite On
			
			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex DefaultPassVertex
				#pragma fragment CopyDepthPassFragment
			ENDHLSL
		}

		Pass {
			Name "Normal"

			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex NormalPassVertex
				#pragma fragment NormalPassFragment
			ENDHLSL
		}

		Pass {
			Name "PreFX"

			// ColorMask 0
			// ZWrite On
			
			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex DefaultPassVertex
				#pragma fragment PreFXPassFragment
			ENDHLSL
		}
	}
}