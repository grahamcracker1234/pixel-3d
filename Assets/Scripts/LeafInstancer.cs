using UnityEditor;
using UnityEngine;
using static System.Runtime.InteropServices.Marshal;

[RequireComponent(typeof(MeshSurfaceSampler))]
public class LeafInstancer : MonoBehaviour
{
    [SerializeField] LayerMask _grassLayer;
    [SerializeField] Mesh _leafMesh;
    [SerializeField] Material _material;

    MeshSurfaceSampler _meshSurfaceSampler;
    RenderParams _renderParams;

    GraphicsBuffer commandBuffer;
    GraphicsBuffer.IndirectDrawIndexedArgs[] commandData;
    LeafData[] leafData;
    ComputeBuffer leafBuffer;

    const int commandCount = 1;

    struct LeafData
    {
        public Vector3 position;
        public Vector3 normal;
    }

    void OnEnable()
    {
        Setup();
    }

    void OnDisable()
    {
        commandBuffer?.Release();
        commandBuffer = null;
        leafBuffer?.Release();
        leafBuffer = null;
    }

    void Setup()
    {
        _meshSurfaceSampler = GetComponent<MeshSurfaceSampler>();
        if (_meshSurfaceSampler == null)
            Debug.LogError("MeshGenerator is null");

        var meshRenderer = GetComponent<MeshRenderer>();
        if (meshRenderer == null)
            Debug.LogError("MeshRenderer is null");

        if (_material == null)
            Debug.LogError("Material is null");

        if (_leafMesh == null)
            Debug.LogError("Grass mesh is null");
    }

    // public void Generate()
    // {
    //     // Set the seed
    //     Random.InitState(_seed);

    //     // Get the size and sample count
    //     var size = new Vector2(_meshSurfaceSampler.size.x, _meshSurfaceSampler.size.z);
    //     _sampleCount = new Vector2Int((int)(_density * size.x), (int)(_density * size.y));

    //     if (_sampleCount.x <= 0 || _sampleCount.y <= 0)
    //         return;

    //     // Initialize the matrices
    //     grassData = new GrassData[GetSampleCount()];
    //     grassBuffer?.Release();
    //     grassBuffer = new ComputeBuffer(GetSampleCount(), SizeOf<GrassData>());
    //     commandBuffer?.Release();
    //     commandBuffer = new GraphicsBuffer(GraphicsBuffer.Target.IndirectArguments, commandCount, GraphicsBuffer.IndirectDrawIndexedArgs.size);
    //     commandData = new GraphicsBuffer.IndirectDrawIndexedArgs[commandCount];

    //     // Loop through each grass
    //     var index = 0;
    //     for (int y = 0; y < _sampleCount.y; y++)
    //     {
    //         for (int x = 0; x < _sampleCount.x; x++)
    //         {
    //             // Calculate the position and uv with random offset
    //             var randomOffset = Random.insideUnitCircle / 2;
    //             var uv = (new Vector2(x, y) + Vector2.one / 2 + randomOffset) / _sampleCount;
    //             var position2D = (uv - Vector2.one / 2) * size;
    //             var height = _meshSurfaceSampler.GetMeshHeight(uv);
    //             var position = transform.TransformPoint(new Vector3(position2D.x, height, position2D.y));

    //             // Set the grass data
    //             grassData[index] = new GrassData
    //             {
    //                 position = position,
    //                 colorTexUV = uv
    //             };

    //             // Increment the index
    //             index++;
    //         }
    //     }

    //     // Set the buffers
    //     var indirectDrawIndexedArgs = new GraphicsBuffer.IndirectDrawIndexedArgs
    //     {
    //         indexCountPerInstance = _grassMesh.GetIndexCount(0),
    //         instanceCount = (uint)GetSampleCount(),
    //         startIndex = _grassMesh.GetIndexStart(0),
    //         baseVertexIndex = _grassMesh.GetBaseVertex(0),
    //         startInstance = 0,
    //     };
    //     for (int i = 0; i < commandCount; i++)
    //         commandData[i] = indirectDrawIndexedArgs;
    //     commandBuffer.SetData(commandData);
    //     grassBuffer.SetData(grassData);

    //     // Set the render params
    //     var block = new MaterialPropertyBlock();
    //     block.SetTexture("_ColorTex", _meshSurfaceSampler.colorTexture);
    //     block.SetBuffer("_GrassData", grassBuffer);
    //     block.SetFloat("_MeshHeight", _grassMesh.bounds.size.y);

    //     _renderParams = new RenderParams(_material)
    //     {
    //         layer = (int)Mathf.Log(_grassLayer.value, 2),
    //         worldBounds = new Bounds(Vector3.zero, 10000 * Vector3.one),
    //         matProps = block,
    //         receiveShadows = true,
    //     };

    //     UpdateRotation();
    // }

    public void Generate()
    {
        var count = _meshSurfaceSampler.points.Length;

        leafData = new LeafData[count];
        leafBuffer?.Release();
        leafBuffer = new ComputeBuffer(count, SizeOf<LeafData>());
        commandBuffer?.Release();
        commandBuffer = new GraphicsBuffer(GraphicsBuffer.Target.IndirectArguments, commandCount, GraphicsBuffer.IndirectDrawIndexedArgs.size);
        commandData = new GraphicsBuffer.IndirectDrawIndexedArgs[commandCount];

        for (int i = 0; i < count; i++)
        {
            leafData[i] = new LeafData
            {
                position = _meshSurfaceSampler.points[i],
                normal = _meshSurfaceSampler.normals[i]
            };
        }

        // Set the buffers
        var indirectDrawIndexedArgs = new GraphicsBuffer.IndirectDrawIndexedArgs
        {
            indexCountPerInstance = _leafMesh.GetIndexCount(0),
            instanceCount = (uint)count,
            startIndex = _leafMesh.GetIndexStart(0),
            baseVertexIndex = _leafMesh.GetBaseVertex(0),
            startInstance = 0,
        };
        for (int i = 0; i < commandCount; i++)
            commandData[i] = indirectDrawIndexedArgs;

        commandBuffer.SetData(commandData);
        leafBuffer.SetData(leafData);

        // Set the render params
        var block = new MaterialPropertyBlock();
        block.SetBuffer("_LeafData", leafBuffer);

        _renderParams = new RenderParams(_material)
        {
            // layer = (int)Mathf.Log(_grassLayer.value, 2),
            worldBounds = new Bounds(Vector3.zero, 10000 * Vector3.one),
            matProps = block,
            receiveShadows = true,
        };

        UpdateRotation();
    }

    // Update the rotation of the grass
    void UpdateRotation()
    {
        var target = Camera.main.transform.position;
        var rotation = Quaternion.LookRotation(transform.position - target, Vector3.up);
        var quaternion = new Vector4(rotation.x, rotation.y, rotation.z, rotation.w);
        _renderParams.matProps.SetVector("_Rotation", quaternion);
    }

    void Update()
    {
        // Validation checks
        if (_meshSurfaceSampler == null)
            Setup();

        if (!_meshSurfaceSampler.ArePointsGenerated())
            _meshSurfaceSampler.GeneratePoints();

        // if (transform.lossyScale != Vector3.one)
        // Debug.LogWarning("GrassInstancer does not support scaling");

        if (leafData == null || leafData.Length == 0)
            Generate();

        UpdateRotation();

        // Render the grass
        Graphics.RenderMeshIndirect(_renderParams, _leafMesh, commandBuffer, commandCount);
    }
}

// Custom editor which adds a button to generate the terrain
[CustomEditor(typeof(LeafInstancer))]
public class LeafInstancerEditor : Editor
{
    public override void OnInspectorGUI()
    {
        var script = (LeafInstancer)target;
        DrawDefaultInspector();
        GUILayout.Space(10);
        if (GUILayout.Button("Generate Leaves"))
            script.Generate();
    }
}