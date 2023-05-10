// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IDistribution {
    function getSplits() external view returns (uint256, uint256, uint256, uint256);
}