/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "MStateRoot.sol";
import "MainStorage.sol";
import "LibConstants.sol";

contract StateRoot is MainStorage, LibConstants, MStateRoot {
    function initialize(
        uint256 initialSequenceNumber,
        uint256 initialValidiumVaultRoot,
        uint256 initialRollupVaultRoot,
        uint256 initialOrderRoot,
        uint256 initialValidiumTreeHeight,
        uint256 initialRollupTreeHeight,
        uint256 initialOrderTreeHeight
    ) internal {
        sequenceNumber = initialSequenceNumber;
        validiumVaultRoot = initialValidiumVaultRoot;
        rollupVaultRoot = initialRollupVaultRoot;
        orderRoot = initialOrderRoot;
        validiumTreeHeight = initialValidiumTreeHeight;
        rollupTreeHeight = initialRollupTreeHeight;
        orderTreeHeight = initialOrderTreeHeight;
    }

    function getValidiumVaultRoot() public view override returns (uint256) {
        return validiumVaultRoot;
    }

    function getValidiumTreeHeight() public view override returns (uint256) {
        return validiumTreeHeight;
    }

    function getRollupVaultRoot() public view override returns (uint256) {
        return rollupVaultRoot;
    }

    function getRollupTreeHeight() public view override returns (uint256) {
        return rollupTreeHeight;
    }

    function getOrderRoot() external view returns (uint256) {
        return orderRoot;
    }

    function getOrderTreeHeight() external view returns (uint256) {
        return orderTreeHeight;
    }

    function getSequenceNumber() external view returns (uint256) {
        return sequenceNumber;
    }

    function getLastBatchId() external view returns (uint256) {
        return lastBatchId;
    }

    function getGlobalConfigCode() external view returns (uint256) {
        return globalConfigCode;
    }

    function isVaultInRange(uint256 vaultId) internal view override returns (bool) {
        return (isValidiumVault(vaultId) || isRollupVault(vaultId));
    }

    function isValidiumVault(uint256 vaultId) internal view override returns (bool) {
        // Return true iff vaultId is in the validium vaults tree.
        return vaultId < 2**getValidiumTreeHeight();
    }

    function isRollupVault(uint256 vaultId) internal view override returns (bool) {
        // Return true iff vaultId is in the rollup vaults tree.
        uint256 rollupLowerBound = 2**ROLLUP_VAULTS_BIT;
        uint256 rollupUpperBound = rollupLowerBound + 2**getRollupTreeHeight();
        return (rollupLowerBound <= vaultId && vaultId < rollupUpperBound);
    }

    function getVaultLeafIndex(uint256 vaultId) internal pure override returns (uint256) {
        // Return the index of vaultId leaf in its tree, which doesn't include the rollup bit flag.
        return (vaultId & (2**ROLLUP_VAULTS_BIT - 1));
    }
}