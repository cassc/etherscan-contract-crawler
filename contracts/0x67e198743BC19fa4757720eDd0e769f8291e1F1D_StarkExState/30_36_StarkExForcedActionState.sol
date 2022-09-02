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

import "StarkExStorage.sol";
import "MStarkExForcedActionState.sol";
import "ActionHash.sol";

/*
  StarkExchange specific action hashses.
*/
contract StarkExForcedActionState is StarkExStorage, ActionHash, MStarkExForcedActionState {
    function fullWithdrawActionHash(uint256 ownerKey, uint256 vaultId)
        internal
        pure
        override
        returns (bytes32)
    {
        return getActionHash("FULL_WITHDRAWAL", abi.encode(ownerKey, vaultId));
    }

    /*
      Implemented in the FullWithdrawal contracts.
    */
    function clearFullWithdrawalRequest(uint256 ownerKey, uint256 vaultId)
        internal
        virtual
        override
    {
        // Reset escape request.
        delete forcedActionRequests[fullWithdrawActionHash(ownerKey, vaultId)];
    }

    function getFullWithdrawalRequest(uint256 ownerKey, uint256 vaultId)
        public
        view
        override
        returns (uint256)
    {
        // Return request value. Expect zero if the request doesn't exist or has been serviced, and
        // a non-zero value otherwise.
        return forcedActionRequests[fullWithdrawActionHash(ownerKey, vaultId)];
    }

    function setFullWithdrawalRequest(uint256 ownerKey, uint256 vaultId) internal override {
        // FullWithdrawal is always at premium cost, hence the `true`.
        setActionHash(fullWithdrawActionHash(ownerKey, vaultId), true);
    }
}