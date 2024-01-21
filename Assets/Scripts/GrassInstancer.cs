using Unity.VisualScripting;
using UnityEditor;
using UnityEngine;
using UnityEngine.PlayerLoop;
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

    struct GrassChunk
    {
        public Vector2Int sampleCount;
        public GraphicsBuffer commandBuffer;
        public ComputeBuffer grassBuffer;
        public Bounds bounds;
        public Material material;
        public Vector2 uvMin;
        public Vector2 uvMax;
    }

    GrassChunk[] grassChunks;
    [SerializeField] int chunkCount = 2;
    GraphicsBuffer.IndirectDrawIndexedArgs commandArgs;


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

        ReleaseChunks();
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

    int GetChunkSampleCount(GrassChunk chunk)
    {
        var size = new Vector2(chunk.bounds.size.x, chunk.bounds.size.z);
        var sampleCount = new Vector2Int((int)(_density * size.x), (int)(_density * size.y));
        return sampleCount.x * sampleCount.y;
    }

    public void InitializeChunks()
    {
        ReleaseChunks();
        grassChunks = new GrassChunk[chunkCount * chunkCount];
        for (int y = 0; y < chunkCount; y++)
        {
            for (int x = 0; x < chunkCount; x++)
            {
                var chunkIndex = y * chunkCount + x;
                var bounds = GetChunkBounds(x, y);
                var uvMin = new Vector2(x, y) / chunkCount;
                var uvMax = uvMin + Vector2.one / chunkCount;
                var size = new Vector2(bounds.size.x, bounds.size.z);
                var sampleCount = new Vector2Int((int)(_density * size.x), (int)(_density * size.y));
                var chunk = new GrassChunk
                {
                    commandBuffer = new GraphicsBuffer(GraphicsBuffer.Target.IndirectArguments, 1, GraphicsBuffer.IndirectDrawIndexedArgs.size),
                    grassBuffer = new ComputeBuffer(sampleCount.x * sampleCount.y, SizeOf<GrassData>()),
                    bounds = bounds,
                    sampleCount = sampleCount,
                    material = _material,
                    uvMin = uvMin,
                    uvMax = uvMax,
                };
                grassChunks[chunkIndex] = chunk;
            }
        }
    }

    void ReleaseChunks()
    {
        if (grassChunks == null)
            return;

        foreach (var chunk in grassChunks)
        {
            chunk.commandBuffer?.Release();
            chunk.grassBuffer?.Release();
        }
        grassChunks = null;
    }

    void OnDrawGizmos()
    {
        if (grassChunks == null)
            return;

        foreach (var chunk in grassChunks)
        {
            Gizmos.color = Color.red;
            Gizmos.DrawWireCube(chunk.bounds.center, chunk.bounds.size);
        }
    }

    Bounds GetChunkBounds(int x, int y)
    {
        var size = new Vector2(_meshGenerator.size.x, _meshGenerator.size.z);
        var chunkSize = size / chunkCount;
        var chunkPosition = new Vector2(x, y) * chunkSize - size / 2;
        var chunkBounds = new Bounds();
        var min = new Vector3(chunkPosition.x, 0, chunkPosition.y);
        var max = new Vector3(chunkPosition.x + chunkSize.x, _meshGenerator.size.y, chunkPosition.y + chunkSize.y);
        chunkBounds.SetMinMax(
            transform.TransformPoint(min),
            transform.TransformPoint(max)
        );
        return chunkBounds;
    }

    public void GenerateChunks()
    {
        GraphicsBuffer.IndirectDrawIndexedArgs[] commandArgs = {
            new()
            {
                indexCountPerInstance = _grassMesh.GetIndexCount(0),
                instanceCount = (uint)GetSampleCount(),
                startIndex = _grassMesh.GetIndexStart(0),
                baseVertexIndex = _grassMesh.GetBaseVertex(0),
                startInstance = 0,
            }
        };

        // Set the render params
        var block = new MaterialPropertyBlock();
        block.SetTexture("_ColorTex", _meshGenerator.colorTexture);
        block.SetFloat("_MeshHeight", _grassMesh.bounds.size.y);

        _renderParams = new RenderParams(_material)
        {
            layer = (int)Mathf.Log(_grassLayer.value, 2),
            worldBounds = new Bounds(Vector3.zero, 10000 * Vector3.one),
            matProps = block,
            receiveShadows = true,
        };

        ReleaseChunks();
        grassChunks = new GrassChunk[chunkCount * chunkCount];
        for (int chunkY = 0; chunkY < chunkCount; chunkY++)
        {
            for (int chunkX = 0; chunkX < chunkCount; chunkX++)
            {
                var chunkIndex = chunkY * chunkCount + chunkX;
                var bounds = GetChunkBounds(chunkX, chunkY);
                var chunkSize = new Vector2(bounds.size.x, bounds.size.z);
                var sampleCount = new Vector2Int((int)(_density * chunkSize.x), (int)(_density * chunkSize.y));

                var chunk = new GrassChunk
                {
                    commandBuffer = new GraphicsBuffer(GraphicsBuffer.Target.IndirectArguments, 1, GraphicsBuffer.IndirectDrawIndexedArgs.size),
                    grassBuffer = new ComputeBuffer(sampleCount.x * sampleCount.y, SizeOf<GrassData>()),
                    bounds = bounds,
                    sampleCount = sampleCount,
                    material = _material,
                };

                // Set the seed
                Random.InitState(_seed);

                // Get the size and sample count
                var size = new Vector2(_meshGenerator.size.x, _meshGenerator.size.z);
                _sampleCount = new Vector2Int((int)(_density * size.x), (int)(_density * size.y));

                if (_sampleCount.x <= 0 || _sampleCount.y <= 0)
                    return;

                // Initialize the matrices
                grassData = new GrassData[GetSampleCount()];
                // grassBuffer?.Release();
                // grassBuffer = new ComputeBuffer(GetSampleCount(), SizeOf<GrassData>());
                // commandBuffer?.Release();
                // commandBuffer = new GraphicsBuffer(GraphicsBuffer.Target.IndirectArguments, commandCount, GraphicsBuffer.IndirectDrawIndexedArgs.size);
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

                chunk.commandBuffer.SetData(commandArgs);
                chunk.grassBuffer.SetData(grassData);

                // Set the render params
                _renderParams.matProps.SetBuffer("_GrassData", chunk.grassBuffer);
                UpdateRotation();

                grassChunks[chunkIndex] = chunk;

                Graphics.RenderMeshIndirect(_renderParams, _grassMesh, chunk.commandBuffer);
            }
        }
    }

    float Remap(float value, float low1, float high1, float low2, float high2)
    {
        return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
    }

    public void GenerateWithChunks()
    {
        // Set the seed
        Random.InitState(_seed);

        InitializeChunks();

        // Set the constant render params
        var block = new MaterialPropertyBlock();
        block.SetTexture("_ColorTex", _meshGenerator.colorTexture);
        block.SetFloat("_MeshHeight", _grassMesh.bounds.size.y);
        _renderParams = new RenderParams(_material)
        {
            layer = (int)Mathf.Log(_grassLayer.value, 2),
            worldBounds = new Bounds(Vector3.zero, 10000 * Vector3.one),
            matProps = block,
            receiveShadows = true,
        };
        UpdateRotation();

        // Set the buffers
        commandData = new GraphicsBuffer.IndirectDrawIndexedArgs[chunkCount * chunkCount];

        var i = 0;
        foreach (var chunk in grassChunks)
        {
            if (i == 4)
            {
                i++;
                continue;
            }
            // Get the size and sample count
            var size = new Vector2(_meshGenerator.size.x, _meshGenerator.size.z);
            var sampleCount = new Vector2Int((int)(_density * size.x), (int)(_density * size.y));

            if (chunk.sampleCount.x <= 0 || chunk.sampleCount.y <= 0)
                return;

            // Initialize the matrices
            var grassData = new GrassData[chunk.sampleCount.x * chunk.sampleCount.y];

            // Loop through each grass
            var index = 0;
            for (int y = 0; y < chunk.sampleCount.y; y++)
            {
                for (int x = 0; x < chunk.sampleCount.x; x++)
                {
                    // Calculate the position and uv with random offset
                    var randomOffset = Random.insideUnitCircle / 2;
                    var chunkUV = (new Vector2(x, y) + Vector2.one / 2 + randomOffset) / chunk.sampleCount;
                    var worldUV = new Vector2(
                        Remap(chunkUV.x, 0, 1, chunk.uvMin.x, chunk.uvMax.x),
                        Remap(chunkUV.y, 0, 1, chunk.uvMin.y, chunk.uvMax.y)
                    );
                    var position2D = (worldUV - Vector2.one / 2) * size;
                    var height = _meshGenerator.GetMeshHeight(worldUV);
                    var position = transform.TransformPoint(new Vector3(position2D.x, height, position2D.y));

                    // Set the grass data
                    grassData[index] = new GrassData
                    {
                        position = position,
                        colorTexUV = worldUV
                    };

                    // Increment the index
                    index++;
                }
            }


            chunk.grassBuffer.SetData(grassData);
            commandData = new GraphicsBuffer.IndirectDrawIndexedArgs[1];
            commandData[0] = new GraphicsBuffer.IndirectDrawIndexedArgs
            {
                indexCountPerInstance = _grassMesh.GetIndexCount(0),
                instanceCount = (uint)(chunk.sampleCount.x * chunk.sampleCount.y),
                startIndex = _grassMesh.GetIndexStart(0),
                baseVertexIndex = _grassMesh.GetBaseVertex(0),
                startInstance = 0,
            };
            chunk.commandBuffer.SetData(commandData);

            _renderParams.matProps.SetBuffer("_GrassData", chunk.grassBuffer);
            Graphics.RenderMeshIndirect(_renderParams, _grassMesh, chunk.commandBuffer);
            i++;
        }
    }

    // public void GenerateWithChunks()
    // {
    //     // Set the seed
    //     Random.InitState(_seed);

    //     InitializeChunks();

    //     commandArgs = new GraphicsBuffer.IndirectDrawIndexedArgs
    //     {
    //         indexCountPerInstance = _grassMesh.GetIndexCount(0),
    //         instanceCount = 0,
    //         startIndex = _grassMesh.GetIndexStart(0),
    //         baseVertexIndex = _grassMesh.GetBaseVertex(0),
    //         startInstance = 0,
    //     };

    //     // Set the constant render params
    //     var block = new MaterialPropertyBlock();
    //     block.SetTexture("_ColorTex", _meshGenerator.colorTexture);
    //     block.SetFloat("_MeshHeight", _grassMesh.bounds.size.y);
    //     _renderParams = new RenderParams(_material)
    //     {
    //         layer = (int)Mathf.Log(_grassLayer.value, 2),
    //         worldBounds = new Bounds(Vector3.zero, 10000 * Vector3.one),
    //         matProps = block,
    //         receiveShadows = true,
    //     };
    //     UpdateRotation();

    //     // Set the buffers
    //     commandData = new GraphicsBuffer.IndirectDrawIndexedArgs[chunkCount * chunkCount];

    //     foreach (var chunk in grassChunks)
    //     {
    //         // Get the size and sample count
    //         var size = new Vector2(_meshGenerator.size.x, _meshGenerator.size.z);
    //         var sampleCount = new Vector2Int((int)(_density * size.x), (int)(_density * size.y));

    //         if (sampleCount.x <= 0 || sampleCount.y <= 0)
    //             return;

    //         // Initialize the matrices
    //         var grassData = new GrassData[sampleCount.x * sampleCount.y];

    //         // Loop through each grass
    //         var index = 0;
    //         for (int y = 0; y < sampleCount.y; y++)
    //         {
    //             for (int x = 0; x < sampleCount.x; x++)
    //             {
    //                 // Calculate the position and uv with random offset
    //                 var randomOffset = Random.insideUnitCircle / 2;
    //                 var uv = (new Vector2(x, y) + Vector2.one / 2 + randomOffset) / sampleCount;
    //                 var position2D = (uv - Vector2.one / 2) * size;
    //                 var height = _meshGenerator.GetMeshHeight(uv);
    //                 var position = transform.TransformPoint(new Vector3(position2D.x, height, position2D.y));

    //                 // Set the grass data
    //                 grassData[index] = new GrassData
    //                 {
    //                     position = position,
    //                     colorTexUV = uv
    //                 };

    //                 // Increment the index
    //                 index++;
    //             }
    //         }

    //         chunk.grassBuffer.SetData(grassData);
    //         GraphicsBuffer.IndirectDrawIndexedArgs[] bufferArgs = { commandArgs };
    //         chunk.commandBuffer.SetData(bufferArgs);

    //         _renderParams.matProps.SetBuffer("_GrassData", chunk.grassBuffer);
    //         Graphics.RenderMeshIndirect(_renderParams, _grassMesh, chunk.commandBuffer);
    //         Debug.Log("Rendering " + sampleCount.x * sampleCount.y + " grass");
    //     }
    // }

    public void Generate()
    {
        // Set the seed
        Random.InitState(_seed);

        // Get the size and sample count
        var size = new Vector2(_meshGenerator.size.x, _meshGenerator.size.z);
        _sampleCount = new Vector2Int((int)(_density * size.x), (int)(_density * size.y));

        if (_sampleCount.x <= 0 || _sampleCount.y <= 0)
            return;

        // InitializeChunks();

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
        var rotation = Quaternion.LookRotation(transform.position - target, Vector3.up);
        // Debug.Log(new Vector4(rotation.x, rotation.y, rotation.z, rotation.w));
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

        // if (grassData == null || grassData.Length == 0)
        // GenerateWithChunks();

        // Set the rotation
        // UpdateRotation();



        // Render the grass
        // Generate();
        // UpdateRotation();
        // Graphics.RenderMeshIndirect(_renderParams, _grassMesh, commandBuffer);

        GenerateWithChunks();
        // GenerateChunks();
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
            script.GenerateWithChunks();
    }
}