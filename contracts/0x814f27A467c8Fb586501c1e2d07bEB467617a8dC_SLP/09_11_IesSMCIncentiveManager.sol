// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

interface IesSMCIncentiveManager {
    function registerSLPDeposit(address _provider, uint256 _amountUSDT, uint256 _timestamp, uint256 _amountSLP) external;
    function registerSLPWithdrawal(address _provider, uint256 _amountUSDT, uint256 _timestamp, uint256 _amountSLP) external;
}