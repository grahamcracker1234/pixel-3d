using UnityEngine;
using UnityEngine.Assertions;

[ExecuteInEditMode]
[RequireComponent(typeof(MeshGenerator))]
public class GrassInstancer : MonoBehaviour
{
    [SerializeField] int _density = 10;
    [SerializeField] Mesh _mesh;
    [SerializeField] Material _material;
    [SerializeField] int _seed = 42;
    // public Material material;

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
        _meshGenerator = GetComponent<MeshGenerator>();
        _meshGenerator.GenerateTerrainMesh();
        Random.InitState(_seed);

        matrices = new Matrix4x4[_density * _density];

        var index = 0;
        for (int y = 0; y < _density; y++)
        {
            for (int x = 0; x < _density; x++)
            {

                var centeringOffset = (float)_density / 2 - 0.5f;
                var scale = _size / _density;

                // var offset = Random.insideUnitCircle;
                // var position = new Vector3(x - centeringOffset + offset.x, 0, y - centeringOffset + offset.y);// * scale + transform.position + new Vector3(offset.x, 0, offset.y);
                // var uv = position / _density;
                // position = position * scale + transform.position;
                var offset = Random.insideUnitCircle / 2;
                var position = new Vector3(x - centeringOffset, 0, y - centeringOffset) * scale + transform.position + new Vector3(offset.x, 0, offset.y) * scale;
                var uv = (new Vector2(x + 0.5f, y + 0.5f) + offset) / _density;

                // var sampleCount = _meshGenerator.sampleCount - Vector2.one;
                // var roundedUV = new Vector2(Mathf.Round(uv.x * sampleCount.x), Mathf.Round(uv.y * sampleCount.y)) / sampleCount;
                //Debug.Log(uv - roundedUV);
                var instancedMeshHeight = _mesh.bounds.size.y / 2;
                position.y += instancedMeshHeight;
                position.y += _meshGenerator.GetMeshHeightWorld(uv);

                var target = Camera.main.transform.position;
                var rotation = Quaternion.LookRotation(position - target, Vector3.up);

                matrices[index] = Matrix4x4.TRS(position, rotation, Vector3.one);
                // matrices[index] = Matrix4x4.TRS(position, Quaternion.identity, Vector3.one);

                index++;
            }
        }

        var rp = new RenderParams(_material)
        {
            layer = LayerMask.NameToLayer("Grass")
        };
        Graphics.RenderMeshInstanced(rp, _mesh, 0, matrices);

        // matrices = new Matrix4x4[_meshGenerator.sampleCount.x * _meshGenerator.sampleCount.y];

        // var index2 = 0;
        // foreach (var vertex in _meshGenerator.meshData.vertices)
        // {
        //     matrices[index2] = Matrix4x4.TRS(vertex, Quaternion.identity, Vector3.one * 0.1f);
        //     index2++;
        // }

        // Mesh mesh = Resources.GetBuiltinResource<Mesh>("Sphere.fbx");
        // var rp2 = new RenderParams(material);
        // Graphics.RenderMeshInstanced(rp2, mesh, 0, matrices);
    }
}
