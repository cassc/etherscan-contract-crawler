// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library VaultParentStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.vaultParent');

    // solhint-disable-next-line ordering
    struct ChainValue {
        uint minValue;
        uint lastUpdate;
        uint maxValue;
    }

    // solhint-disable-next-line ordering
    struct Layout {
        bytes32 _deprecated_vaultId;
        bool childCreationInProgress;
        bool bridgeInProgress;
        uint lastBridgeCancellation;
        uint withdrawsInProgress;
        uint16[] childChains;
        // chainId => childVault address
        mapping(uint16 => address) children;
        mapping(uint16 => ChainValue) chainTotalValues;
        uint16 bridgeApprovedFor;
        // Not a big fan of inverted flags, but some vaults were already deployed.
        // Would have preferred to have childIsActive
        mapping(uint16 => bool) childIsInactive;
        bool vaultClosed;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}