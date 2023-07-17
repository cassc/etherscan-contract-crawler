// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

interface INodeRewards {
    function totalNodeStaked() external view returns (uint256);
}