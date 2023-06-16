// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

interface IXUSDPool {
    function collatDollarBalance() external view returns (uint256);
    function availableExcessCollatDV() external view returns (uint256);
    function getCollateralPrice() external view returns (uint256);
}