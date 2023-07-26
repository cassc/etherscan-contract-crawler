// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct OpenSeaProxyInitArgs {
	address os721Proxy;
	address os1155Proxy;
}

library OpenSeaProxyStorage {
	struct Layout {
		address os721Proxy;
		address os1155Proxy;
	}

	bytes32 internal constant STORAGE_SLOT = keccak256("com.opensea.contracts.storage.proxy");

	function layout() internal pure returns (Layout storage l) {
		bytes32 slot = STORAGE_SLOT;
		// slither-disable-next-line timestamp
		// solhint-disable-next-line no-inline-assembly
		assembly {
			l.slot := slot
		}
	}

	function _setProxies(OpenSeaProxyInitArgs memory init) internal {
		_setProxies(init.os721Proxy, init.os1155Proxy);
	}

	function _setProxies(address os721Proxy, address os1155Proxy) internal {
		layout().os721Proxy = os721Proxy;
		layout().os1155Proxy = os1155Proxy;
	}
}