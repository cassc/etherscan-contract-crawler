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

interface IEthBridgedToken {
    /**
     * @notice should increase token supply by amount, and should only be callable by the L2 bridge.
     */
    function bridgeMint(address account, uint256 amount) external;

    /**
     * @notice should decrease token supply by amount, and should only be callable by the L2 bridge.
     */
    function bridgeBurn(address account, uint256 amount) external;

    /**
     * @return address of layer 2 token
     */
    function l2Address() external view returns (address);
}