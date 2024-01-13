using UnityEngine;

public class CubeRenderer : MonoBehaviour
{

    public Material material;
    public Mesh mesh;

    GraphicsBuffer commandBuf;
    GraphicsBuffer.IndirectDrawIndexedArgs[] commandData;
    const int commandCount = 2;

    public int gridWidth = 1000;
    public int gridHeight = 1000;
    public float spacing = 1.0f;

    int totalInstances;

    void Start()
    {
        commandBuf = new GraphicsBuffer(GraphicsBuffer.Target.IndirectArguments, commandCount, GraphicsBuffer.IndirectDrawIndexedArgs.size);
        commandData = new GraphicsBuffer.IndirectDrawIndexedArgs[commandCount];
        totalInstances = gridWidth * gridHeight;
    }

    void Update()
    {
        material.SetInt("_GridWidth", gridWidth);
        material.SetInt("_GridHeight", gridHeight);
        material.SetFloat("_Spacing", spacing);

        var matProps = new MaterialPropertyBlock();
        matProps.SetMatrix("_ObjectToWorld", Matrix4x4.Translate(new Vector3(4.5f, 0, 0)));
        var rp = new RenderParams(material)
        {
            worldBounds = new Bounds(Vector3.zero, 10000 * Vector3.one), // use tighter bounds for better FOV culling
            matProps = matProps
        };

        commandData[0].indexCountPerInstance = mesh.GetIndexCount(0);
        commandData[0].instanceCount = (uint)totalInstances;
        commandData[1].indexCountPerInstance = mesh.GetIndexCount(0);
        commandData[1].instanceCount = (uint)totalInstances;
        commandBuf.SetData(commandData);
        Graphics.RenderMeshIndirect(rp, mesh, commandBuf, commandCount);
    }

    void OnDestroy()
    {
        commandBuf?.Release();
        commandBuf = null;
    }
}
