// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IYieldsterVault {
    function tokenValueInUSD() external view returns (uint256);
}