--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict

return table.freeze({

	NAMESPACE_STORAGE_NAME = "SwitchNet2_Namespaces",

	--// namespace/packet initialization settings
	NAMESPACE_NAME_SIZE_LIMIT = 32,
	PACKET_NAME_SIZE_LIMIT = 64,

	--// compression settings
	BUFFER_SIZE_LIMIT = 2 ^ 21,
	MAX_REFERENCES = 2 ^ 16,
	REFERENCES_PRE_ALLOC_SIZE = 32,

})