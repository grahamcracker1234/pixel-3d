using UnityEditor;
using UnityEngine;

[RequireComponent(typeof(MeshGenerator))]
public class GrassInstancer : MonoBehaviour
{
    [SerializeField] LayerMask _grassLayer;
    [SerializeField] Mesh _grassMesh;
    [SerializeField] Material _material;
    [SerializeField] float _density = 10;
    [SerializeField] int _seed = 42;

    MeshGenerator _meshGenerator;
    RenderParams _renderParams;
    internal Vector2Int _sampleCount;

    Matrix4x4[] _matrices;

    void Setup()
    {
        _meshGenerator = GetComponent<MeshGenerator>();
        if (_meshGenerator == null)
            Debug.LogError("MeshGenerator is null");

        var meshRenderer = GetComponent<MeshRenderer>();
        if (meshRenderer == null)
            Debug.LogError("MeshRenderer is null");

        if (_material == null)
            Debug.LogError("Material is null");

        if (_grassMesh == null)
            Debug.LogError("Grass mesh is null");

        _renderParams = new RenderParams(_material)
        {
            layer = (int)Mathf.Log(_grassLayer.value, 2),
        };
    }


    void GenerateMatrices()
    {
        // Set the seed
        Random.InitState(_seed);

        // Get the size and sample count
        var size = new Vector2(_meshGenerator.size.x, _meshGenerator.size.z);
        _sampleCount = new Vector2Int((int)(_density * size.x), (int)(_density * size.y));

        // Initialize the matrices
        _matrices = new Matrix4x4[_sampleCount.x * _sampleCount.y];

        // Calculate the rotation
        var target = Camera.main.transform.position;
        var rotation = Quaternion.LookRotation(transform.position - target, Vector3.up);


        // Loop through each grass
        var index = 0;
        for (int y = 0; y < _sampleCount.y; y++)
        {
            for (int x = 0; x < _sampleCount.x; x++)
            {
                // Calculate the position and uv with random offset
                var randomOffset = Random.insideUnitCircle / 2;
                var uv = (new Vector2(x, y) + Vector2.one / 2 + randomOffset) / _sampleCount;
                var position2D = (uv - Vector2.one / 2) * size;
                var height = _grassMesh.bounds.size.y / 2 + _meshGenerator.GetMeshHeight(uv);
                var position = transform.TransformPoint(new Vector3(position2D.x, height, position2D.y));

                // Set the matrix
                _matrices[index] = Matrix4x4.TRS(position, rotation, Vector3.one);

                // Increment the index
                index++;
            }
        }
    }

    void Update()
    {
        // Validation checks
        if (_density <= 0)
            return;

        if (_meshGenerator == null)
            Setup();

        if (!_meshGenerator.IsMeshGenerated())
            _meshGenerator.GenerateTerrainMesh();

        if (transform.lossyScale != Vector3.one)
            Debug.LogWarning("GrassInstancer does not support scaling");

        if (_matrices == null || _matrices.Length == 0)
            GenerateMatrices();

        GenerateMatrices();

        // Render the grass
        Graphics.RenderMeshInstanced(_renderParams, _grassMesh, 0, _matrices);
    }
}

// Custom editor which adds a button to generate the terrain
[CustomEditor(typeof(GrassInstancer))]
public class GrassInstancerEditor : Editor
{
    public override void OnInspectorGUI()
    {
        var script = (GrassInstancer)target;
        DrawDefaultInspector();
        GUILayout.Space(10);
        GUILayout.Label("Sample Count: " + script._sampleCount.x * script._sampleCount.y);
    }
}