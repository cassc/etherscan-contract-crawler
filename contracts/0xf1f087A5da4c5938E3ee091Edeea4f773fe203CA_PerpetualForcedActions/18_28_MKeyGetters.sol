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

abstract contract MKeyGetters {
    // NOLINTNEXTLINE: external-function.
    function getEthKey(uint256 ownerKey) public view virtual returns (address);

    function strictGetEthKey(uint256 ownerKey) internal view virtual returns (address);

    function isMsgSenderKeyOwner(uint256 ownerKey) internal view virtual returns (bool);

    /*
      Allows calling the function only if ownerKey is registered to msg.sender.
    */
    modifier onlyKeyOwner(uint256 ownerKey) {
        // Require the calling user to own the stark key.
        require(msg.sender == strictGetEthKey(ownerKey), "MISMATCHING_STARK_ETH_KEYS");
        _;
    }
}