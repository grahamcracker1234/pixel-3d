using UnityEngine;
using UnityEditor;
using System;

[ExecuteInEditMode]
[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshCollider))]
[RequireComponent(typeof(MeshRenderer))]
public class MeshGenerator : MonoBehaviour
{
	public Texture2D heightMap;
	public Vector3 size = new Vector3(10, 3, 10);
	public Vector2Int sampleCount = new Vector2Int(25, 25);
	[HideInInspector] public MeshData meshData;
	[HideInInspector] public Mesh mesh;

	public MeshData GenerateTerrainMesh()
	{
		meshData = new MeshData(sampleCount.x, sampleCount.y);

		var index = 0;
		for (var y = 0; y < sampleCount.y; y++)
		{
			for (var x = 0; x < sampleCount.x; x++)
			{
				var uv = new Vector2(x, y) / (sampleCount - Vector2.one);
				var vertex = (uv - Vector2.one / 2) * new Vector2(size.x, size.z);

				var heightValue = GetMeshHeightUV(uv);

				meshData.vertices[index] = new Vector3(vertex.x, heightValue, vertex.y);
				meshData.uvs[index] = uv;

				if (x < sampleCount.x - 1 && y < sampleCount.y - 1)
				{
					meshData.AddTriangle(index, index + sampleCount.x + 1, index + sampleCount.x);
					meshData.AddTriangle(index + sampleCount.x + 1, index, index + 1);
				}

				index++;
			}
		}

		mesh = meshData.CreateMesh();

		GetComponent<MeshFilter>().sharedMesh = mesh;
		GetComponent<MeshCollider>().sharedMesh = mesh;

		return meshData;
	}

	public float GetMeshHeightWorld(Vector2 uv, bool debug = false)
	{
		// Calculate the precise indices
		float xIndexPrecise = uv.x * (sampleCount.x - 1);
		float zIndexPrecise = uv.y * (sampleCount.y - 1);

		// Calculate the indices of the vertices around the point
		var xIndex = Mathf.FloorToInt(uv.x * (sampleCount.x - 1));
		var zIndex = Mathf.FloorToInt(uv.y * (sampleCount.y - 1));

		// Ensure indices are within the bounds of the mesh
		xIndex = Mathf.Clamp(xIndex, 0, sampleCount.x - 2);
		zIndex = Mathf.Clamp(zIndex, 0, sampleCount.y - 2);

		// Get the four vertices of the square
		var v1 = meshData.vertices[zIndex * sampleCount.x + xIndex];
		var v2 = meshData.vertices[zIndex * sampleCount.x + xIndex + 1];
		var v3 = meshData.vertices[(zIndex + 1) * sampleCount.x + xIndex];
		var v4 = meshData.vertices[(zIndex + 1) * sampleCount.x + xIndex + 1];

		if (debug)
		{
			Debug.Log("debug");
			Debug.Log("xIndex: " + xIndex);
			Debug.Log("zIndex: " + zIndex);
			Debug.Log("uv: " + uv);

			// Debug.DrawRay(worldPosition, Vector3.up * 10, Color.blue, 1, false);

			var calculatedPosFromUV = new Vector3(uv.x * size.x + mesh.bounds.min.x, 0, uv.y * size.z + mesh.bounds.min.z);
			Debug.DrawRay(transform.TransformPoint(calculatedPosFromUV), Vector3.up * 10, Color.blue, 1, false);
			Debug.DrawRay(transform.TransformPoint(v1), Vector3.up * 10, Color.blue, 1, false);
			Debug.DrawRay(transform.TransformPoint(v4), Vector3.up * 10, Color.blue, 1, false);
			Debug.DrawLine(transform.TransformPoint(v1), transform.TransformPoint(v2), Color.green, 1, false);
			Debug.DrawLine(transform.TransformPoint(v1), transform.TransformPoint(v3), Color.green, 1, false);
			Debug.DrawLine(transform.TransformPoint(v2), transform.TransformPoint(v4), Color.green, 1, false);
			Debug.DrawLine(transform.TransformPoint(v3), transform.TransformPoint(v4), Color.green, 1, false);
		}

		// Bilinear interpolation
		float xRem = xIndexPrecise - xIndex;
		float zRem = zIndexPrecise - zIndex;

		float height1 = Mathf.Lerp(v1.y, v2.y, xRem);
		float height2 = Mathf.Lerp(v3.y, v4.y, xRem);
		return Mathf.Lerp(height1, height2, zRem);
	}

	private Vector3 CalculateBarycentricCoordinates(Vector2 uv, Vector3 v1, Vector3 v2, Vector3 v3)
	{
		Vector3 p = new Vector3(uv.x, uv.y, 0);

		Vector3 a = new Vector3(v1.x, v1.z, 0); // Convert to 2D
		Vector3 b = new Vector3(v2.x, v2.z, 0); // Convert to 2D
		Vector3 c = new Vector3(v3.x, v3.z, 0); // Convert to 2D

		// Compute vectors from point p to vertices
		Vector3 vectorPA = a - p;
		Vector3 vectorPB = b - p;
		Vector3 vectorPC = c - p;

		// Compute the areas of the sub-triangles and the full triangle
		float areaTriangleABC = Vector3.Cross(a - b, a - c).magnitude;
		float areaPBC = Vector3.Cross(b - c, vectorPB).magnitude;
		float areaPCA = Vector3.Cross(c - a, vectorPC).magnitude;
		float areaPAB = Vector3.Cross(a - b, vectorPA).magnitude;

		// Calculate the barycentric coordinates
		float lambda1 = areaPBC / areaTriangleABC;
		float lambda2 = areaPCA / areaTriangleABC;
		float lambda3 = areaPAB / areaTriangleABC;

		return new Vector3(lambda1, lambda2, lambda3);
	}


	public float GetMeshHeightUV(Vector2 uv)
	{
		var x = Mathf.RoundToInt(uv.x * heightMap.width);
		var y = Mathf.RoundToInt(uv.y * heightMap.height);
		return GetMeshHeightPixel(x, y);

		// var scaledUV = uv * (sampleCount - Vector2.one); // new Vector2(sampleCount.x - 1, sampleCount.y - 1);

		// var floorX = Mathf.RoundToInt(Mathf.Floor(scaledUV.x) / (sampleCount.x - 1) * heightMap.width);
		// var floorY = Mathf.RoundToInt(Mathf.Floor(scaledUV.y) / (sampleCount.y - 1) * heightMap.height);

		// var ceilX = Mathf.RoundToInt(Mathf.Ceil(scaledUV.x) / (sampleCount.x - 1) * heightMap.width);
		// var ceilY = Mathf.RoundToInt(Mathf.Ceil(scaledUV.y) / (sampleCount.y - 1) * heightMap.height);

		// var lerpX = scaledUV.x - floorX;
		// var lerpY = scaledUV.y - floorY;

		// var bottomLeft = GetMeshHeight(floorX, floorY);
		// var topLeft = GetMeshHeight(floorX, ceilY);
		// var bottomRight = GetMeshHeight(ceilX, floorY);
		// var topRight = GetMeshHeight(ceilX, ceilY);

		// var floorHeight = Mathf.Lerp(bottomLeft, topLeft, lerpY);
		// var ceilHeight = Mathf.Lerp(bottomRight, topRight, lerpY);

		// return Mathf.Lerp(floorHeight, ceilHeight, lerpX);

		// // var scaledUV = uv * new Vector2(heightMap.width, heightMap.height);

		// // var floorX = (int)Mathf.Floor(scaledUV.x);
		// // var floorY = (int)Mathf.Floor(scaledUV.y);

		// // var ceilX = (int)Mathf.Ceil(scaledUV.x);
		// // var ceilY = (int)Mathf.Ceil(scaledUV.y);

		// // var lerpX = scaledUV.x - floorX;
		// // var lerpY = scaledUV.y - floorY;

		// // var bottomLeft = GetMeshHeight(floorX, floorY);
		// // var topLeft = GetMeshHeight(floorX, ceilY);
		// // var bottomRight = GetMeshHeight(ceilX, floorY);
		// // var topRight = GetMeshHeight(ceilX, ceilY);

		// // var floorHeight = Mathf.Lerp(bottomLeft, topLeft, lerpY);
		// // var ceilHeight = Mathf.Lerp(bottomRight, topRight, lerpY);

		// // return Mathf.Lerp(floorHeight, ceilHeight, lerpX);

		// var roundedU = Mathf.Round(uv.x * (sampleCount.x - 1)) / (sampleCount.x - 1);
		// var roundedV = Mathf.Round(uv.y * (sampleCount.y - 1)) / (sampleCount.y - 1);
		// var x = Mathf.RoundToInt(roundedU * heightMap.width);
		// var y = Mathf.RoundToInt(roundedV * heightMap.height);
		// return GetMeshHeight(x, y);

		// var x = Mathf.RoundToInt(uv.x * heightMap.width);
		// var y = Mathf.RoundToInt(uv.y * heightMap.height);
		// return GetMeshHeight(x, y);
	}

	public float GetMeshHeightPixel(int x, int y)
	{
		return heightMap.GetPixel(x, y).grayscale * size.y;
	}
}

public class MeshData
{
	public Vector3[] vertices;
	public int[] triangles;
	public Vector2[] uvs;

	int triangleIndex;

	public MeshData(int meshWidth, int meshHeight)
	{
		vertices = new Vector3[meshWidth * meshHeight];
		uvs = new Vector2[meshWidth * meshHeight];
		triangles = new int[(meshWidth - 1) * (meshHeight - 1) * 6];
	}

	public void AddTriangle(int a, int b, int c)
	{
		triangles[triangleIndex] = a;
		triangles[triangleIndex + 1] = c;
		triangles[triangleIndex + 2] = b;
		triangleIndex += 3;
	}

	public Mesh CreateMesh()
	{
		Mesh mesh = new Mesh
		{
			vertices = vertices,
			triangles = triangles,
			uv = uvs
		};
		mesh.RecalculateNormals();
		return mesh;
	}

}

[CustomEditor(typeof(MeshGenerator))]
public class MeshGeneratorEditor : Editor
{
	public override void OnInspectorGUI()
	{
		DrawDefaultInspector();

		var script = (MeshGenerator)target;
		if (GUILayout.Button("Generate Terrain"))
		{
			script.GenerateTerrainMesh();
		}
	}
}