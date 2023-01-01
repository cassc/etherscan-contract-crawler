// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library ERC1155SupplyAdminStorage {
    struct Layout {
        mapping(uint256 => bool) maxSupplyFrozen;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.ERC1155SupplyAdmin");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}