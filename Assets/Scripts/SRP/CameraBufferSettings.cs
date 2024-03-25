using UnityEngine;

[System.Serializable]
public struct CameraBufferSettings
{
	public bool allowHDR;

	public bool copyColor, copyColorReflection,
				copyDepth, copyDepthReflections,
				copyNormal, copyNormalReflections;

	[Range(0.0625f, 2f)]
	public float renderScale;

	[Range(0, 1080)]
	public int pixelHeight;

	public enum SamplerStateFilterMode
	{
		Point = 0,
		Linear = 1,
		Trilinear = 2,
	}

	public SamplerStateFilterMode filterMode;
}

