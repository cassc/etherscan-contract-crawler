// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

library ACLStorage {
    struct Layout {
        mapping(address => bool) admins;
        mapping(address => bool) authorized;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("game.contracts.storage.ACL");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}