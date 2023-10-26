// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Registry } from '../registry/Registry.sol';
import { IGmxPositionRouterCallbackReceiver } from '../interfaces/IGmxPositionRouterCallbackReceiver.sol';
import { VaultBaseInternal } from './VaultBaseInternal.sol';
import { ExecutorIntegration } from '../executors/IExecutor.sol';
import { VaultBaseStorage } from './VaultBaseStorage.sol';
import { VaultRiskProfile } from './IVaultRiskProfile.sol';

contract VaultBaseExternal is
    IGmxPositionRouterCallbackReceiver,
    VaultBaseInternal
{
    function receiveBridgedAsset(address asset) external onlyTransport {
        _receiveBridgedAsset(asset);
    }

    // The Executor runs as the Vault. I'm not sure this is ideal but it makes writing executors easy
    // Other solutions are
    // 1. The executor returns transactions to be executed which are then assembly called by the this
    // 2. We write the executor code in the vault
    function execute(
        ExecutorIntegration integration,
        bytes memory encodedWithSelectorPayload
    ) external payable onlyManager whenNotPaused nonReentrant {
        _execute(integration, encodedWithSelectorPayload);
    }

    function gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool isIncrease
    ) external nonReentrant {
        _gmxPositionCallback(positionKey, isExecuted, isIncrease);
    }

    function registry() external view returns (Registry) {
        return _registry();
    }

    function manager() external view returns (address) {
        return _manager();
    }

    function vaultId() external view returns (bytes32) {
        return _vaultId();
    }

    function getVaultValue()
        external
        view
        returns (uint minValue, uint maxValue)
    {
        return _getVaultValue();
    }

    function getCurrentCpit() external view returns (uint256) {
        return _getCurrentCpit();
    }

    function riskProfile() external view returns (VaultRiskProfile) {
        return _riskProfile();
    }

    function enabledAssets(address asset) external view returns (bool) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.enabledAssets[asset];
    }

    // This should not be called assetsWithBalances, but should be called enabledAssets;
    // Some assets are enabled even though their balance 0
    // Any example is that the collateralAsset for gmx is enabled for the life of the perp position
    // Becaues the perp can get liquidated and the vault receive the collateral asset without notification.
    function assetsWithBalances() external view returns (address[] memory) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.assets;
    }

    function assetLocks(address asset) external view returns (uint256) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.assetLocks[asset];
    }

    // This can be called by the executors to update the vaults active assets after a tx
    function addActiveAsset(address asset) public onlyThis {
        _addAsset(asset);
    }

    // This can be called by the executors to update the vaults active assets after a tx
    function updateActiveAsset(address asset) public onlyThis {
        _updateActiveAsset(asset);
    }

    // This can be called by the executors
    function addAssetLock(address asset) public onlyThis {
        _addAssetLock(asset);
    }

    // This can be called by the executors
    function removeAssetLock(address asset) public onlyThis {
        _removeAssetLock(asset);
    }
}