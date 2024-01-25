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

    public void GeneratePoints()
    {
        Random.InitState(seed);

        var vertices = _mesh.vertices;
        var normals = _mesh.normals;
        var triangles = _mesh.triangles;
        var triangleAreas = new float[triangles.Length / 3];

        var totalArea = 0.0f;
        for (var i = 0; i < triangles.Length; i += 3)
        {
            var v1 = vertices[triangles[i]];
            var v2 = vertices[triangles[i + 1]];
            var v3 = vertices[triangles[i + 2]];
            var area = TriangleArea(v1, v2, v3);
            totalArea += area;
            triangleAreas[i / 3] = area;
        }

        var totalPoints = Mathf.CeilToInt(totalArea * _density);
        for (var i = 0; i < triangleAreas.Length; i++)
        {
            var pointsInThisTriangle = Mathf.CeilToInt(triangleAreas[i] / totalArea * totalPoints);
            for (var j = 0; j < pointsInThisTriangle; j++)
            {
                (Vector3 point, Vector3 normal) = RandomPointAndNormalInTriangle(
                    vertices[triangles[i * 3]], vertices[triangles[i * 3 + 1]], vertices[triangles[i * 3 + 2]],
                    normals[triangles[i * 3]], normals[triangles[i * 3 + 1]], normals[triangles[i * 3 + 2]]);

                Debug.DrawRay(point, normal, Color.red, 10);
            }
        }
    }

    float TriangleArea(Vector3 v1, Vector3 v2, Vector3 v3)
    {
        return Vector3.Cross(v1 - v2, v1 - v3).magnitude * 0.5f;
    }

    (Vector3, Vector3) RandomPointAndNormalInTriangle(Vector3 v1, Vector3 v2, Vector3 v3, Vector3 n1, Vector3 n2, Vector3 n3)
    {
        var r1 = Mathf.Sqrt(Random.value);
        var r2 = Random.value;
        var point = (1 - r1) * v1 + r1 * (1 - r2) * v2 + r1 * r2 * v3;
        var normal = ((1 - r1) * n1 + r1 * (1 - r2) * n2 + r1 * r2 * n3).normalized;
        return (point, normal);
    }
}

// using UnityEngine;

// public class MeshSurfaceSampler : MonoBehaviour
// {

//     [SerializeField] float _density = 1;
//     [SerializeField] int seed = 42;

//     Mesh _mesh;

//     void OnEnable()
//     {
//         _mesh = GetComponent<MeshFilter>().mesh;
//         GeneratePoints();
//     }

//     void GeneratePoints()
//     {
//         Random.InitState(seed);

//         var vertices = _mesh.vertices;
//         var normals = _mesh.normals;
//         var triangles = _mesh.triangles;
//         var triangleAreas = new float[triangles.Length / 3];

//         float totalArea = 0;
//         for (int i = 0; i < triangles.Length; i += 3)
//         {
//             Vector3 v1 = vertices[triangles[i]];
//             Vector3 v2 = vertices[triangles[i + 1]];
//             Vector3 v3 = vertices[triangles[i + 2]];
//             totalArea += TriangleArea(v1, v2, v3);
//             triangleAreas[i / 3] = totalArea;
//         }

//         int totalPoints = Mathf.CeilToInt(totalArea * _density);
//         for (int i = 0; i < totalPoints; i++)
//         {
//             var (point, normal) = RandomPointAndNormalOnMesh(vertices, normals, triangles, triangleAreas, totalArea);
//             Debug.DrawRay(point, normal, Color.red, 10);

//             // Do something with the point, like instantiate an object
//             Debug.Log("Point " + i + ": " + point);

//         }
//     }

//     float TriangleArea(Vector3 v1, Vector3 v2, Vector3 v3)
//     {
//         return Vector3.Cross(v1 - v2, v1 - v3).magnitude * 0.5f;
//     }

//     (Vector3, Vector3) RandomPointAndNormalOnMesh(Vector3[] vertices, Vector3[] normals, int[] triangles, float[] triangleAreas, float totalArea)
//     {
//         // Choose a random triangle weighted by area
//         float randomWeight = Random.value * totalArea;
//         float cumulativeWeight = 0;
//         int chosenTriangleIndex = 0;
//         for (int i = 0; i < triangleAreas.Length; i++)
//         {
//             cumulativeWeight += triangleAreas[i];
//             if (randomWeight <= cumulativeWeight)
//             {
//                 chosenTriangleIndex = i;
//                 break;
//             }
//         }

//         Vector3 v1 = vertices[triangles[chosenTriangleIndex]];
//         Vector3 v2 = vertices[triangles[chosenTriangleIndex + 1]];
//         Vector3 v3 = vertices[triangles[chosenTriangleIndex + 2]];

//         Vector3 n1 = normals[triangles[chosenTriangleIndex]];
//         Vector3 n2 = normals[triangles[chosenTriangleIndex + 1]];
//         Vector3 n3 = normals[triangles[chosenTriangleIndex + 2]];

//         float r1 = Mathf.Sqrt(Random.value);
//         float r2 = Random.value;
//         float a = 1 - r1;
//         float b = r1 * (1 - r2);
//         float c = r1 * r2;

//         Vector3 point = a * v1 + b * v2 + c * v3;
//         Vector3 normal = (a * n1 + b * n2 + c * n3).normalized;

//         return (point, normal);
//     }
// }

// using UnityEngine;

// public class MeshSurfaceSampler : MonoBehaviour
// {

//     [SerializeField] float _density = 1;
//     [SerializeField] int seed = 42;

//     Mesh _mesh;

//     void OnEnable()
//     {
//         _mesh = GetComponent<MeshFilter>().mesh;
//         GeneratePoints();
//     }

//     void GeneratePoints()
//     {
//         Random.InitState(seed);

//         Vector3[] vertices = _mesh.vertices;
//         int[] triangles = _mesh.triangles;
//         Vector3[] normals = _mesh.normals;

//         float totalArea = 0;
//         for (int i = 0; i < triangles.Length; i += 3)
//         {
//             Vector3 v1 = vertices[triangles[i]];
//             Vector3 v2 = vertices[triangles[i + 1]];
//             Vector3 v3 = vertices[triangles[i + 2]];
//             totalArea += TriangleArea(v1, v2, v3);
//         }

//         int totalPoints = Mathf.CeilToInt(totalArea * _density);
//         for (int i = 0; i < totalPoints; i++)
//         {
//             var (point, normal) = RandomPointAndNormalOnMesh(vertices, normals, triangles);
//             Debug.DrawRay(point, normal, Color.red, 10);

//             // Do something with the point, like instantiate an object
//             Debug.Log("Point " + i + ": " + point);

//         }
//     }

//     float TriangleArea(Vector3 v1, Vector3 v2, Vector3 v3)
//     {
//         return Vector3.Cross(v1 - v2, v1 - v3).magnitude * 0.5f;
//     }

//     (Vector3, Vector3) RandomPointAndNormalOnMesh(Vector3[] vertices, Vector3[] normals, int[] triangles)
//     {
//         int triangleIndex = Random.Range(0, triangles.Length / 3) * 3;
//         Vector3 v1 = vertices[triangles[triangleIndex]];
//         Vector3 v2 = vertices[triangles[triangleIndex + 1]];
//         Vector3 v3 = vertices[triangles[triangleIndex + 2]];

//         Vector3 n1 = normals[triangles[triangleIndex]];
//         Vector3 n2 = normals[triangles[triangleIndex + 1]];
//         Vector3 n3 = normals[triangles[triangleIndex + 2]];

//         float r1 = Mathf.Sqrt(Random.value);
//         float r2 = Random.value;
//         float a = 1 - r1;
//         float b = r1 * (1 - r2);
//         float c = r1 * r2;

//         Vector3 point = a * v1 + b * v2 + c * v3;
//         Vector3 normal = (a * n1 + b * n2 + c * n3).normalized;

//         return (point, normal);
//     }
// }
