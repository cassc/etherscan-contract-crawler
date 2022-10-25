// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library PresaleStorage {
    struct Layout {
        bytes32 merkleRoot;
        mapping(address => bool) claimed;
    }

    bytes32 internal constant APP_STORAGE_SLOT =
        keccak256("NiftyKit.contracts.Presale");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = APP_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}