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
import "MForcedWithdrawalActionState.sol";
import "ActionHash.sol";

/*
  ForcedWithdrawal specific action hashses.
*/
contract ForcedWithdrawalActionState is PerpetualStorage, ActionHash, MForcedWithdrawalActionState {
    function forcedWithdrawActionHash(
        uint256 starkKey,
        uint256 vaultId,
        uint256 quantizedAmount
    ) internal pure override returns (bytes32) {
        return getActionHash("FORCED_WITHDRAWAL", abi.encode(starkKey, vaultId, quantizedAmount));
    }

    function clearForcedWithdrawalRequest(
        uint256 starkKey,
        uint256 vaultId,
        uint256 quantizedAmount
    ) internal override {
        bytes32 actionHash = forcedWithdrawActionHash(starkKey, vaultId, quantizedAmount);
        require(forcedActionRequests[actionHash] != 0, "NON_EXISTING_ACTION");
        delete forcedActionRequests[actionHash];
    }

    function getForcedWithdrawalRequest(
        uint256 starkKey,
        uint256 vaultId,
        uint256 quantizedAmount
    ) public view override returns (uint256) {
        // Return request value. Expect zero if the request doesn't exist or has been serviced, and
        // a non-zero value otherwise.
        return forcedActionRequests[forcedWithdrawActionHash(starkKey, vaultId, quantizedAmount)];
    }

    function setForcedWithdrawalRequest(
        uint256 starkKey,
        uint256 vaultId,
        uint256 quantizedAmount,
        bool premiumCost
    ) internal override {
        setActionHash(forcedWithdrawActionHash(starkKey, vaultId, quantizedAmount), premiumCost);
    }
}