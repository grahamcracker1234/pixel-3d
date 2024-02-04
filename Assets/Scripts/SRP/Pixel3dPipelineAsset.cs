using UnityEngine;
using UnityEngine.Rendering;

namespace Pixel3d
{
    [CreateAssetMenu(menuName = "Rendering/Pixel 3D")]
    public class CustomPipelineAsset : RenderPipelineAsset
    {
        [SerializeField]
        bool useDynamicBatching = true, useGPUInstancing = true, useSRPBatcher = true;

        [SerializeField]
        ShadowSettings shadows = default;

        protected override RenderPipeline CreatePipeline()
        {
            return new CustomPipeline(useDynamicBatching, useGPUInstancing, useSRPBatcher, shadows);
        }
    }
}