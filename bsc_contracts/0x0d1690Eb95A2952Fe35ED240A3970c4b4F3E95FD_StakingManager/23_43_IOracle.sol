// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOracle {
    function getNativeTokenPrice(uint256 amount) external view returns (uint256);

    function getTokenPrice(address token, uint256 amount) external view returns (uint256);

    function getTokenUSDPrice(address token, uint256 amount) external view returns (uint256);
}