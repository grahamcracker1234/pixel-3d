using UnityEngine;

public class MeshSurfaceSampler : MonoBehaviour
{

    [SerializeField] float _density = 1;
    [SerializeField] int seed = 42;

    Mesh _mesh;

    void OnEnable()
    {
        _mesh = GetComponent<MeshFilter>().mesh;
        GeneratePoints();
    }

    void GeneratePoints()
    {
        Random.InitState(seed);

        Vector3[] vertices = _mesh.vertices;
        int[] triangles = _mesh.triangles;
        Vector3[] normals = _mesh.normals;

        float totalArea = 0;
        for (int i = 0; i < triangles.Length; i += 3)
        {
            Vector3 v1 = vertices[triangles[i]];
            Vector3 v2 = vertices[triangles[i + 1]];
            Vector3 v3 = vertices[triangles[i + 2]];
            totalArea += TriangleArea(v1, v2, v3);
        }

        int totalPoints = Mathf.CeilToInt(totalArea * _density);
        for (int i = 0; i < totalPoints; i++)
        {
            var (point, normal) = RandomPointAndNormalOnMesh(vertices, normals, triangles);
            Debug.DrawRay(point, normal, Color.red, 10);

            // Do something with the point, like instantiate an object
            Debug.Log("Point " + i + ": " + point);

        }
    }

    float TriangleArea(Vector3 v1, Vector3 v2, Vector3 v3)
    {
        return Vector3.Cross(v1 - v2, v1 - v3).magnitude * 0.5f;
    }

    (Vector3, Vector3) RandomPointAndNormalOnMesh(Vector3[] vertices, Vector3[] normals, int[] triangles)
    {
        int triangleIndex = Random.Range(0, triangles.Length / 3) * 3;
        Vector3 v1 = vertices[triangles[triangleIndex]];
        Vector3 v2 = vertices[triangles[triangleIndex + 1]];
        Vector3 v3 = vertices[triangles[triangleIndex + 2]];

        Vector3 n1 = normals[triangles[triangleIndex]];
        Vector3 n2 = normals[triangles[triangleIndex + 1]];
        Vector3 n3 = normals[triangles[triangleIndex + 2]];

        float r1 = Mathf.Sqrt(Random.value);
        float r2 = Random.value;
        float a = 1 - r1;
        float b = r1 * (1 - r2);
        float c = r1 * r2;

        Vector3 point = a * v1 + b * v2 + c * v3;
        Vector3 normal = (a * n1 + b * n2 + c * n3).normalized;

        return (point, normal);
    }
}
