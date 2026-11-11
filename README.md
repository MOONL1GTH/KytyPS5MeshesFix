# KytyPS5 MeshesFix

An **experimental fork** of [KytyPS5](https://github.com/KytyPS5/KytyPS5), a free and open-source
PlayStation 5 translation layer, that tries to run games on GPUs **without `VK_EXT_mesh_shader`**
support, such as AMD RDNA 1 cards (for example the RX 5600M and RX 5700 series).

> [!IMPORTANT]
> This fork is not affiliated with Sony Interactive Entertainment, PlayStation or the KytyPS5
> maintainers. It does not distribute games or copyrighted system software. Use only game files
> that you have obtained legally.

> [!WARNING]
> Work in progress. The changes here are largely untested, and games may crash, render
> incorrectly or run slowly. Do not expect upstream-level compatibility.

## The problem

KytyPS5 translates the PS5's primitive (NGG) shaders into Vulkan mesh shaders. GPUs without
mesh shader support stop with:

```
Not implemented (!m_graphics.mesh_shader_enabled) in ...pipelineCache.cpp
```

so most 3D games cannot run on them.

## What this fork changes

1. **Stage 1: no crash.** Draws that need mesh shaders are skipped with a warning instead of
   exiting the emulator.
2. **Stage 2: compute fallback.** When the GPU has no mesh shaders, each PS5 primitive shader is
   compiled as a **compute shader** that writes its vertices and triangles to a GPU buffer. A
   generic vertex shader (`src/graphics/host_gpu/shaders/gpu_mesh_fallback.vert`) then draws
   from that buffer, and the normal pixel shaders are used unchanged.

Design notes and the list of changed files are in [`HANDOFF.md`](HANDOFF.md).

### Known limitations

- Clip and cull distances and user clip planes are not applied to fallback draws.
- Indirect mesh draws use the CPU path, and primitive restart is ignored.
- Each fallback draw interrupts the render pass, so performance is reduced.
- Draws needing more than 192 MB of fallback buffer are skipped with a warning.

## Building

You do not need a local toolchain. The build runs on GitHub Actions:

1. Open the **Actions** tab and select **Build and Release KytyPS5**.
2. Run the workflow (or push a commit) and wait for the **Windows** job to finish.
3. Download the `KytyPS5-Windows-x64` artifact and unzip it.
4. **Delete the `_PipelineCache` folder** next to the executable when switching between builds.

To build locally, follow the instructions in the
[upstream repository](https://github.com/KytyPS5/KytyPS5).

## Reporting results

Useful reports include your GPU model, the game's title ID, and the console output. Build
errors from the Actions log are also helpful. Please do not report problems from this fork to
the upstream maintainers unless you can reproduce them with an unmodified upstream build.

## Credits and license

KytyPS5 is based on a heavily modified version of [Kyty](https://github.com/InoriRus/Kyty).
All credit for the emulator goes to the KytyPS5 and Kyty authors. This fork keeps the upstream
license, **GPL-2.0**; see [`LICENSE`](LICENSE) and the [`LICENSES`](LICENSES) folder.
