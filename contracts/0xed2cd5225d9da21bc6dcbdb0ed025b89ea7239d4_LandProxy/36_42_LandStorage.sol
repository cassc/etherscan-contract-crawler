// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Category, Segment, Zone } from "./LandTypes.sol";

library LandStorage {
	struct Layout {
		uint8 mintState;
		address signer;
		address icons;
		address lions;
		uint8 zoneIndex;
		mapping(uint8 => Zone) zones;
		mapping(address => bool) proxies;
	}

	bytes32 internal constant STORAGE_SLOT =
		keccak256("co.sportsmetaverse.contracts.storage.LandStorage");

	function layout() internal pure returns (Layout storage l) {
		bytes32 slot = STORAGE_SLOT;
		// slither-disable-next-line timestamp
		// solhint-disable-next-line no-inline-assembly
		assembly {
			l.slot := slot
		}
	}

	// Adders

	// add the count of minted inventory to the zone segment
	function _addCount(
		uint8 zoneId,
		uint8 segmentId,
		uint16 count
	) internal {
		Zone storage zone = LandStorage.layout().zones[zoneId];
		Category category = Category(segmentId);

		if (category == Category.ONExONE) {
			zone.one.count += count;
		} else if (category == Category.TWOxTWO) {
			zone.two.count += count;
		} else if (category == Category.THREExTHREE) {
			zone.three.count += count;
		} else if (category == Category.SIXxSIX) {
			zone.four.count += count;
		}
	}

	function _addInventory(
		Zone storage zone,
		uint8 segmentId,
		uint16 count
	) internal {
		Category category = Category(segmentId);

		if (category == Category.ONExONE) {
			zone.one.max += count;
		} else if (category == Category.TWOxTWO) {
			zone.two.max += count;
		} else if (category == Category.THREExTHREE) {
			zone.three.max += count;
		} else if (category == Category.SIXxSIX) {
			zone.four.max += count;
		}
	}

	function _removeInventory(
		Zone storage zone,
		uint8 segmentId,
		uint16 count
	) internal {
		Category category = Category(segmentId);

		if (category == Category.ONExONE) {
			zone.one.max -= count;
		} else if (category == Category.TWOxTWO) {
			zone.two.max -= count;
		} else if (category == Category.THREExTHREE) {
			zone.three.max -= count;
		} else if (category == Category.SIXxSIX) {
			zone.four.max -= count;
		}
	}

	// add a new zone
	function _addZone(Zone memory zone) internal {
		uint8 index = _getZoneIndex();
		index += 1;
		_setZone(index, zone);
		_setZoneIndex(index);
	}

	// Getters

	// TODO: resolve the indicies in a way that does not
	// require a contract upgrade to add a named zone
	function _getIndexSportsCity() internal pure returns (uint8) {
		return 1;
	}

	function _getIndexLionLands() internal pure returns (uint8) {
		return 2;
	}

	// get a segment for a zoneId and segmentId
	function _getSegment(uint8 zoneId, uint8 segmentId)
		internal
		view
		returns (Segment memory segment)
	{
		Zone memory zone = _getZone(zoneId);
		return _getSegment(zone, segmentId);
	}

	// get a segment for a zone and segmentId
	function _getSegment(Zone memory zone, uint8 segmentId)
		internal
		pure
		returns (Segment memory segment)
	{
		Category category = Category(segmentId);
		if (category == Category.ONExONE) {
			return zone.one;
		}
		if (category == Category.TWOxTWO) {
			return zone.two;
		}
		if (category == Category.THREExTHREE) {
			return zone.three;
		}
		if (category == Category.SIXxSIX) {
			return zone.four;
		}
		revert("_getCategory: wrong category");
	}

	function _getSigner() internal view returns (address) {
		return layout().signer;
	}

	// get the current index of zones
	function _getZoneIndex() internal view returns (uint8) {
		return layout().zoneIndex;
	}

	// get a zone from storage
	function _getZone(uint8 zoneId) internal view returns (Zone storage) {
		return LandStorage.layout().zones[zoneId];
	}

	// Setters

	// set maximum available inventory
	// note setting to the current count effectively makes none available.
	function _setInventory(
		Zone storage zone,
		uint16 maxOne,
		uint16 maxTwo,
		uint16 maxThree,
		uint16 maxFour
	) internal {
		zone.one.max = maxOne;
		zone.two.max = maxTwo;
		zone.three.max = maxThree;
		zone.four.max = maxFour;
	}

	// set an approved proxy
	function _setProxy(address proxy, bool enabled) internal {
		layout().proxies[proxy] = enabled;
	}

	// set the account that can sign tgransactions
	function _setSigner(address signer) internal {
		layout().signer = signer;
	}

	function _setZone(uint8 zoneId, Zone memory zone) internal {
		layout().zones[zoneId] = zone;
	}

	function _setZoneIndex(uint8 index) internal {
		layout().zoneIndex = index;
	}

	function _isValidInventory(Segment memory segment, uint16 maxCount) internal pure returns (bool) {
		require(maxCount >= segment.count, "_isValidInventory: invalid");
		require(
			maxCount <= segment.endIndex - segment.startIndex - segment.count,
			"_isValidInventory: too much"
		);

		return true;
	}

	function _isValidSegment(Segment memory last, Segment memory incoming)
		internal
		pure
		returns (bool)
	{
		require(incoming.count == 0, "_isValidSegment: wrong count");
		require(incoming.startIndex == last.endIndex, "_isValidSegment: wrong start");
		require(incoming.startIndex <= incoming.endIndex, "_isValidSegment: wrong end");
		require(incoming.max <= incoming.endIndex - incoming.startIndex, "_isValidSegment: wrong max");
		return true;
	}
}