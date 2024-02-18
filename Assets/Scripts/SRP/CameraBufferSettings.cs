﻿using UnityEngine;

[System.Serializable]
public struct CameraBufferSettings
{
	public bool allowHDR;

	public bool copyColor, copyColorReflection, copyDepth, copyDepthReflections;

	[Range(0.0625f, 2f)]
	public float renderScale;

	[Range(0, 1080)]
	public int pixelHeight;
}