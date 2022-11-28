// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library ERC1155TieredSalesStorage {
    struct Layout {
        mapping(uint256 => uint256) tierToTokenId;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.ERC1155TieredSales");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}