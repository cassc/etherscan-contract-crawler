// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IStrategyVault {
    function totalSupply() external view returns (uint256);

    function deposit(uint256 assets_, address receiver_) external returns (uint256 shares_);

    function withdraw(uint256 assets_, address receiver_, address owner_) external returns (uint256 shares_);

    function mint(uint256 shares_, address receiver_) external returns (uint256 assets_);

    function redeem(uint256 shares_, address receiver_, address owner_) external returns (uint256 assetsAfterFee_);

    function getWithdrawFee(uint256 _amount) external view returns (uint256 amount);
}