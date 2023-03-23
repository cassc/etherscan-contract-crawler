/*
  Copyright 2019-2023 StarkWare Industries Ltd.

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

import "NamedStorage.sol";
import "IStarknetMessaging.sol";

abstract contract StarknetTokenStorage {
    // Random storage slot tags.
    string internal constant BRIDGED_TOKEN_TAG = "STARKNET_ERC20_TOKEN_BRIDGE_TOKEN_ADDRESS";
    string internal constant L2_TOKEN_TAG = "STARKNET_TOKEN_BRIDGE_L2_TOKEN_CONTRACT";
    string internal constant MAX_DEPOSIT_TAG = "STARKNET_TOKEN_BRIDGE_MAX_DEPOSIT";
    string internal constant MAX_TOTAL_BALANCE_TAG = "STARKNET_TOKEN_BRIDGE_MAX_TOTAL_BALANCE";
    string internal constant MESSAGING_CONTRACT_TAG = "STARKNET_TOKEN_BRIDGE_MESSAGING_CONTRACT";
    string internal constant DEPOSITOR_ADDRESSES_TAG = "STARKNET_TOKEN_BRIDGE_DEPOSITOR_ADDRESSES";
    string internal constant BRIDGE_IS_ACTIVE_TAG = "STARKNET_TOKEN_BRIDGE_IS_ACTIVE";

    // Storage Getters.
    function bridgedToken() internal view returns (address) {
        return NamedStorage.getAddressValue(BRIDGED_TOKEN_TAG);
    }

    function l2TokenBridge() internal view returns (uint256) {
        return NamedStorage.getUintValue(L2_TOKEN_TAG);
    }

    function maxDeposit() public view returns (uint256) {
        return NamedStorage.getUintValue(MAX_DEPOSIT_TAG);
    }

    function maxTotalBalance() public view returns (uint256) {
        return NamedStorage.getUintValue(MAX_TOTAL_BALANCE_TAG);
    }

    function messagingContract() internal view returns (IStarknetMessaging) {
        return IStarknetMessaging(NamedStorage.getAddressValue(MESSAGING_CONTRACT_TAG));
    }

    function isActive() public view returns (bool) {
        return NamedStorage.getBoolValue(BRIDGE_IS_ACTIVE_TAG);
    }

    function depositors() internal pure returns (mapping(uint256 => address) storage) {
        return NamedStorage.uintToAddressMapping(DEPOSITOR_ADDRESSES_TAG);
    }

    // Storage Setters.
    function bridgedToken(address contract_) internal {
        NamedStorage.setAddressValueOnce(BRIDGED_TOKEN_TAG, contract_);
    }

    function l2TokenBridge(uint256 value) internal {
        NamedStorage.setUintValueOnce(L2_TOKEN_TAG, value);
    }

    function maxDeposit(uint256 value) internal {
        NamedStorage.setUintValue(MAX_DEPOSIT_TAG, value);
    }

    function maxTotalBalance(uint256 value) internal {
        NamedStorage.setUintValue(MAX_TOTAL_BALANCE_TAG, value);
    }

    function messagingContract(address contract_) internal {
        NamedStorage.setAddressValueOnce(MESSAGING_CONTRACT_TAG, contract_);
    }

    function setActive() internal {
        return NamedStorage.setBoolValue(BRIDGE_IS_ACTIVE_TAG, true);
    }
}