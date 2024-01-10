using UnityEngine;
using UnityEditor;
using UnityEditor.PackageManager.UI;

[ExecuteInEditMode]
[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshCollider))]
public class MeshGenerator : MonoBehaviour
{
	public Texture2D heightMap;
	public Vector3 size = new Vector3(10, 3, 10);
	public Vector2Int sampleCount = new Vector2Int(25, 25);

	public MeshData GenerateTerrainMesh()
	{
		var meshData = new MeshData(sampleCount.x, sampleCount.y);

		var index = 0;
		for (var y = 0; y < sampleCount.y; y++)
		{
			for (var x = 0; x < sampleCount.x; x++)
			{
				var uv = new Vector2(x, y) / (sampleCount - Vector2.one);
				var heightValue = GetMeshHeight(uv);

				var vertex = (uv - Vector2.one / 2) * new Vector2(size.x, size.z); ;

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

		var meshFiler = GetComponent<MeshFilter>();
		meshFiler.sharedMesh = meshData.CreateMesh();
		GetComponent<MeshCollider>().sharedMesh = meshFiler.sharedMesh;

		return meshData;
	}

	public float GetMeshHeight(Vector2 uv)
	{
		var x = Mathf.RoundToInt(uv.x * heightMap.width);
		var y = Mathf.RoundToInt(uv.y * heightMap.height);
		return GetMeshHeight(x, y);
	}

	public float GetMeshHeight(int x, int y)
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