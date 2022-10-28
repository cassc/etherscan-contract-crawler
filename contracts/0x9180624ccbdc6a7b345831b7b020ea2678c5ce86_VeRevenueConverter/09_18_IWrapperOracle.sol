// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IWrapperOracle {
    function getUSDPrice(address token) external view returns (uint256 priceInWei);
}