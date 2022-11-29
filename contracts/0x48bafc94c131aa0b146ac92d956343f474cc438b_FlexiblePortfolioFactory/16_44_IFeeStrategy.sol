// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IFeeStrategy {
    function managerFeeRate() external view returns (uint256);
}