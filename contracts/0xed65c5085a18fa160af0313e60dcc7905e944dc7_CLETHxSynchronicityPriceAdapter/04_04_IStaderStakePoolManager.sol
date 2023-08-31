// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IStaderStakePoolManager {
    function getExchangeRate() external view returns (uint256);
}