using UnityEngine;
using UnityEditor;

[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
public class MeshGenerator : MonoBehaviour
{
	public Texture2D heightMap;
	public Vector3 size = new Vector3(10, 3, 10);
	public Vector2Int sampleCount = new Vector2Int(25, 25);
	[HideInInspector] public MeshData meshData;
	[HideInInspector] public Mesh mesh;

	public void GenerateTerrainMesh()
	{
		// Check if the height map is null
		if (heightMap == null)
		{
			Debug.LogError("Height map is null");
			return;
		}

		// Initialize the mesh data
		meshData = new MeshData(sampleCount.x, sampleCount.y);

		// Loop through each vertex
		var index = 0;
		for (var y = 0; y < sampleCount.y; y++)
		{
			for (var x = 0; x < sampleCount.x; x++)
			{
				// Calculate the uv, vertex position
				var uv = new Vector2(x, y) / (sampleCount - Vector2.one);
				var vertex = (uv - Vector2.one / 2) * new Vector2(size.x, size.z);
				var heightValue = GetTrueHeight(uv);

				// Set the vertex position and uv
				meshData.vertices[index] = new Vector3(vertex.x, heightValue, vertex.y);
				meshData.uvs[index] = uv;

				// Add triangles if not at the edge
				if (x < sampleCount.x - 1 && y < sampleCount.y - 1)
				{
					meshData.AddTriangle(index, index + sampleCount.x + 1, index + sampleCount.x);
					meshData.AddTriangle(index + sampleCount.x + 1, index, index + 1);
				}

				// Increment the index
				index++;
			}
		}

		// Create the mesh
		mesh = meshData.CreateMesh();

		var meshFilter = GetComponent<MeshFilter>();
		if (meshFilter != null)
			meshFilter.sharedMesh = mesh;
		else
			Debug.LogError("Mesh filter is null");

		var meshCollider = GetComponent<MeshCollider>();
		if (meshCollider != null)
			meshCollider.sharedMesh = mesh;
	}

	// Get the height of the terrain at the given uv from the mesh
	public float GetMeshHeight(Vector2 uv)
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

		// Get the four vertices of the square (assuming row major and clockwise order)
		var v1 = meshData.vertices[zIndex * sampleCount.x + xIndex];
		var v2 = meshData.vertices[zIndex * sampleCount.x + xIndex + 1];
		var v3 = meshData.vertices[(zIndex + 1) * sampleCount.x + xIndex];
		var v4 = meshData.vertices[(zIndex + 1) * sampleCount.x + xIndex + 1];

		// Bilinear interpolation
		var xRem = xIndexPrecise - xIndex;
		var zRem = zIndexPrecise - zIndex;
		var height1 = Mathf.Lerp(v1.y, v2.y, xRem);
		var height2 = Mathf.Lerp(v3.y, v4.y, xRem);
		return Mathf.Lerp(height1, height2, zRem);
	}

	// Get the true height of the terrain at the given uv from the height map
	public float GetTrueHeight(Vector2 uv)
	{
		var x = Mathf.RoundToInt(uv.x * heightMap.width);
		var y = Mathf.RoundToInt(uv.y * heightMap.height);
		return heightMap.GetPixel(x, y).grayscale * size.y; ;
	}

	// Check if the mesh and mesh data are generated
	public bool IsMeshGenerated()
	{
		return mesh != null && meshData != null;
	}
}

// MeshData class which allows for easy mesh creation
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
		var mesh = new Mesh
		{
			vertices = vertices,
			triangles = triangles,
			uv = uvs
		};
		mesh.RecalculateNormals();
		return mesh;
	}

}

// Custom editor which adds a button to generate the terrain
[CustomEditor(typeof(MeshGenerator))]
public class MeshGeneratorEditor : Editor
{
	public override void OnInspectorGUI()
	{
		var script = (MeshGenerator)target;
		DrawDefaultInspector();
		GUILayout.Space(10);
		if (GUILayout.Button("Generate Terrain"))
			script.GenerateTerrainMesh();
	}
}