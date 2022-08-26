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

import "LibConstants.sol";
import "MAcceptModifications.sol";
import "MTokenQuantization.sol";
import "MainStorage.sol";

/*
  Interface containing actions a verifier can invoke on the state.
  The contract containing the state should implement these and verify correctness.
*/
abstract contract AcceptModifications is
    MainStorage,
    LibConstants,
    MAcceptModifications,
    MTokenQuantization
{
    event LogWithdrawalAllowed(
        uint256 ownerKey,
        uint256 assetType,
        uint256 nonQuantizedAmount,
        uint256 quantizedAmount
    );

    event LogNftWithdrawalAllowed(uint256 ownerKey, uint256 assetId);

    event LogAssetWithdrawalAllowed(uint256 ownerKey, uint256 assetId, uint256 quantizedAmount);

    event LogMintableWithdrawalAllowed(uint256 ownerKey, uint256 assetId, uint256 quantizedAmount);

    /*
      Transfers funds from the on-chain deposit area to the off-chain area.
      Implemented in the Deposits contracts.
    */
    function acceptDeposit(
        uint256 ownerKey,
        uint256 vaultId,
        uint256 assetId,
        uint256 quantizedAmount
    ) internal virtual override {
        // Fetch deposit.
        require(
            pendingDeposits[ownerKey][assetId][vaultId] >= quantizedAmount,
            "DEPOSIT_INSUFFICIENT"
        );

        // Subtract accepted quantized amount.
        pendingDeposits[ownerKey][assetId][vaultId] -= quantizedAmount;
    }

    /*
      Transfers funds from the off-chain area to the on-chain withdrawal area.
    */
    function allowWithdrawal(
        uint256 ownerKey,
        uint256 assetId,
        uint256 quantizedAmount
    ) internal override {
        // Fetch withdrawal.
        uint256 withdrawal = pendingWithdrawals[ownerKey][assetId];

        // Add accepted quantized amount.
        withdrawal += quantizedAmount;
        require(withdrawal >= quantizedAmount, "WITHDRAWAL_OVERFLOW");

        // Store withdrawal.
        pendingWithdrawals[ownerKey][assetId] = withdrawal;

        // Log event.
        uint256 presumedAssetType = assetId;
        if (registeredAssetType[presumedAssetType]) {
            emit LogWithdrawalAllowed(
                ownerKey,
                presumedAssetType,
                fromQuantized(presumedAssetType, quantizedAmount),
                quantizedAmount
            );
        } else if (assetId == ((assetId & MASK_240) | MINTABLE_ASSET_ID_FLAG)) {
            emit LogMintableWithdrawalAllowed(ownerKey, assetId, quantizedAmount);
        } else {
            // Default case is Non-Mintable ERC721 or ERC1155 asset id.
            // In ERC721 and ERC1155 cases, assetId is not the assetType.
            require(assetId == assetId & MASK_250, "INVALID_ASSET_ID");
            // If withdrawal amount is 1, the asset could be either NFT or SFT. In that case, both
            // NFT and general events will be emitted so that the listened for event is captured.
            // When withdrawal is greater than 1, it must be SFT and only one event will be emitted.
            if (withdrawal <= 1) {
                emit LogNftWithdrawalAllowed(ownerKey, assetId);
            }
            emit LogAssetWithdrawalAllowed(ownerKey, assetId, quantizedAmount);
        }
    }

    // Verifier authorizes withdrawal.
    function acceptWithdrawal(
        uint256 ownerKey,
        uint256 assetId,
        uint256 quantizedAmount
    ) internal virtual override {
        allowWithdrawal(ownerKey, assetId, quantizedAmount);
    }
}