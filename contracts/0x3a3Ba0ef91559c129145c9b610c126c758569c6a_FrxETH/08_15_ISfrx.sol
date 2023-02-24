// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISfrx {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    function totalAssets() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}