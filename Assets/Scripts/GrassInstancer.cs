using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Assertions;

public class GrassInstancer : MonoBehaviour
{
    // [SerializeField] int _size = 10;
    [SerializeField] int _density = 10;
    [SerializeField] Mesh mesh;
    [SerializeField] Material material;

    Matrix4x4[] matrices;
    float _size;

    void OnEnable()
    {
        var size = GetComponent<MeshRenderer>().bounds.size;
        Assert.IsTrue(size.x == size.z);
        _size = size.x;
    }

    void Update()
    {
        // Matrix4x4 P = Camera.main.projectionMatrix;
        // Matrix4x4 V = Camera.main.transform.worldToLocalMatrix;
        // Matrix4x4 VP = P * V;

        matrices = new Matrix4x4[_density * _density];

        for (int x = 0; x < _density; x++)
        {
            for (int y = 0; y < _density; y++)
            {
                var index = x + y * _density;
                var offset = (float)_density / 2 - 0.5f;
                var position = new Vector3(x - offset, 0, y - offset) * _size / _density + transform.position;
                var rotation = Quaternion.LookRotation(position - Camera.main.transform.position, Vector3.up);
                matrices[index] = Matrix4x4.TRS(position, rotation, Vector3.one);
            }
        }

        Graphics.DrawMeshInstanced(mesh, 0, material, matrices);
    }
}
