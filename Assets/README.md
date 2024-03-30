# Readme

## Todo

- [ ] Add trees + leaf shader
- [ ] Add water shader
- [ ] Add cloud shader (potentially baked onto _ShadowMapTexture?)
- [ ] Add random weeds and flowers
- [ ] Add frustum culling and occlusion culling to grass
- [ ] Pixel perfect camera with zoom and pan
- [ ] Fix ghost mesh culling shadows at world origin
- [ ] Poor depth outlining on large terrain of steep angles
- [ ] Fix grass angle occluded on steep terrain

## Info

- <https://iquilezles.org/articles/voronoise/>
- <https://bruop.github.io/frustum_culling/>
- <https://www.shadertoy.com/playlist/fXlXzf&from=0&num=12>
- <https://www.shadertoy.com/view/lsl3RH>
- <https://forum.unity.com/threads/how-to-extract-view-depth-from-a-camera-render-with-a-shader.1506944>
- <https://ameye.dev/notes/shaders-done-quick/>

## Priority todo

- [x] Pixel Perfect Outlining [6]
  - [x] Generate pixel perfect outlines around the internal and external edges of all objects [4]
    - [x] Internal [2]
      - [x] Outline [1]
      - [x] Pixel perfect (in majority) [1]
    - [x] External [2]
      - [x] Outline [1]
      - [x] Pixel perfect (in majority) [1]
  - [x] Options: on/off [1], colors [1]
- [ ] Pixel Perfect Camera [6]
  - [x] Ensures pixel art remains crisp and clear at different resolutions [2]
    - [x] Downscale [1]
    - [x] Maintain aspect ratio [1]
  - [ ] Ensures stability in motion without excessive "jittering" [4]
    - [x] Zoom in (pixel space) [1]
    - [x] Zoom in (world space) [1]
    - [x] Rotation keeping viewport center in place [1]
    - [ ] Translation pixel offset [1]
- [x] Foliage Rending [8]
  - [x] Rendering of grass on top of meshes with GPU instancing [2]
    - [x] Rendering [1]
    - [x] GPU instancing [1]
  - [x] Rendering of leaves on top of trees with GPU instancing [2]
    - [x] Rendering [1]
    - [x] GPU instancing [1]
  - [x] Frustum culling and chunking to improve performance [3]
    - [x] Chunking [1.5]
    - [x] Frustum culling [1.5]
  - [x] Options: density, colors, wind speed/strength [1]
- [ ] Lighting [8]
  - [x] Cell shader with custom banding textures and real-time lighting [2]
    - [x] Cell shader [1]
    - [x] Custom banding texture [1]
  - [ ] Point lights and directional lights with multi-light shading [3]
    - [x] Directional lights [1]
    - [ ] Point lights [1]
    - [ ] Multi-light [1]
  - [x] Shadows [3]
    - [x] Receive shadows [1]
    - [x] Cast shadows [1]
    - [x] Shadow threshold (for hard/soft shadows) [1]
- [x] Clouds [6]
  - [x] Renders clouds over environment [4]
    - [x] Noise rendering [1]
    - [x] Layered noise [1]
    - [x] Movement [1]
    - [x] Accurate shadow projection [1]
  - [x] Options: cloud coverage [0.66], speed [0.66], direction [0.66]
- [ ] Water [6]
  - [ ] Renders water and other liquids with reflection and refraction [3]
    - [x] Renders [1]
    - [ ] Reflection [1]
    - [x] Refraction [1]
  - [ ] Reacts to movement with ripples [2]
    - [ ] Ripples [1]
    - [ ] React to movement [1]
  - [x] Outline edges for objects both inside and outside the water [0.5]
  - [x] Options: color, absorption, viscosity [0.5]
