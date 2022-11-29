// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import {IERC20Metadata} from "ERC20.sol";
import {IERC20Upgradeable, IERC20MetadataUpgradeable} from "IERC20MetadataUpgradeable.sol";

interface IERC4626 is IERC20Upgradeable, IERC20MetadataUpgradeable {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);

    function asset() external view returns (IERC20Metadata asset);

    function totalAssets() external view returns (uint256 totalManagedAssets);

    function convertToShares(uint256 assets) external view returns (uint256 shares);

    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function maxWithdraw(address owner) external view returns (uint256);

    function previewWithdraw(uint256 assets) external view returns (uint256);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256);

    function maxRedeem(address owner) external view returns (uint256);

    function maxDeposit(address receiver) external view returns (uint256);

    function maxMint(address receiver) external view returns (uint256);

    function previewMint(uint256 shares) external view returns (uint256);

    function previewRedeem(uint256 shares) external view returns (uint256);

    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    function mint(uint256 shares, address receiver) external returns (uint256 assets);
}