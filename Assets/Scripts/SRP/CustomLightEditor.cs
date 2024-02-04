using UnityEngine;
using UnityEditor;

namespace Pixel3d
{
    [CanEditMultipleObjects]
    [CustomEditorForRenderPipeline(typeof(Light), typeof(CustomPipelineAsset))]
    public class CustomLightEditor : LightEditor
    {
        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();
            if (!settings.lightType.hasMultipleDifferentValues &&
                (LightType)settings.lightType.enumValueIndex == LightType.Spot)
            {
                settings.DrawInnerAndOuterSpotAngle();
                settings.ApplyModifiedProperties();
            }
        }
    }
}