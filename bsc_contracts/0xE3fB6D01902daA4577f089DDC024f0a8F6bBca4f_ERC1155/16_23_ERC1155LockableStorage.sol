// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library ERC1155LockableStorage {
    struct Layout {
        mapping(address => mapping(uint256 => uint256)) lockedAmount;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.ERC1155Lockable");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}