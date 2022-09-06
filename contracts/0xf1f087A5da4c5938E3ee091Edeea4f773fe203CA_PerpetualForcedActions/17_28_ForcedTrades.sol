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

import "PerpetualStorage.sol";
import "MForcedTradeActionState.sol";
import "PerpetualConstants.sol";
import "MFreezable.sol";
import "MKeyGetters.sol";

abstract contract ForcedTrades is
    PerpetualStorage,
    PerpetualConstants,
    MForcedTradeActionState,
    MFreezable,
    MKeyGetters
{
    event LogForcedTradeRequest(
        uint256 starkKeyA,
        uint256 starkKeyB,
        uint256 vaultIdA,
        uint256 vaultIdB,
        uint256 collateralAssetId,
        uint256 syntheticAssetId,
        uint256 amountCollateral,
        uint256 amountSynthetic,
        bool aIsBuyingSynthetic,
        uint256 nonce
    );

    // NOLINTNEXTLINE: uninitialized-state.
    function forcedTradeRequest(
        uint256 starkKeyA,
        uint256 starkKeyB,
        uint256 vaultIdA,
        uint256 vaultIdB,
        uint256 collateralAssetId,
        uint256 syntheticAssetId,
        uint256 amountCollateral,
        uint256 amountSynthetic,
        bool aIsBuyingSynthetic,
        uint256 submissionExpirationTime,
        uint256 nonce,
        bytes calldata signature,
        bool premiumCost
    ) external notFrozen onlyKeyOwner(starkKeyA) {
        require(vaultIdA < PERPETUAL_POSITION_ID_UPPER_BOUND, "OUT_OF_RANGE_POSITION_ID");
        require(vaultIdB < PERPETUAL_POSITION_ID_UPPER_BOUND, "OUT_OF_RANGE_POSITION_ID");

        require(vaultIdA != vaultIdB, "IDENTICAL_VAULTS");
        require(collateralAssetId == systemAssetType, "SYSTEM_ASSET_NOT_IN_TRADE");
        require(collateralAssetId != uint256(0x0), "SYSTEM_ASSET_NOT_SET");
        require(collateralAssetId != syntheticAssetId, "IDENTICAL_ASSETS");
        require(configurationHash[syntheticAssetId] != bytes32(0x0), "UNKNOWN_ASSET");
        require(amountCollateral < PERPETUAL_AMOUNT_UPPER_BOUND, "ILLEGAL_AMOUNT");
        require(amountSynthetic < PERPETUAL_AMOUNT_UPPER_BOUND, "ILLEGAL_AMOUNT");
        require(nonce < K_MODULUS, "INVALID_NONCE_VALUE");
        require(submissionExpirationTime >= block.timestamp / 3600, "REQUEST_TIME_EXPIRED");

        // Start timer on escape request.
        setForcedTradeRequest(
            starkKeyA,
            starkKeyB,
            vaultIdA,
            vaultIdB,
            collateralAssetId,
            syntheticAssetId,
            amountCollateral,
            amountSynthetic,
            aIsBuyingSynthetic,
            nonce,
            premiumCost
        );

        validatePartyBSignature(
            starkKeyA,
            starkKeyB,
            vaultIdA,
            vaultIdB,
            collateralAssetId,
            syntheticAssetId,
            amountCollateral,
            amountSynthetic,
            aIsBuyingSynthetic,
            submissionExpirationTime,
            nonce,
            signature
        );

        // Log request.
        emit LogForcedTradeRequest(
            starkKeyA,
            starkKeyB,
            vaultIdA,
            vaultIdB,
            collateralAssetId,
            syntheticAssetId,
            amountCollateral,
            amountSynthetic,
            aIsBuyingSynthetic,
            nonce
        );
    }

    function freezeRequest(
        uint256 starkKeyA,
        uint256 starkKeyB,
        uint256 vaultIdA,
        uint256 vaultIdB,
        uint256 collateralAssetId,
        uint256 syntheticAssetId,
        uint256 amountCollateral,
        uint256 amountSynthetic,
        bool aIsBuyingSynthetic,
        uint256 nonce
    ) external notFrozen {
        // Verify vaultId in range.
        require(vaultIdA < PERPETUAL_POSITION_ID_UPPER_BOUND, "OUT_OF_RANGE_POSITION_ID");
        require(vaultIdB < PERPETUAL_POSITION_ID_UPPER_BOUND, "OUT_OF_RANGE_POSITION_ID");

        // Load request time.
        uint256 requestTime = getForcedTradeRequest(
            starkKeyA,
            starkKeyB,
            vaultIdA,
            vaultIdB,
            collateralAssetId,
            syntheticAssetId,
            amountCollateral,
            amountSynthetic,
            aIsBuyingSynthetic,
            nonce
        );

        validateFreezeRequest(requestTime);
        freeze();
    }

    function validatePartyBSignature(
        uint256 starkKeyA,
        uint256 starkKeyB,
        uint256 vaultIdA,
        uint256 vaultIdB,
        uint256 collateralAssetId,
        uint256 syntheticAssetId,
        uint256 amountCollateral,
        uint256 amountSynthetic,
        bool aIsBuyingSynthetic,
        uint256 submissionExpirationTime,
        uint256 nonce,
        bytes memory signature
    ) internal view {
        bytes32 actionHash = forcedTradeActionHash(
            starkKeyA,
            starkKeyB,
            vaultIdA,
            vaultIdB,
            collateralAssetId,
            syntheticAssetId,
            amountCollateral,
            amountSynthetic,
            aIsBuyingSynthetic,
            nonce
        );

        bytes32 signedData = keccak256(abi.encodePacked(actionHash, submissionExpirationTime));
        address signer;
        {
            uint8 v = uint8(signature[64]);
            bytes32 r;
            bytes32 s;

            assembly {
                r := mload(add(signature, 32))
                s := mload(add(signature, 64))
            }
            signer = ecrecover(signedData, v, r, s);
        }
        address starkKeyBOwner = getEthKey(starkKeyB);
        require(starkKeyBOwner != address(0x0), "USER_B_UNREGISTERED");
        require(signer == starkKeyBOwner, "INVALID_SIGNATURE");
    }
}