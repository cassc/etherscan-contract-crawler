// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @dev All factors or APYs are written as a number with mantissa 18.
struct AssetMetadata {
    address assetAddress;
    string assetSymbol;
    uint8 assetDecimals;
    uint256 referencePrice;
    uint256 totalLiquidity;
    uint256 totalSupply;
    uint256 totalBorrow;
    uint256 totalReserves;
    uint256 supplyAPR;
    uint256 borrowAPR;
    address rewardTokenAddress;
    string rewardTokenSymbol;
    uint8 rewardTokenDecimals;
    uint256 estimatedSupplyRewardsPerYear;
    uint256 estimatedBorrowRewardsPerYear;
    uint256 collateralFactor;
    uint256 liquidationFactor;
    bool canSupply;
    bool canBorrow;
}

interface ILendingPlatform {
    function getAssetMetadata(address platform, address asset) external returns (AssetMetadata memory assetMetadata);

    function getCollateralUsageFactor(address platform) external returns (uint256 collateralUsageFactor);

    function getCollateralFactorForAsset(address platform, address asset) external returns (uint256);

    function getReferencePrice(address platform, address token) external returns (uint256 referencePrice);

    function getBorrowBalance(address platform, address token) external returns (uint256 borrowBalance);

    function getSupplyBalance(address platform, address token) external returns (uint256 supplyBalance);

    function claimRewards(address platform) external returns (address rewardsToken, uint256 rewardsAmount);

    function enterMarkets(address platform, address[] memory markets) external;

    function supply(
        address platform,
        address token,
        uint256 amount
    ) external;

    function borrow(
        address platform,
        address token,
        uint256 amount
    ) external;

    function redeemSupply(
        address platform,
        address token,
        uint256 amount
    ) external;

    function repayBorrow(
        address platform,
        address token,
        uint256 amount
    ) external;
}