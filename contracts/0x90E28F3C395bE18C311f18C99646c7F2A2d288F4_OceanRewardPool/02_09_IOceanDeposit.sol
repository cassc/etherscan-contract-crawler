// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IOceanDeposit {
    function deposit(uint256, bool) external;

    function lockIncentive() external view returns (uint256);
}