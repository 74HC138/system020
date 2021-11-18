abs RAM_BASE

__SerialRingbuffer: ;clean ringbuffer
		ds.w 256
__SerialRBRead: ;read index into ringbuffer
		ds.w 1
__SerialRBWrite: ;write index into ringbuffer
		ds.w 1
__CommandBuffer:
		ds.w 256
