// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity >=0.8.0;

/**
 * @title L1gatewayRouter for native-arbitrum
 */
interface L1GatewayRouter {
    /**
     * @notice outbound function to bridge ERC20 via NativeArbitrum-Bridge
     * @param _token address of token being bridged via GatewayRouter
     * @param _to recipient of the token on arbitrum chain
     * @param _amount amount of ERC20 token being bridged
     * @param _maxGas a depositParameter for bridging the token
     * @param _gasPriceBid  a depositParameter for bridging the token
     * @param _data a depositParameter for bridging the token
     * @return calldata returns the output of transactioncall made on gatewayRouter
     */
    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes calldata);
}