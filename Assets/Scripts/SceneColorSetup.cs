/*
Copies the camera buffer after rendering opaques, to _CameraOpaqueTexture property so the Scene Color node can work in the Built-in RP.
Attach this script to the Main Camera (and any other cameras you want an Opaque Texture for)
Will also work for Scene Views (Though if a new window is opened will need to enter & exit play mode)
Tested in 2022.2
@Cyanilux
*/

using UnityEngine;
using UnityEngine.Rendering;

[ExecuteAlways]
public class SceneColorSetup : MonoBehaviour
{

    private Camera cam;
    private CommandBuffer cmd, cmd2;

    void OnEnable()
    {
        cam = GetComponent<Camera>();
        int rtID = Shader.PropertyToID("_CameraOpaqueTexture");
        if (cmd == null)
        {
            cmd = new CommandBuffer
            {
                name = "Setup Opaque Texture"
            };
            cmd.GetTemporaryRT(rtID, cam.pixelWidth, cam.pixelHeight, 0);
            // cmd.Blit(null, rtID);
        }
        if (cmd2 == null)
        {
            cmd2 = new CommandBuffer
            {
                name = "Release Opaque Texture"
            };
            cmd2.ReleaseTemporaryRT(rtID);
        }

        // Game View (camera script is assigned on)
        cam.AddCommandBuffer(CameraEvent.AfterForwardOpaque, cmd);
        cam.AddCommandBuffer(CameraEvent.AfterEverything, cmd2);

        // Scene View
#if UNITY_EDITOR
        if (cam.tag == "MainCamera")
        {
            Camera[] sceneCameras = UnityEditor.SceneView.GetAllSceneCameras();
            foreach (Camera c in sceneCameras)
            {
                c.AddCommandBuffer(CameraEvent.AfterForwardOpaque, cmd);
                c.AddCommandBuffer(CameraEvent.AfterEverything, cmd2);
            }
        }
#endif
    }

    void OnDisable()
    {
        // Game View (camera script is assigned on)
        cam.RemoveCommandBuffer(CameraEvent.AfterForwardOpaque, cmd);
        cam.RemoveCommandBuffer(CameraEvent.AfterEverything, cmd2);

        // Scene View
#if UNITY_EDITOR
        if (cam.tag == "MainCamera")
        {
            Camera[] sceneCameras = UnityEditor.SceneView.GetAllSceneCameras();
            foreach (Camera c in sceneCameras)
            {
                c.RemoveCommandBuffer(CameraEvent.AfterForwardOpaque, cmd);
                c.RemoveCommandBuffer(CameraEvent.AfterEverything, cmd2);
            }
        }
#endif
    }
}