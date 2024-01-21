using UnityEditor;
using UnityEngine;
using static System.Runtime.InteropServices.Marshal;

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
    Vector2Int _sampleCount;

    GraphicsBuffer commandBuffer;
    GraphicsBuffer.IndirectDrawIndexedArgs[] commandData;
    GrassData[] grassData;
    ComputeBuffer grassBuffer;

    const int commandCount = 1;


    struct GrassData
    {
        public Vector3 position;
        public Vector2 colorTexUV;
    }

    void OnEnable()
    {
        Setup();
    }

    void OnDisable()
    {
        commandBuffer?.Release();
        commandBuffer = null;
        grassBuffer?.Release();
        grassBuffer = null;
    }

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
    }

    public int GetSampleCount()
    {
        return _sampleCount.x * _sampleCount.y;
    }

    public void Generate()
    {
        // Set the seed
        Random.InitState(_seed);

        // Get the size and sample count
        var size = new Vector2(_meshGenerator.size.x, _meshGenerator.size.z);
        _sampleCount = new Vector2Int((int)(_density * size.x), (int)(_density * size.y));

        if (_sampleCount.x <= 0 || _sampleCount.y <= 0)
            return;

        // Initialize the matrices
        grassData = new GrassData[GetSampleCount()];
        grassBuffer?.Release();
        grassBuffer = new ComputeBuffer(GetSampleCount(), SizeOf<GrassData>());
        commandBuffer?.Release();
        commandBuffer = new GraphicsBuffer(GraphicsBuffer.Target.IndirectArguments, commandCount, GraphicsBuffer.IndirectDrawIndexedArgs.size);
        commandData = new GraphicsBuffer.IndirectDrawIndexedArgs[commandCount];

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
                var height = _meshGenerator.GetMeshHeight(uv);
                var position = transform.TransformPoint(new Vector3(position2D.x, height, position2D.y));

                // Set the grass data
                grassData[index] = new GrassData
                {
                    position = position,
                    colorTexUV = uv
                };

                // Increment the index
                index++;
            }
        }

        // Set the buffers
        var indirectDrawIndexedArgs = new GraphicsBuffer.IndirectDrawIndexedArgs
        {
            indexCountPerInstance = _grassMesh.GetIndexCount(0),
            instanceCount = (uint)GetSampleCount(),
            startIndex = _grassMesh.GetIndexStart(0),
            baseVertexIndex = _grassMesh.GetBaseVertex(0),
            startInstance = 0,
        };
        for (int i = 0; i < commandCount; i++)
            commandData[i] = indirectDrawIndexedArgs;
        commandBuffer.SetData(commandData);
        grassBuffer.SetData(grassData);

        // Set the render params
        var block = new MaterialPropertyBlock();
        block.SetTexture("_ColorTex", _meshGenerator.colorTexture);
        block.SetBuffer("_GrassData", grassBuffer);
        block.SetFloat("_MeshHeight", _grassMesh.bounds.size.y);

        _renderParams = new RenderParams(_material)
        {
            layer = (int)Mathf.Log(_grassLayer.value, 2),
            worldBounds = new Bounds(Vector3.zero, 10000 * Vector3.one),
            matProps = block,
            receiveShadows = true,
        };

        UpdateRotation();
    }

    void UpdateRotation()
    {
        var target = Camera.main.transform.position;
        // var rotation = Quaternion.identity;
        var rotation = Quaternion.LookRotation(transform.position - target, Vector3.up);
        Debug.Log(new Vector4(rotation.x, rotation.y, rotation.z, rotation.w));
        _renderParams.matProps.SetVector("_Rotation", new Vector4(rotation.x, rotation.y, rotation.z, rotation.w));
    }

    void Update()
    {
        // Validation checks
        if (_meshGenerator == null)
            Setup();

        if (!_meshGenerator.IsMeshGenerated())
            _meshGenerator.GenerateTerrainMesh();

        if (transform.lossyScale != Vector3.one)
            Debug.LogWarning("GrassInstancer does not support scaling");

        if (grassData == null || grassData.Length == 0)
            Generate();

        // Set the rotation
        UpdateRotation();

        // Render the grass
        Graphics.RenderMeshIndirect(_renderParams, _grassMesh, commandBuffer, commandCount);
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
        GUILayout.Label("Sample Count: " + script.GetSampleCount());
        if (GUILayout.Button("Generate Grass"))
            script.Generate();
    }
}