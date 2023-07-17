// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library RoyaltyStorage {
    struct RoyaltyInfo {
        uint16 defaultRoyaltyBPS;
        address royaltyReceiver;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("owls.royalty.storage");

    function royaltyInfo() internal pure returns (RoyaltyInfo storage ryl) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            ryl.slot := slot
        }
    }
}