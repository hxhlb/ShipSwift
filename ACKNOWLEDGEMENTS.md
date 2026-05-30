# Acknowledgements

ShipSwift bundles code adapted from third-party open-source projects. Their
original copyright and license notices are reproduced below as required.

---

## ShaderKit

The following ShipSwift components are adapted from **ShaderKit** by
James Rochabrun (https://github.com/jamesrochabrun/ShaderKit):

- `SWPackage/SWAnimation/SWMetal/SWFoil.metal` / `SWFoil.swift`
- `SWPackage/SWAnimation/SWMetal/SWGlitter.metal` / `SWGlitter.swift`
- `SWPackage/SWAnimation/SWMetal/SWIntenseBling.metal` / `SWIntenseBling.swift`
- `SWPackage/SWAnimation/SWMetal/SWChromaticGlass.metal` / `SWChromaticGlass.swift`
- `SWPackage/SWAnimation/SWMetal/SWPolishedAluminum.metal` / `SWPolishedAluminum.swift`

The Metal shaders are taken from ShaderKit's `FoilEffectsShaders.metal`,
`IntenseBlingShader.metal`, `GlassShaders.metal` (the `chromaticGlass`
function), `PolishedAluminumShader.metal`, and shared helpers from
`ShaderUtilities.metal`. They were renamed with a `swSW`-style prefix and
re-wrapped as SwiftUI `layerEffect` views to fit ShipSwift's conventions,
but the shader logic is preserved from the original.

### License

```
MIT License

Copyright (c) 2025 James Rochabrun

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## Star Nest

The following ShipSwift component is adapted from **"Star Nest"** by
Pablo Roman Andrioli ("Kali"), originally published on Shadertoy
(https://www.shadertoy.com/view/XlfGRj):

- `SWPackage/SWAnimation/SWMetal/SWStarNest.metal` / `SWStarNest.swift`

The GLSL fragment shader was ported to a Metal `stitchable` color effect and
re-wrapped as a SwiftUI `.colorEffect` background view to fit ShipSwift's
conventions (the mouse-driven camera was replaced with explicit `angleX` /
`angleY` parameters). The fractal "magic formula", volumetric march, and all
tuning constants are preserved from the original.

### License

```
MIT License

Copyright (c) Pablo Roman Andrioli

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## Demo Imagery (Player Cards showcase)

The `SWPlayerCardShowcase` demo applies the foil shaders to scenery photos
sourced from Wikimedia Commons under the licenses noted below. Attribution is
provided here as required by the respective licenses.

- `Assets.xcassets/aurora` — "Aurora borealis over Eielson Air Force Base,
  Alaska." U.S. Air Force photo by Senior Airman Joshua Strang. **Public domain.**
- `Assets.xcassets/glacier` — "Geikie Plateau Glacier." NASA / Christy Hansen.
  **Public domain.**
- `Assets.xcassets/galaxy` — "The Milky Way" (ESO-VLT-Laser). © ESO / Y. Beletsky.
  **CC BY 4.0** — https://creativecommons.org/licenses/by/4.0/
- `Assets.xcassets/fireworks` — "New Year's Eve on Sydney Harbour."
  © Rob Chandler. **CC BY-SA 2.0** — https://creativecommons.org/licenses/by-sa/2.0/
- `Assets.xcassets/peak` — "Matterhorn from Domhütte." © Zacharie Grossen.
  **CC BY-SA 3.0** — https://creativecommons.org/licenses/by-sa/3.0/

The two CC BY-SA images retain their share-alike terms; swap them for
public-domain alternatives if a fully unrestricted bundle is required.
