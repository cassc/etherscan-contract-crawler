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

abstract contract MStarkExForcedActionState {
    function fullWithdrawActionHash(uint256 ownerKey, uint256 vaultId)
        internal
        pure
        virtual
        returns (bytes32);

    function clearFullWithdrawalRequest(uint256 ownerKey, uint256 vaultId) internal virtual;

    // NOLINTNEXTLINE: external-function.
    function getFullWithdrawalRequest(uint256 ownerKey, uint256 vaultId)
        public
        view
        virtual
        returns (uint256);

    function setFullWithdrawalRequest(uint256 ownerKey, uint256 vaultId) internal virtual;
}