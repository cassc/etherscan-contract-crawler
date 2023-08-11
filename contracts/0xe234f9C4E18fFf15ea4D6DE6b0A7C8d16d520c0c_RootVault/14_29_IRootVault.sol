// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IRootVault is IERC20Metadata {
    function asset() external view returns (address);

    function recomputePricePerTokenAndHarvestFee() external;

    function totalAssets() external view returns (uint256);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function pricePerToken() external view returns (uint256);

    function feeInclusivePricePerToken() external view returns (uint256);

    function vaultsLength() external view returns (uint256);

    function getVault(uint256 index) external view returns (address);

    function totalPortfolioScore() external view returns (uint256);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function redeem(uint256 shares, address receiver) external returns (uint256 assets);

    function computeScoreDeviationInPpm(address vaultAddress) external view returns (int256);

    function rebalance(address sourceVaultAddress, address destinationVaultAddress, uint256 shares) external;

    function previewRedeem(uint256 shares) external returns (uint256 assets);
}