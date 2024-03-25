#ifndef CUSTOM_CAMERA_RENDERER_PASSES_INCLUDED
#define CUSTOM_CAMERA_RENDERER_PASSES_INCLUDED

TEXTURE2D(_SourceTexture);

// This overrides the default sampler for the post-processing stack
int _SamplerStateFilterMode;

struct Varyings {
	float4 positionCS : SV_POSITION;
	float2 screenUV : VAR_SCREEN_UV;
};

struct NormalAttributes {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
};

struct NormalVaryings {
	float3 normal : TEXCOORD0;
};

NormalVaryings NormalPassVertex (uint vertexID : SV_VertexID, NormalAttributes input) {
	NormalVaryings output;
	output.normal = TransformObjectToWorldNormal(input.normal);
	return output;
}

Varyings DefaultPassVertex(uint vertexID : SV_VertexID) {
	Varyings output;
	output.positionCS = float4(
		vertexID <= 1 ? -1.0 : 3.0,
		vertexID == 1 ? 3.0 : -1.0,
		0.0, 1.0
	);
	output.screenUV = float2(
		vertexID <= 1 ? 0.0 : 2.0,
		vertexID == 1 ? 2.0 : 0.0
	);
	if (_ProjectionParams.x < 0.0) {
		output.screenUV.y = 1.0 - output.screenUV.y;
	}
	return output;
}

float4 CopyPassFragment (Varyings input) : SV_TARGET {
	if (_SamplerStateFilterMode == 0) {
		return SAMPLE_TEXTURE2D_LOD(_SourceTexture, sampler_point_clamp, input.screenUV, 0);
	} else if (_SamplerStateFilterMode == 1) {
		return SAMPLE_TEXTURE2D_LOD(_SourceTexture, sampler_linear_clamp, input.screenUV, 0);
	} else {
		return SAMPLE_TEXTURE2D_LOD(_SourceTexture, sampler_trilinear_clamp, input.screenUV, 0);
	}
	// return SAMPLE_TEXTURE2D_LOD(_SourceTexture, sampler_linear_clamp, input.screenUV, 0);
}

float CopyDepthPassFragment (Varyings input) : SV_DEPTH {
	return SAMPLE_DEPTH_TEXTURE_LOD(_SourceTexture, sampler_point_clamp, input.screenUV, 0);
}

float4 NormalPassFragment (NormalVaryings input) : SV_TARGET {
	float3 normalColor = input.normal * 0.5 + 0.5;
	return float4(normalColor, 1.0);
}

float4 PreFXPassFragment (Varyings input) : SV_TARGET {
	float4 color = SAMPLE_TEXTURE2D_LOD(_SourceTexture, sampler_linear_clamp, input.screenUV, 0);
	// return float4(1, 0, 0, 1);
	// color.rgb = pow(color.rgb, 1.0 / 2.2);
	return color;
}

// float4 CopyDepthNormalPassFragment (Varyings input) : SV_TARGET {
// 	float4 depth = SAMPLE_TEXTURE2D_LOD(_SourceTexture, sampler_linear_clamp, input.screenUV, 0);
// 	float4 normal = float4(0.0, 0.0, 1.0, 1.0);
// 	return float4(normal.xyz, depth.x);
// }

#endif