#version 460
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_shader_explicit_arithmetic_types_int64 : require
#extension GL_ARB_shader_viewport_layer_array : require

// Draws the triangles a mesh program wrote when it ran as a compute shader, on hosts without mesh
// shaders. The layout is IR::MeshFallbackLayout; each work group has a slot, and the draw covers
// max_primitives triangles per slot, hiding the unused ones as degenerate triangles.

#ifndef PARAM_COUNT
#define PARAM_COUNT 8
#endif

layout(buffer_reference, std430, buffer_reference_align = 16) readonly buffer FloatSlot {
	vec4 v[];
};
layout(buffer_reference, std430, buffer_reference_align = 16) readonly buffer UintSlot {
	uvec4 v[];
};

// Dwords 0..7 of IR::PushData; the pixel program's data follows.
layout(push_constant) uniform Push {
	uint max_primitives;
	uint slot_stride;
	uint prim_offset;
	uint vertex_stride;
	uint param_mask;
	uint address_low;
	uint address_high;
	uint groups;
} pc;

layout(location = 0) out vec4 o_param[PARAM_COUNT];

void main() {
	uint primitive_global = uint(gl_VertexIndex) / 3u;
	uint corner           = uint(gl_VertexIndex) - primitive_global * 3u;
	uint group            = primitive_global / pc.max_primitives;
	uint primitive        = primitive_global - group * pc.max_primitives;
	uint slot             = uint(gl_InstanceIndex) * pc.groups + group;

	uint64_t base = uint64_t(pc.address_low) | (uint64_t(pc.address_high) << 32);
	uint64_t slot_address = base + uint64_t(slot) * uint64_t(pc.slot_stride) * uint64_t(16);
	UintSlot  slot_uint  = UintSlot(slot_address);
	FloatSlot slot_float = FloatSlot(slot_address);

	uvec4 header = slot_uint.v[0];
	uvec4 record = slot_uint.v[pc.prim_offset + primitive];
	bool  valid  = primitive < header.y && (record.w & 0x80000000u) == 0u;
	if (!valid) {
		gl_Position = vec4(0.0);
		gl_Layer    = 0;
		for (uint i = 0u; i < uint(PARAM_COUNT); i++) {
			o_param[i] = vec4(0.0);
		}
		return;
	}
	uint vertex_base = 1u + record[corner] * pc.vertex_stride;
	gl_Position      = slot_float.v[vertex_base];
	gl_Layer         = int(record.w & 0xffffu);
	for (uint i = 0u; i < uint(PARAM_COUNT); i++) {
		o_param[i] = (pc.param_mask & (1u << i)) != 0u ? slot_float.v[vertex_base + 1u + i]
		                                               : vec4(0.0);
	}
}
