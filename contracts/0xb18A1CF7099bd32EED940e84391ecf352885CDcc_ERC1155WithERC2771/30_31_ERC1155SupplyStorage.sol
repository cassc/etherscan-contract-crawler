// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library ERC1155SupplyStorage {
    struct Layout {
        mapping(uint256 => uint256) totalSupply;
        mapping(uint256 => uint256) maxSupply;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.ERC1155Supply");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}