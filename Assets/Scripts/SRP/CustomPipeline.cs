using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace Pixel3d
{
    public class CustomPipeline : RenderPipeline
    {
        CameraRenderer renderer = new();

        public CustomPipeline()
        {
            GraphicsSettings.useScriptableRenderPipelineBatching = true;
        }

        bool useDynamicBatching, useGPUInstancing;

        ShadowSettings shadowSettings;

        public CustomPipeline(bool useDynamicBatching, bool useGPUInstancing, bool useSRPBatcher, ShadowSettings shadowSettings)
        {
            this.shadowSettings = shadowSettings;
            this.useDynamicBatching = useDynamicBatching;
            this.useGPUInstancing = useGPUInstancing;
            GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatcher;
            GraphicsSettings.lightsUseLinearIntensity = true;
        }
        // {
        //     this.dynamicBatching = dynamicBatching;
        //     this.instancing = instancing;
        //     GraphicsSettings.lightsUseLinearIntensity = true;
        // }

        // Only needed for abstract class RenderPipeline, Unity 2022+ uses Render with List<Camera>
        protected override void Render(ScriptableRenderContext renderContext, Camera[] cameras) { }
        protected override void Render(ScriptableRenderContext renderContext, List<Camera> cameras)
        {
            foreach (var camera in cameras)
            {
                renderer.Render(renderContext, camera, useDynamicBatching, useGPUInstancing, shadowSettings);
            }
        }
    }
}