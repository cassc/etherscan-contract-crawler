// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEthLeverage {
    function deposit(uint256 assets, address receiver) external payable returns (uint256 shares);

    function withdraw(uint256 assets, address receiver) external returns (uint256 shares);

    function totalAssets() external view returns (uint256);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function withdrawSlippage() external view returns (uint256);
}