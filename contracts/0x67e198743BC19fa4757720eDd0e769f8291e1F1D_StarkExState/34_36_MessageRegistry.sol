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

import "Identity.sol";
import "FactRegistry.sol";

contract MessageRegistry is FactRegistry, Identity {
    event LogMsgRegistered(address from, address to, bytes32 msgHash);

    function identify() external pure virtual override returns (string memory) {
        return "StarkWare_MessageRegistry_2021_1";
    }

    // NOLINTNEXTLINE: external-function.
    function registerMessage(address to, bytes32 messageHash) public {
        bytes32 messageFact = keccak256(abi.encodePacked(msg.sender, to, messageHash));
        registerFact(messageFact);
        emit LogMsgRegistered(msg.sender, to, messageHash);
    }

    function isMessageRegistered(
        address from,
        address to,
        bytes32 messageHash
    ) external view returns (bool) {
        bytes32 messageFact = keccak256(abi.encodePacked(from, to, messageHash));
        return _factCheck(messageFact);
    }
}