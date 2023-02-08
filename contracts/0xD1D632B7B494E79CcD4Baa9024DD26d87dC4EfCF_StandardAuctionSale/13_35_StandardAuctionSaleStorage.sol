// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

import "./interfaces/IStandardAuctionSale.sol";

library StandardAuctionSaleStorage {
    struct Layout {
        address minter;
        mapping(uint256 => bool) vouchersUsed; // voucherId --> boolean (used or not used)
        mapping(uint256 => StandardAuctionDrop) drops; // dropId --> drop
        mapping(uint256 => mapping(uint256 => StandardAuctionItemBid)) bids; // dropId --> itemId --> bid
        uint256 minBidIncrement;
        address blackListAddress;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("quantum.contracts.storage.standardauctionsale.v1");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}