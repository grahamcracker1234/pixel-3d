using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;

[RequireComponent(typeof(Camera))]
public class PostProcesser : MonoBehaviour
{
    public Shader replacementShader;
    [SerializeField] Settings _settings;

    public enum ShaderState
    {
        On,
        Off,
        Debug,
    }

    [System.Serializable]
    public class Settings
    {
        [Header("Pixel Shader")]
        public ShaderState pixel = ShaderState.On;
        public int screenHeight = 192;

        [Header("Outline Shader")]
        public ShaderState outline = ShaderState.On;
        public Color outlineColor = Color.black;
        public Color edgeColor = Color.white;
        public float depthThreshold = 0.02f;
        public float normalThreshold = 0.05f;
        public Vector3 normalEdgeBias = Vector3.one;
        public float angleThreshold = 0.5f;
        public int angleFactorScale = 7;
    }

    // void OnRenderImage(RenderTexture src, RenderTexture dest)
    // {
    //     var outline = CoreUtils.CreateEngineMaterial("Custom/PixelPerfectOutline");
    //     outline.SetFloat("_DepthThreshold", _settings.depthThreshold);
    //     outline.SetFloat("_AngleThreshold", _settings.angleThreshold);
    //     outline.SetFloat("_AngleFactorScale", _settings.angleFactorScale);
    //     outline.SetFloat("_NormalThreshold", _settings.normalThreshold);
    //     outline.SetVector("_NormalEdgeBias", _settings.normalEdgeBias);
    //     outline.SetInteger("_DebugOutline", _settings.outline == ShaderState.Debug ? 1 : 0);
    //     outline.SetColor("_OutlineColor", _settings.outlineColor);
    //     outline.SetColor("_EdgeColor", _settings.edgeColor);

    //     var pixelScreenHeight = _settings.screenHeight;
    //     var pixelScreenWidth = (int)(pixelScreenHeight * Camera.main.aspect + 0.5f);

    //     var temp = RenderTexture.GetTemporary(src.descriptor);
    //     var screenSize = new Vector2(Screen.width, Screen.height);

    //     if (_settings.pixel == ShaderState.On)
    //     {
    //         temp.Release();
    //         temp.height = pixelScreenHeight;
    //         temp.width = pixelScreenWidth;
    //         temp.filterMode = FilterMode.Point;
    //         src.filterMode = FilterMode.Point;
    //         temp.Create();

    //         screenSize = new Vector2(pixelScreenWidth, pixelScreenHeight);
    //     }

    //     outline.SetVector("_ScreenSize", screenSize);

    //     if (_settings.outline != ShaderState.Off)
    //     {
    //         Graphics.Blit(src, temp, outline);
    //         Graphics.Blit(temp, dest);
    //     }
    //     else
    //     {
    //         Graphics.Blit(src, temp);
    //         Graphics.Blit(temp, dest);
    //     }


    //     RenderTexture.ReleaseTemporary(temp);
    // }

    void OnEnable()
    {
        var camera = GetComponent<Camera>();
        camera.depthTextureMode = DepthTextureMode.DepthNormals;
        if (replacementShader == null) return;

        camera.SetReplacementShader(replacementShader, "RenderType");
    }

    void OnDisable()
    {
        var camera = GetComponent<Camera>();
        camera.ResetReplacementShader();
    }
}
