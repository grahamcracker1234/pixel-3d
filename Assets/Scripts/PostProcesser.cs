using UnityEngine;
using UnityEngine.Rendering;

[RequireComponent(typeof(Camera))]
public class PostProcesser : MonoBehaviour
{
    [Header("Grass Overlaying Shaders")]
    public Shader grassReplacementShader;
    public Shader grassBlendingShader;

    [Header("Pixel Shader")]
    public ShaderState pixelState = ShaderState.On;
    public int screenHeight = 192;

    [Header("Outline Shader")]
    public ShaderState outlineState = ShaderState.On;
    public Color outlineColor = Color.black;
    public Color edgeColor = Color.white;
    public float depthThreshold = 0.02f;
    public float normalThreshold = 0.05f;
    public Vector3 normalEdgeBias = Vector3.one;
    public float angleThreshold = 0.5f;
    public int angleFactorScale = 7;

    public enum ShaderState
    {
        On,
        Off,
        Debug,
    }

    // [SerializeField] Settings;

    // [System.Serializable]
    // public class Settings
    // {
    //     [Header("Pixel Shader")]
    //     public ShaderState pixel = ShaderState.On;
    //     public int screenHeight = 192;

    //     [Header("Outline Shader")]
    //     public ShaderState outline = ShaderState.On;
    //     public Color outlineColor = Color.black;
    //     public Color edgeColor = Color.white;
    //     public float depthThreshold = 0.02f;
    //     public float normalThreshold = 0.05f;
    //     public Vector3 normalEdgeBias = Vector3.one;
    //     public float angleThreshold = 0.5f;
    //     public int angleFactorScale = 7;
    // }

    void Setup()
    {
        Camera.main.depthTextureMode = DepthTextureMode.DepthNormals;
    }

    // [ImageEffectOpaque]
    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        var outlineMaterial = CoreUtils.CreateEngineMaterial("Custom/PixelPerfectOutline");
        outlineMaterial.SetFloat("_DepthThreshold", depthThreshold);
        outlineMaterial.SetFloat("_AngleThreshold", angleThreshold);
        outlineMaterial.SetFloat("_AngleFactorScale", angleFactorScale);
        outlineMaterial.SetFloat("_NormalThreshold", normalThreshold);
        outlineMaterial.SetVector("_NormalEdgeBias", normalEdgeBias);
        outlineMaterial.SetInteger("_DebugOutline", outlineState == ShaderState.Debug ? 1 : 0);
        outlineMaterial.SetColor("_OutlineColor", outlineColor);
        outlineMaterial.SetColor("_EdgeColor", edgeColor);

        var pixelScreenHeight = screenHeight;
        var pixelScreenWidth = (int)(pixelScreenHeight * Camera.main.aspect + 0.5f);

        var tempTex = RenderTexture.GetTemporary(src.descriptor);
        var grassTex = RenderTexture.GetTemporary(src.descriptor);
        var screenSize = new Vector2(Screen.width, Screen.height);

        if (pixelState == ShaderState.On)
        {
            src.filterMode = FilterMode.Point;

            tempTex.Release();
            tempTex.height = pixelScreenHeight;
            tempTex.width = pixelScreenWidth;
            tempTex.filterMode = FilterMode.Point;
            tempTex.Create();

            grassTex.Release();
            grassTex.height = pixelScreenHeight;
            grassTex.width = pixelScreenWidth;
            grassTex.filterMode = FilterMode.Point;
            grassTex.Create();

            screenSize = new Vector2(pixelScreenWidth, pixelScreenHeight);
        }

        outlineMaterial.SetVector("_ScreenSize", screenSize);

        var grassCameraObject = new GameObject("GrassCamera");
        grassCameraObject.transform.SetParent(Camera.main.transform);
        var grassCamera = grassCameraObject.AddComponent<Camera>();
        grassCamera.CopyFrom(Camera.main);
        grassCamera.targetTexture = grassTex;
        grassCamera.cullingMask = -1;
        grassCamera.clearFlags = CameraClearFlags.Nothing;
        grassCamera.RenderWithShader(grassReplacementShader, "RenderType");
        Destroy(grassCameraObject);

        var grassBlendingMaterial = CoreUtils.CreateEngineMaterial("Custom/GrassBlending");
        grassBlendingMaterial.SetTexture("_GrassTex", grassTex);

        if (outlineState != ShaderState.Off)
        {
            Graphics.Blit(src, tempTex, outlineMaterial);
            Graphics.Blit(tempTex, dest, grassBlendingMaterial);
            // Graphics.Blit(tempTex, dest);
        }
        else
        {
            Graphics.Blit(src, tempTex);
            Graphics.Blit(tempTex, dest);
        }

        RenderTexture.ReleaseTemporary(tempTex);
        RenderTexture.ReleaseTemporary(grassTex);
        Graphics.SetRenderTarget(dest);
    }

    void OnEnable()
    {
        Setup();
    }
}
