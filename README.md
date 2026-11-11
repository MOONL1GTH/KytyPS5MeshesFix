# KytyPS5 MeshesFix

An experimental fork of [KytyPS5](https://github.com/KytyPS5/KytyPS5) that adds support for
GPUs without Vulkan mesh shaders (`VK_EXT_mesh_shader`), such as AMD RDNA 1 (RX 5600M,
RX 5700 series).

> **Status: experimental.** Behavior is under active development and not yet validated across
> games. Expect crashes, graphical errors and reduced performance.

## Background

KytyPS5 translates PS5 primitive (NGG) shaders into Vulkan mesh shaders. On GPUs that lack
this extension, the emulator aborts with:

```
Not implemented (!m_graphics.mesh_shader_enabled)
```

which prevents most 3D titles from running.

## Approach

When mesh shaders are unavailable, this fork replaces the mesh stage with an equivalent
two-pass pipeline:

1. **Compute pass.** The translated primitive shader runs as a compute shader and writes
   vertex attributes and primitive indices into a device-local buffer.
2. **Vertex pass.** A generic vertex shader reads that buffer and feeds the unmodified
   fragment pipeline.

GPUs with native mesh shader support continue to use the original path.

## Releases

Prebuilt Windows x64 builds are published on the
[Releases](../../releases) page. Download the latest archive, extract it, and delete any
existing `_PipelineCache` folder before first launch.

## Known limitations

- Clip distances, cull distances and user clip planes are not applied on fallback draws.
- Indirect mesh draws use the CPU path; primitive restart is ignored.
- Each fallback draw splits the render pass, which reduces performance.
- Draws requiring more than 192 MB of intermediate buffer are skipped with a warning.

## Reporting issues

Please include your GPU model, driver version, game title ID and the console log. Report
problems specific to this fork here, not to the upstream project.

## Credits and license

Based on [KytyPS5](https://github.com/KytyPS5/KytyPS5), itself derived from
[Kyty](https://github.com/InoriRus/Kyty). Distributed under the **GPL-2.0** license; see
[LICENSE](LICENSE).

This project is not affiliated with Sony Interactive Entertainment. It does not include or
distribute games or system software; use only content you have legally obtained.
