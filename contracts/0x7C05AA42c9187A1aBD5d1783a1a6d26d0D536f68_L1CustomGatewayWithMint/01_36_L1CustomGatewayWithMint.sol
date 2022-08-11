/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.8.9;

import "./arb-peripherals/L1CustomGateway.sol";
import "./IEthBridgedToken.sol";

/*
    L1CustomGatewayWithMint is arbitrum L1 gateway that mints new points in L1 whenever they're deposited from L2 and
    burns them when they're withdrawn back to L2
*/

contract L1CustomGatewayWithMint is L1CustomGateway {
    function postUpgradeInit() external override {}

    function initialize(
        address _l1Counterpart,
        address _l1Router,
        address _inbox,
        address _owner
    ) public virtual override {
        L1CustomGateway.initialize(_l1Counterpart, _l1Router, _inbox, _owner);
    }

    function inboundEscrowTransfer(
        address _token,
        address _dest,
        uint256 _amount
    ) internal virtual override {
        IEthBridgedToken(_token).bridgeMint(_dest, _amount);
    }

    function outboundEscrowTransfer(
        address _token,
        address _from,
        uint256 _amount
    ) internal virtual override returns (uint256 amountBurnt) {
        // burns L1 tokens in order to transfer L1 -> L2
        IEthBridgedToken(_token).bridgeBurn(_from, _amount);
        return _amount;
    }
}