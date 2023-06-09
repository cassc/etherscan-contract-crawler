/*
    Copyright 2021 Babylon Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IVoteToken {
    function delegate(address delegatee) external;

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool prefix
    ) external;

    function getCurrentVotes(address account) external view returns (uint96);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);

    function getMyDelegatee() external view returns (address);

    function getDelegatee(address account) external view returns (address);

    function getCheckpoints(address account, uint32 id) external view returns (uint32 fromBlock, uint96 votes);

    function getNumberOfCheckpoints(address account) external view returns (uint32);
}

interface IVoteTokenWithERC20 is IVoteToken, IERC20 {}