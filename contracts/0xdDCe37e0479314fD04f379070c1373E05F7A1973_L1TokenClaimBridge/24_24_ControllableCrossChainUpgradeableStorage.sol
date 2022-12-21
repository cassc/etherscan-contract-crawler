// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library ControllableCrossChainUpgradeableStorage {
    bytes32 constant STORAGE_POSITION =
        keccak256("homage.controllable-cross-chain-upgradeable");

    struct Struct {
        address deployer;
        address crossChainOwner;
    }

    function get() internal pure returns (Struct storage storageStruct) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            storageStruct.slot := position
        }
    }
}