// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IDepositController {
    function onDeposit(
        address sender,
        uint256 amount,
        address receiver
    ) external returns (uint256, uint256);

    function onMint(
        address sender,
        uint256 amount,
        address receiver
    ) external returns (uint256, uint256);

    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    function previewMint(uint256 shares) external view returns (uint256 assets);

    function maxDeposit(address sender) external view returns (uint256 assets);

    function maxMint(address sender) external view returns (uint256 shares);
}