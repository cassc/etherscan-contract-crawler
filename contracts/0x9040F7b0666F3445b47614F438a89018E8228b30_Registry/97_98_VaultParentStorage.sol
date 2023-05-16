// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library VaultParentStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.vaultParent');

    struct ChainValue {
        uint value;
        uint lastUpdate;
    }

    struct Layout {
        bytes32 vaultId;
        bool childCreationInProgress;
        bool bridgeInProgress;
        uint lastBridgeCancellation;
        uint withdrawsInProgress;
        uint16[] childChains;
        mapping(uint16 => address) children;
        mapping(uint16 => ChainValue) chainTotalValues;
        uint16 bridgeApprovedTo;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}