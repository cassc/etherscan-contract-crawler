// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Registry } from '../registry/Registry.sol';

import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';

library VaultBaseStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.VaultBase');

    // solhint-disable-next-line ordering
    struct Layout {
        Registry registry;
        address manager;
        address[] assets;
        mapping(address => bool) enabledAssets;
        VaultRiskProfile riskProfile;
        bytes32 vaultId;
        // For instance a GMX position can get liquidated at anytime and any collateral
        // remaining is returned to the vault. But the vault is not notified.
        // In this case the collateralToken might not be tracked by the vault anymore
        // To resolve this: A GmxPosition will increament the assetLock for the collateralToken, meaning that it cannot
        // be removed from enabledAssets until the lock for the asset reaches 0
        // Any code that adds a lock is responsible for removing the lock
        mapping(address => uint256) assetLocks;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}