// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library ScapesMarketplaceStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("scapes.storage.Marketplace");

    struct Offer {
        uint80 price;
        uint80 specificBuyerPrice;
        uint80 lastPrice;
        address specificBuyer;
    }

    struct Layout {
        address beneficiary;
        uint256 bps;
        mapping(uint256 => Offer) offers;
    }

    function layout() internal pure returns (Layout storage d) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            d.slot := slot
        }
    }
}