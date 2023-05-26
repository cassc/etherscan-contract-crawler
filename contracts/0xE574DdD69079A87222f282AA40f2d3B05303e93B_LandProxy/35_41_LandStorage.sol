// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { MintState, Zone } from "./LandTypes.sol";

library LandStorage {
	struct Layout {
		uint8 mintState;
		uint16 index; // current incremental index of zone id's
		uint64 price;
		address signer;
		address avatars;
		Zone avatarClaim; // zoneId is zero
		mapping(uint256 => address) claimedAvatars;
		mapping(uint16 => Zone) zones;
		mapping(address => bool) proxies;
	}

	bytes32 internal constant STORAGE_SLOT = keccak256("io.frogland.contracts.storage.LandStorage");

	function layout() internal pure returns (Layout storage l) {
		bytes32 slot = STORAGE_SLOT;
		// slither-disable-next-line timestamp
		// solhint-disable no-inline-assembly
		assembly {
			l.slot := slot
		}
	}

	// Adders

	function _addClaimCount(uint16 count) internal {
		layout().avatarClaim.count += count;
	}

	function _addCount(uint16 index, uint16 count) internal {
		Zone storage zone = _getZone(index);
		_addCount(zone, count);
	}

	function _addCount(Zone storage zone, uint16 count) internal {
		zone.count += count;
	}

	function _addInventory(Zone storage zone, uint16 count) internal {
		zone.max += count;
	}

	function _removeInventory(Zone storage zone, uint16 count) internal {
		zone.max -= count;
	}

	function _addZone(Zone memory zone) internal {
		uint16 index = _getIndex();
		index += 1;
		layout().zones[index] = zone;
		_setIndex(index);
	}

	// Getters

	function _getClaimedAvatar(uint256 tokenId) internal view returns (address) {
		return layout().claimedAvatars[tokenId];
	}

	function _getIndex() internal view returns (uint16 index) {
		return layout().index;
	}

	function _getPrice() internal view returns (uint64) {
		return layout().price;
	}

	function _getSigner() internal view returns (address) {
		return layout().signer;
	}

	function _getZone(uint16 index) internal view returns (Zone storage) {
		if (index == 0) {
			return layout().avatarClaim;
		}
		return layout().zones[index];
	}

	// Setters

	function _setAvatars(address avatars) internal {
		layout().avatars = avatars;
	}

	function _setClaimedAvatar(uint256 tokenId, address claimedBy) internal {
		layout().claimedAvatars[tokenId] = claimedBy;
	}

	function _setClaimedAvatars(uint256[] memory tokenIds, address claimedBy) internal {
		for (uint256 index = 0; index < tokenIds.length; index++) {
			uint256 tokenId = tokenIds[index];
			_setClaimedAvatar(tokenId, claimedBy);
		}
	}

	function _setIndex(uint16 index) internal {
		layout().index = index;
	}

	function _setInventory(Zone storage zone, uint16 maxCount) internal {
		zone.max = maxCount;
	}

	function _setPrice(uint64 price) internal {
		layout().price = price;
	}

	function _setProxy(address proxy, bool enabled) internal {
		layout().proxies[proxy] = enabled;
	}

	function _setSigner(address signer) internal {
		layout().signer = signer;
	}
}