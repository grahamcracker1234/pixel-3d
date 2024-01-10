using UnityEngine;
using UnityEngine.Rendering;

[RequireComponent(typeof(Camera))]
public class PostProcessing : MonoBehaviour
{
    Camera _mainCamera;

    Camera _normalCamera;

    [SerializeField] Settings _settings;

    [System.Serializable]
    public class Settings
    {
        public int screenHeight = 192;
        public float depthThreshold = 0.02f;
        public float normalThreshold = 0.05f;
        public Vector3 normalEdgeBias = Vector3.one;
        public float angleThreshold = 0.5f;
        public int angleFactorScale = 7;
        // [Range(0, 1)] public float depthNormalThreshold = 0.5f;
        // [Range(1, 100)] public float depthNormalThresholdScale = 7;

        public bool pixel = true;
        public bool outline = true;
        public bool debugOutline = false;
    }

    void ProcessingSetup()
    {
        // Get the main camera
        _mainCamera = GetComponent<Camera>();
        _mainCamera.depthTextureMode = DepthTextureMode.DepthNormals;

        // // Create the camera for the render texture
        // var normalCameraObject = new GameObject("PostCamera");
        // normalCameraObject.transform.parent = transform;
        // _normalCamera = normalCameraObject.AddComponent<Camera>();
        // _normalCamera.CopyFrom(_mainCamera);
        // _normalCamera.SetReplacementShader(Shader.Find("Custom/Normal"), "");
        // // _normalCamera.enabled = false;

        // // Create a canvas as the child of the render camera
        // var canvas = new GameObject("Canvas");
        // canvas.transform.parent = transform;
        // canvas.transform.SetLocalPositionAndRotation(Vector3.zero, Quaternion.identity);
        // var canvasComponent = canvas.AddComponent<Canvas>();
        // canvasComponent.renderMode = RenderMode.ScreenSpaceOverlay;
        // canvasComponent.vertexColorAlwaysGammaSpace = true;
        // canvas.AddComponent<UnityEngine.UI.CanvasScaler>();
        // canvas.AddComponent<UnityEngine.UI.GraphicRaycaster>();

        // // Create a RawImage as the child of the canvas
        // var rawImage = new GameObject("RawImage");
        // rawImage.transform.parent = canvas.transform;
        // rawImage.transform.SetLocalPositionAndRotation(Vector3.zero, Quaternion.identity);
        // var rawImageComponent = rawImage.AddComponent<UnityEngine.UI.RawImage>();
        // rawImageComponent.texture = _preCameraTexture;
        // rawImageComponent.SetNativeSize();
    }

    // void OnRenderImage(RenderTexture src, RenderTexture dest)
    // {
    //     // var outline = CoreUtils.CreateEngineMaterial("Custom/Outline");
    //     // outline.SetFloat("_OutlineWidth", _settings.outlineScale);

    //     // var outline = CoreUtils.CreateEngineMaterial("Custom/ImprovedOutline");
    //     // outline.SetInt("_ConvolutionScale", _settings.outlineScale);
    //     // outline.SetFloat("_DepthThreshold", _settings.depthThreshold);
    //     // outline.SetFloat("_NormalThreshold", _settings.normalThreshold);
    //     // var viewDir = _mainCamera.transform.rotation.eulerAngles / 360;
    //     // outline.SetVector("_ViewDir", viewDir);
    //     // outline.SetFloat("_DepthNormalThreshold", _settings.depthNormalThreshold);
    //     // outline.SetFloat("_DepthNormalThresholdScale", _settings.depthNormalThresholdScale);

    //     // var outline = CoreUtils.CreateEngineMaterial("Custom/NewImprovedOutline");
    //     // outline.SetInt("_ConvolutionScale", _settings.outlineScale);
    //     // outline.SetFloat("_DepthThreshold", _settings.depthThreshold);
    //     // outline.SetFloat("_NormalThreshold", _settings.normalThreshold);
    //     // var viewDir = _mainCamera.transform.rotation.eulerAngles / 360;
    //     // outline.SetVector("_ViewDir", viewDir);
    //     // outline.SetFloat("_DepthNormalThreshold", _settings.depthNormalThreshold);
    //     // outline.SetFloat("_DepthNormalThresholdScale", _settings.depthNormalThresholdScale);

    //     var outline = CoreUtils.CreateEngineMaterial("Custom/AltOutline");
    //     outline.SetInt("_ConvolutionScale", _settings.outlineScale);
    //     outline.SetFloat("_DepthThreshold", _settings.depthThreshold);
    //     outline.SetFloat("_NormalThreshold", _settings.normalThreshold);
    //     var viewDir = _mainCamera.transform.rotation.eulerAngles / 360;
    //     outline.SetVector("_ViewDir", viewDir);
    //     outline.SetFloat("_DepthNormalThreshold", _settings.depthNormalThreshold);
    //     outline.SetFloat("_DepthNormalThresholdScale", _settings.depthNormalThresholdScale);

    //     var pixel = CoreUtils.CreateEngineMaterial("Custom/Pixel");
    //     var pixelScreenHeight = _settings.screenHeight;
    //     var pixelScreenWidth = (int)(pixelScreenHeight * _mainCamera.aspect + 0.5f);
    //     pixel.SetVector("_BlockCount", new Vector2(pixelScreenWidth, pixelScreenHeight));

    //     // var normalTex = GetTexture(_normalCamera);
    //     // material.SetTexture("_NormalTex", normalTex);

    //     var temp = RenderTexture.GetTemporary(src.descriptor);
    //     temp.filterMode = FilterMode.Point;

    //     if (_settings.outline) Graphics.Blit(src, temp, outline);
    //     else Graphics.Blit(src, temp);

    //     if (_settings.pixel) Graphics.Blit(temp, dest, pixel);
    //     else Graphics.Blit(temp, dest);

    //     RenderTexture.ReleaseTemporary(temp);
    // }

    // void OnRenderImage(RenderTexture src, RenderTexture dest)
    // {

    //     var outline = CoreUtils.CreateEngineMaterial("Custom/AltOutline");
    //     outline.SetFloat("_DepthThreshold", _settings.depthThreshold);
    //     outline.SetFloat("_NormalThreshold", _settings.normalThreshold);
    //     outline.SetFloat("_DepthNormalThreshold", _settings.depthNormalThreshold);
    //     outline.SetFloat("_DepthNormalThresholdScale", _settings.depthNormalThresholdScale);

    //     var erosionDepth = RenderTexture.GetTemporary(src.descriptor);
    //     erosionDepth.filterMode = FilterMode.Point;

    //     if (_settings.outline)
    //     {
    //         Graphics.Blit(src, erosionDepth, outline, 0);
    //         outline.SetTexture("_ErosionDepthTexture", erosionDepth);
    //         Graphics.Blit(src, dest, outline, 1);
    //     }
    //     else
    //     {
    //         Graphics.Blit(src, dest);
    //     }


    //     RenderTexture.ReleaseTemporary(erosionDepth);
    // }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {

        var outline = CoreUtils.CreateEngineMaterial("Custom/PixelPerfectOutline");
        outline.SetFloat("_DepthThreshold", _settings.depthThreshold);
        outline.SetFloat("_AngleThreshold", _settings.angleThreshold);
        outline.SetFloat("_AngleFactorScale", _settings.angleFactorScale);
        outline.SetFloat("_NormalThreshold", _settings.normalThreshold);
        outline.SetVector("_NormalEdgeBias", _settings.normalEdgeBias);
        outline.SetInteger("_DebugOutline", _settings.debugOutline ? 1 : 0);

        var pixelScreenHeight = _settings.screenHeight;
        var pixelScreenWidth = (int)(pixelScreenHeight * _mainCamera.aspect + 0.5f);

        var temp = RenderTexture.GetTemporary(src.descriptor);

        if (_settings.pixel)
        {
            temp.Release();
            temp.height = pixelScreenHeight;
            temp.width = pixelScreenWidth;
            temp.filterMode = FilterMode.Point;
            src.filterMode = FilterMode.Point;
            temp.Create();

            outline.SetVector("_ScreenSize", new Vector2(pixelScreenWidth, pixelScreenHeight));
        }
        else
        {
            outline.SetVector("_ScreenSize", new Vector2(Screen.width, Screen.height));
        }

        if (_settings.outline)
        {
            Graphics.Blit(src, temp, outline);
            Graphics.Blit(temp, dest);
        }
        else
        {
            Graphics.Blit(src, temp);
            Graphics.Blit(temp, dest);
        }


        RenderTexture.ReleaseTemporary(temp);
    }

    Texture2D GetTexture(Camera camera)
    {
        var rt = new RenderTexture(Screen.width, Screen.height, 24);

        camera.targetTexture = rt;
        Texture2D tex = new Texture2D(rt.width, rt.height);

        // camera.enabled = true;
        camera.Render();

        RenderTexture.active = rt;
        tex.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0);

        camera.targetTexture = null;
        RenderTexture.active = null;
        // camera.enabled = false;

        return tex;
    }

    void Awake()
    {
        if (enabled) ProcessingSetup();
    }

    void OnDisable()
    {
        // Destroy all children
        foreach (Transform child in transform)
        {
            Destroy(child.gameObject);
        }
    }
}
