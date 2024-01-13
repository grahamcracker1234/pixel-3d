using UnityEngine;

public class ExampleClass : MonoBehaviour
{
    public Material material;
    public Mesh mesh;

    GraphicsBuffer commandBuf;
    GraphicsBuffer.IndirectDrawIndexedArgs[] commandData;
    const int commandCount = 2;

    void Start()
    {
        commandBuf = new GraphicsBuffer(GraphicsBuffer.Target.IndirectArguments, commandCount, GraphicsBuffer.IndirectDrawIndexedArgs.size);
        commandData = new GraphicsBuffer.IndirectDrawIndexedArgs[commandCount];
    }

    void OnDestroy()
    {
        commandBuf?.Release();
        commandBuf = null;
    }

    void Update()
    {
        RenderParams rp = new RenderParams(material);
        rp.worldBounds = new Bounds(Vector3.zero, 10000 * Vector3.one); // use tighter bounds for better FOV culling
        rp.matProps = new MaterialPropertyBlock();
        rp.matProps.SetMatrix("_ObjectToWorld", Matrix4x4.Translate(new Vector3(-4.5f, 0, 0)));
        commandData[0].indexCountPerInstance = mesh.GetIndexCount(0);
        commandData[0].instanceCount = 10;
        commandData[1].indexCountPerInstance = mesh.GetIndexCount(0);
        commandData[1].instanceCount = 10;
        commandBuf.SetData(commandData);
        Graphics.RenderMeshIndirect(rp, mesh, commandBuf, commandCount);
    }
}