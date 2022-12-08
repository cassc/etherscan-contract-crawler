// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

import "./IBaselArtFixedPriceSale.sol";

library BaselArtFixedPriceSaleStorage {
    struct Layout {
        address minter;
        mapping(uint256 => BaselArtFixedPriceDrop) drops;
        address blackListAddress;
        address payable artistAddress;
        address payable treasuryAddress;
        mapping(uint256 => mapping (uint256 => address)) itemOwners;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("quantum.contracts.storage.baselartfixedpricesale.v1");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}