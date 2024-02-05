using System;
using UnityEngine.Rendering;
using UnityEngine;

[Serializable]
public class CameraSettings
{

	[RenderingLayerMaskField]
	public int renderingLayerMask = -1;

	public bool maskLights = false;

	public enum RenderScaleMode { Inherit, Multiply, Override }

	public RenderScaleMode renderScaleMode = RenderScaleMode.Inherit;

	[Range(0.1f, 2f)]
	public float renderScale = 1f;

	public bool overridePostFX = false;

	public PostFXSettings postFXSettings = default;

	[Serializable]
	public struct FinalBlendMode
	{

		public BlendMode source, destination;
	}

	public FinalBlendMode finalBlendMode = new FinalBlendMode
	{
		source = BlendMode.One,
		destination = BlendMode.Zero
	};

	public bool copyColor = true, copyDepth = true;

	public float GetRenderScale(float scale)
	{
		return
			renderScaleMode == RenderScaleMode.Inherit ? scale :
			renderScaleMode == RenderScaleMode.Override ? renderScale :
			scale * renderScale;
	}
}