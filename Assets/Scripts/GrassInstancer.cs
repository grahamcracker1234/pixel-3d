using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Assertions;

[RequireComponent(typeof(MeshRenderer))]
public class GrassInstancer : MonoBehaviour
{
    [SerializeField] int _density = 10;
    [SerializeField] Mesh _mesh;
    [SerializeField] Material _material;
    [SerializeField] int _seed = 42;

    MeshGenerator _meshGenerator;

    Matrix4x4[] matrices;
    float _size;

    void OnEnable()
    {
        _meshGenerator = GetComponent<MeshGenerator>();
        var size = GetComponent<MeshRenderer>().bounds.size;
        Assert.IsTrue(size.x == size.z);
        _size = size.x;
    }

    void Update()
    {
        Random.InitState(_seed);

        // Matrix4x4 P = Camera.main.projectionMatrix;
        // Matrix4x4 V = Camera.main.transform.worldToLocalMatrix;
        // Matrix4x4 VP = P * V;

        matrices = new Matrix4x4[_density * _density];

        var index = 0;
        for (int y = 0; y < _density; y++)
        {
            for (int x = 0; x < _density; x++)
            {

                var centeringOffset = (float)_density / 2 - 0.5f;
                var scale = _size / _density;

                var offset = Random.insideUnitCircle * scale;
                var position = new Vector3(x - centeringOffset, 0, y - centeringOffset) * scale + transform.position + new Vector3(offset.x, 0, offset.y);

                var uv = new Vector2(x, y) / _density;
                position.y = _meshGenerator.GetMeshHeight(uv);

                var target = Camera.main.transform.position;
                var rotation = Quaternion.LookRotation(position - target, Vector3.up);

                matrices[index] = Matrix4x4.TRS(position, rotation, Vector3.one);

                index++;
            }
        }

        var rp = new RenderParams(_material);
        Graphics.RenderMeshInstanced(rp, _mesh, 0, matrices);
    }
}
