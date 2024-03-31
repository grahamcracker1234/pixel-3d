using System.Collections.Generic;
using UnityEngine;

public class MeshSurfaceSampler : MonoBehaviour
{

    [SerializeField] float _density = 1;
    [SerializeField] int seed = 42;

    Mesh _mesh;

    [HideInInspector] public Vector3[] points;
    [HideInInspector] public Vector3[] normals;

    void OnEnable()
    {
        _mesh = GetComponent<MeshFilter>().mesh;
        GeneratePoints();
    }

    public void GeneratePoints()
    {
        Random.InitState(seed);

        var tris = _mesh.triangles;
        var triangleAreas = new float[tris.Length / 3];

        var totalArea = 0.0f;
        for (var i = 0; i < tris.Length; i += 3)
        {
            var v1 = _mesh.vertices[tris[i]];
            var v2 = _mesh.vertices[tris[i + 1]];
            var v3 = _mesh.vertices[tris[i + 2]];
            var area = TriangleArea(v1, v2, v3);
            totalArea += area;
            triangleAreas[i / 3] = area;
        }

        var pointList = new List<Vector3>();
        var normalList = new List<Vector3>();

        var totalPoints = Mathf.CeilToInt(totalArea * _density);
        for (var i = 0; i < triangleAreas.Length; i++)
        {
            var pointsInThisTriangle = Mathf.CeilToInt(triangleAreas[i] / totalArea * totalPoints);
            for (var j = 0; j < pointsInThisTriangle; j++)
            {
                (Vector3 point, Vector3 normal) = RandomPointAndNormalInTriangle(
                    _mesh.vertices[tris[i * 3]], _mesh.vertices[tris[i * 3 + 1]], _mesh.vertices[tris[i * 3 + 2]],
                    _mesh.normals[tris[i * 3]], _mesh.normals[tris[i * 3 + 1]], _mesh.normals[tris[i * 3 + 2]]);

                pointList.Add(transform.TransformPoint(point));
                // normalList.Add(normal);
                normalList.Add(transform.TransformDirection(normal));
                // Debug.DrawRay(point, normal, Color.red, 10);
            }
        }
        points = pointList.ToArray();
        normals = normalList.ToArray();
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

    public bool ArePointsGenerated()
    {
        return points != null && points.Length > 0;
    }
}
