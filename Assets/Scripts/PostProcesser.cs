using System.Collections.Generic;
// using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.SceneManagement;

[RequireComponent(typeof(Camera))]
public class PostProcesser : MonoBehaviour
{
    [Header("Grass Overlaying Shaders")]
    public Light mainLight;
    CommandBuffer lightCommand;
    public LayerMask grassLayer;
    public ShaderState grassState = ShaderState.On;
    public Shader grassReplacementShader;
    public Shader grassBlendingShader;
    public float alphaThreshold = 0.5f;

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

    void OnEnable()
    {
        Camera.main.depthTextureMode = DepthTextureMode.DepthNormals;
        if (grassState != ShaderState.Debug)
            Camera.main.cullingMask = ~(1 << (int)Mathf.Log(grassLayer.value, 2));

        // lightCommand = new CommandBuffer();
        // lightCommand.SetGlobalTexture("_MainShadowMapTexture", BuiltinRenderTextureType.CurrentActive);
        // mainLight.AddCommandBuffer(LightEvent.AfterShadowMap, lightCommand);
    }

    void OnDisable()
    {
        // lightCommand?.Dispose();
    }

    public static IEnumerable<T> GetAllComponentsOfType<T>()
        where T : Component
    {
        GameObject[] rootObjs = SceneManager.GetActiveScene().GetRootGameObjects();
        foreach (GameObject obj in rootObjs)
        {
            foreach (T child in obj.GetComponentsInChildren<T>(true))
                yield return child;
        }
    }

    // void OnPreCell()
    // {
    //     // CameraEvent.BeforeImageEffectsOpaque
    //     var commandBuffer = new CommandBuffer();
    //     commandBuffer.SetGlobalTexture("_ShadowMapTexture", BuiltinRenderTextureType.CurrentActive);
    //     Camera.main.AddCommandBuffer(CameraEvent.BeforeImageEffectsOpaque, commandBuffer);
    // }

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

        var grassBlendingMaterial = CoreUtils.CreateEngineMaterial("Custom/GrassBlending");
        grassBlendingMaterial.SetFloat("_AlphaThreshold", alphaThreshold);

        var pixelScreenHeight = screenHeight;
        var pixelScreenWidth = (int)(pixelScreenHeight * Camera.main.aspect + 0.5f);

        // var pixelMaterial = CoreUtils.CreateEngineMaterial("Custom/Pixel");
        // pixelMaterial.SetVector("_BlockCount", new Vector2(pixelScreenWidth, pixelScreenHeight));

        var tempTex = RenderTexture.GetTemporary(src.descriptor);
        // var pixelTex = RenderTexture.GetTemporary(src.descriptor);
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

            // pixelTex.Release();
            // pixelTex.height = pixelScreenHeight;
            // pixelTex.width = pixelScreenWidth;
            // pixelTex.filterMode = FilterMode.Point;
            // pixelTex.Create();

            screenSize = new Vector2(pixelScreenWidth, pixelScreenHeight);
        }
        else
        {
            src.filterMode = FilterMode.Bilinear;
            tempTex.filterMode = FilterMode.Bilinear;
            grassTex.filterMode = FilterMode.Bilinear;
            // pixelTex.filterMode = FilterMode.Bilinear;

            tempTex.Release();
            tempTex.Create();

            grassTex.Release();
            grassTex.Create();

            // pixelTex.Release();
            // pixelTex.Create();
        }

        outlineMaterial.SetVector("_ScreenSize", screenSize);

        // Graphics.Blit(src, pixelTex, pixelMaterial);
        // Graphics.Blit(pixelTex, src);

        if (grassState == ShaderState.On)
        {
            var grassCameraObject = new GameObject("GrassCamera");
            grassCameraObject.transform.SetParent(Camera.main.transform);
            var grassCamera = grassCameraObject.AddComponent<Camera>();
            grassCamera.CopyFrom(Camera.main);
            grassCamera.targetTexture = grassTex;
            grassCamera.cullingMask = -1;
            grassCamera.clearFlags = CameraClearFlags.Nothing;


            // var renderers = GetAllComponentsOfType<MeshRenderer>().ToList();
            // renderers.ForEach(r => Debug.Log(r.shadowCastingMode));
            // var shadowCastingModes = renderers.Select(r => r.shadowCastingMode);
            // renderers.ForEach(r => r.shadowCastingMode = ShadowCastingMode.ShadowsOnly);
            // grassCamera.Render();
            grassCamera.RenderWithShader(grassReplacementShader, "RenderType");
            // renderers.Zip(shadowCastingModes, (r, scm) => r.shadowCastingMode = scm);
            Destroy(grassCameraObject);

            grassBlendingMaterial.SetTexture("_GrassTex", grassTex);
        }

        if (outlineState != ShaderState.Off)
        {
            Graphics.Blit(src, tempTex, outlineMaterial);
            if (grassState == ShaderState.On)
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
        // RenderTexture.ReleaseTemporary(pixelTex);
        Graphics.SetRenderTarget(dest);
    }
}
