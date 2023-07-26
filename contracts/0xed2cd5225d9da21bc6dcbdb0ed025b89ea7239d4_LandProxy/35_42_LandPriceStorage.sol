// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Category, SegmentPrice } from "./LandTypes.sol";

library LandPriceStorage {
	struct Layout {
		SegmentPrice price;
		mapping(uint8 => SegmentPrice) discountPrices;
	}

	bytes32 internal constant STORAGE_SLOT =
		keccak256("co.sportsmetaverse.contracts.storage.LandPriceStorage");

	function layout() internal pure returns (Layout storage l) {
		bytes32 slot = STORAGE_SLOT;
		assembly {
			l.slot := slot
		}
	}

	// Getters

	function _getDiscountPrice(uint8 zoneId) internal view returns (SegmentPrice storage) {
		return layout().discountPrices[zoneId];
	}

	function _getDiscountPrice(uint8 zoneId, uint8 category) internal view returns (uint64) {
		SegmentPrice memory price = layout().discountPrices[zoneId];
		return _getPrice(price, category);
	}

	function _getPrice() internal view returns (SegmentPrice storage) {
		return layout().price;
	}

	function _getPrice(uint8 category) internal view returns (uint64) {
		SegmentPrice storage price = layout().price;
		return _getPrice(price, category);
	}

	function _getPrice(SegmentPrice memory price, uint8 category) internal pure returns (uint64) {
		if (Category(category) == Category.ONExONE) {
			return price.one;
		}
		if (Category(category) == Category.TWOxTWO) {
			return price.two;
		}
		if (Category(category) == Category.THREExTHREE) {
			return price.three;
		}
		if (Category(category) == Category.SIXxSIX) {
			return price.four;
		}
		revert("_getPrice: wrong category");
	}

	// determine if a specific zone is discountable
	function _isDiscountable(uint8 zoneId) internal view returns (bool) {
		return
			layout().discountPrices[zoneId].one != 0 &&
			layout().discountPrices[zoneId].two != 0 &&
			layout().discountPrices[zoneId].three != 0 &&
			layout().discountPrices[zoneId].four != 0;
	}

	// Setters

	function _setDiscountPrice(uint8 zoneId, SegmentPrice memory price) internal {
		layout().discountPrices[zoneId] = price;
	}

	function _setPrice(SegmentPrice memory price) internal {
		layout().price = price;
	}
}