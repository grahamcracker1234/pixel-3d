using UnityEngine;

[System.Serializable]
public struct CameraBufferSettings
{
	public bool allowHDR;

	public bool copyColor, copyColorReflection, copyDepth, copyDepthReflections;

	[Range(0.1f, 2f)]
	public float renderScale;
}