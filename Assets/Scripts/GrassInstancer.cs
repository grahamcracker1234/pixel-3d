using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
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

    GrassData[] grassData;
    GraphicsBuffer commandBuffer;
    GraphicsBuffer.IndirectDrawIndexedArgs[] commandData;
    const int commandCount = 1;

    ComputeBuffer grassBuffer;

    struct GrassData
    {
        public Matrix4x4 matrixTRS;
        public Vector2 colorTexUV;
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

    void Generate()
    {
        // Set the seed
        Random.InitState(_seed);

        // Get the size and sample count
        var size = new Vector2(_meshGenerator.size.x, _meshGenerator.size.z);
        _sampleCount = new Vector2Int((int)(_density * size.x), (int)(_density * size.y));

        // Initialize the matrices
        grassData = new GrassData[GetSampleCount()];
        grassBuffer?.Release();
        grassBuffer = new ComputeBuffer(GetSampleCount(), SizeOf<GrassData>());
        commandBuffer?.Release();
        commandBuffer = new GraphicsBuffer(GraphicsBuffer.Target.IndirectArguments, commandCount, GraphicsBuffer.IndirectDrawIndexedArgs.size);
        commandData = new GraphicsBuffer.IndirectDrawIndexedArgs[commandCount];

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
                var scale = 0.5f;
                var uv = (new Vector2(x, y) + Vector2.one / 2 + randomOffset) / _sampleCount;
                var position2D = (uv - Vector2.one / 2) * size;
                var height = _grassMesh.bounds.size.y / 2 * scale + _meshGenerator.GetMeshHeight(uv);
                var position = transform.TransformPoint(new Vector3(position2D.x, height, position2D.y));

                // Set the grass data
                grassData[index] = new GrassData
                {
                    matrixTRS = Matrix4x4.TRS(position, rotation, Vector3.one * scale),
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
        _renderParams = new RenderParams(_material)
        {
            layer = (int)Mathf.Log(_grassLayer.value, 2),
            worldBounds = new Bounds(Vector3.zero, 10000 * Vector3.one),
            matProps = block,
            receiveShadows = true,
            shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.On,
        };
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

        if (grassData == null || grassData.Length == 0)
            Generate();

        Generate(); // TODO: Remove this (add rotation angle to shader as uniform)

        // Render the grass
        // https://docs.unity3d.com/ScriptReference/Graphics.RenderMeshIndirect.html
        // CommandBuffer.SetGlobalTexture("_ShadowMapTexture", BuiltinRenderTextureType.N);
        Graphics.RenderMeshIndirect(_renderParams, _grassMesh, commandBuffer, commandCount);
    }

    void OnDisable()
    {
        commandBuffer?.Release();
        commandBuffer = null;
        grassBuffer?.Release();
        grassBuffer = null;
    }

    public int GetSampleCount()
    {
        return _sampleCount.x * _sampleCount.y;
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
    }
}