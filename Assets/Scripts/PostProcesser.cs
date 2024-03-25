using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;

[RequireComponent(typeof(Camera))]
public class PostProcesser : MonoBehaviour
{
    [Header("Grass Overlaying Shaders")]
    public LayerMask grassLayer;
    public ShaderState grassState = ShaderState.On;
    public Shader grassReplacementShader;
    public Shader grassBlendingShader;
    public float alphaThreshold = 0.5f;

    [Header("Pixel Shader")]
    public ShaderState pixelState = ShaderState.On;
    public bool dynamicPixelSize = false;
    public int screenHeight = 192;
    public float pixelsPerUnit = 24f;
    [Range(1f / 32f, 1)] public float zoom = 0.125f;

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

    void OnEnable()
    {
        Camera.main.depthTextureMode = DepthTextureMode.DepthNormals;
        if (grassState != ShaderState.Debug)
            Camera.main.cullingMask = ~(1 << (int)Mathf.Log(grassLayer.value, 2));
    }

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

        var grassBlendingMaterial = CoreUtils.CreateEngineMaterial("Custom/GrassBlending");
        grassBlendingMaterial.SetFloat("_AlphaThreshold", alphaThreshold);

        Camera.main.orthographicSize = 1 / zoom;
        var farPlane = 10 / zoom;
        var pos = Camera.main.transform.localPosition;
        pos.z = -farPlane / 2;
        Camera.main.transform.SetLocalPositionAndRotation(pos, Quaternion.identity);
        Camera.main.farClipPlane = farPlane;

        if (dynamicPixelSize)
        {
            screenHeight = (int)(Screen.height * zoom);
            screenHeight = screenHeight - (screenHeight % 2);
        }

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
        else
        {
            src.filterMode = FilterMode.Bilinear;

            tempTex.filterMode = FilterMode.Bilinear;
            tempTex.Release();
            tempTex.Create();

            grassTex.filterMode = FilterMode.Bilinear;
            grassTex.Release();
            grassTex.Create();
        }

        outlineMaterial.SetVector("_ScreenSize", screenSize);

        if (grassState == ShaderState.On && outlineState != ShaderState.Debug)
        {
            var grassCameraObject = new GameObject("GrassCamera");
            grassCameraObject.transform.SetParent(Camera.main.transform);

            var grassCamera = grassCameraObject.AddComponent<Camera>();
            grassCamera.CopyFrom(Camera.main);
            grassCamera.targetTexture = grassTex;
            grassCamera.cullingMask = -1;
            grassCamera.clearFlags = CameraClearFlags.Nothing;
            grassCamera.RenderWithShader(grassReplacementShader, "RenderType");

            Destroy(grassCameraObject);
            grassBlendingMaterial.SetTexture("_GrassTex", grassTex);
        }

        if (outlineState != ShaderState.Off)
        {
            Graphics.Blit(src, tempTex, outlineMaterial);
            if (grassState == ShaderState.On && outlineState != ShaderState.Debug)
                Graphics.Blit(tempTex, dest, grassBlendingMaterial);
            else
                Graphics.Blit(tempTex, dest);
        }
        else if (grassState == ShaderState.On)
        {
            Graphics.Blit(src, tempTex, grassBlendingMaterial);
            Graphics.Blit(tempTex, dest);
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
}
