// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

struct AssetInfo {
    uint8 offset;
    address asset;
    address priceFeed;
    uint64 scale;
    uint64 borrowCollateralFactor;
    uint64 liquidateCollateralFactor;
    uint64 liquidationFactor;
    uint128 supplyCap;
}

struct RewardConfig {
    address token;
    uint64 rescaleFactor;
    bool shouldUpscale;
}

struct RewardOwed {
    address token;
    uint256 owed;
}

struct AssetConfig {
    address asset;
    address priceFeed;
    uint8 decimals;
    uint64 borrowCollateralFactor;
    uint64 liquidateCollateralFactor;
    uint64 liquidationFactor;
    uint128 supplyCap;
}

struct Configuration {
    address governor;
    address pauseGuardian;
    address baseToken;
    address baseTokenPriceFeed;
    address extensionDelegate;
    uint64 supplyKink;
    uint64 supplyPerYearInterestRateSlopeLow;
    uint64 supplyPerYearInterestRateSlopeHigh;
    uint64 supplyPerYearInterestRateBase;
    uint64 borrowKink;
    uint64 borrowPerYearInterestRateSlopeLow;
    uint64 borrowPerYearInterestRateSlopeHigh;
    uint64 borrowPerYearInterestRateBase;
    uint64 storeFrontPriceFactor;
    uint64 trackingIndexScale;
    uint64 baseTrackingSupplySpeed;
    uint64 baseTrackingBorrowSpeed;
    uint104 baseMinForRewards;
    uint104 baseBorrowMin;
    uint104 targetReserves;
    AssetConfig[] assetConfigs;
}

struct TotalsBasic {
    // 1st slot
    uint64 baseSupplyIndex;
    uint64 baseBorrowIndex;
    uint64 trackingSupplyIndex;
    uint64 trackingBorrowIndex;
    // 2nd slot
    uint104 totalSupplyBase;
    uint104 totalBorrowBase;
    uint40 lastAccrualTime;
    uint8 pauseFlags;
}

struct TotalsCollateral {
    uint128 totalSupplyAsset;
    uint128 _reserved;
}

struct UserBasic {
    int104 principal;
    uint64 baseTrackingIndex;
    uint64 baseTrackingAccrued;
    uint16 assetsIn;
    uint8 _reserved;
}

struct UserCollateral {
    uint128 balance;
    uint128 _reserved;
}

interface IComet {
    function getAssetInfo(uint8 i) external view returns (AssetInfo memory);

    function getAssetInfoByAddress(address asset) external view returns (AssetInfo memory);

    function getSupplyRate(uint256 utilization) external view returns (uint64);

    function getBorrowRate(uint256 utilization) external view returns (uint64);

    function getUtilization() external view returns (uint64);

    function getPrice(address priceFeed) external view returns (uint256);

    function getReserves() external view returns (int256);

    function isBorrowCollateralized(address account) external view returns (bool);

    function isLiquidatable(address account) external view returns (bool);

    function isSupplyPaused() external view returns (bool);

    function isTransferPaused() external view returns (bool);

    function isWithdrawPaused() external view returns (bool);

    function isAbsorbPaused() external view returns (bool);

    function isBuyPaused() external view returns (bool);

    function quoteCollateral(address asset, uint256 baseAmount) external view returns (uint256);

    function totalSupply() external view returns (uint104);

    function totalBorrow() external view returns (uint104);

    function balanceOf(address account) external view returns (uint256);

    function baseBalanceOf(address account) external view returns (int104);

    function borrowBalanceOf(address account) external view returns (uint256);

    function targetReserves() external view returns (uint104);

    function numAssets() external view returns (uint8);

    function decimals() external view returns (uint8);

    function initializeStorage() external;

    function baseScale() external view returns (uint64);

    /// @dev uint64
    function trackingIndexScale() external view returns (uint64);

    /// @dev uint64
    function baseTrackingSupplySpeed() external view returns (uint64);

    /// @dev uint64
    function baseTrackingBorrowSpeed() external view returns (uint64);

    /// @dev uint104
    function baseMinForRewards() external view returns (uint104);

    /// @dev uint104
    function baseBorrowMin() external view returns (uint104);

    /// @dev uint64
    function supplyKink() external view returns (uint64);

    /// @dev uint64
    function supplyPerSecondInterestRateSlopeLow() external view returns (uint64);

    /// @dev uint64
    function supplyPerSecondInterestRateSlopeHigh() external view returns (uint64);

    /// @dev uint64
    function supplyPerSecondInterestRateBase() external view returns (uint64);

    /// @dev uint64
    function borrowKink() external view returns (uint64);

    /// @dev uint64
    function borrowPerSecondInterestRateSlopeLow() external view returns (uint64);

    /// @dev uint64
    function borrowPerSecondInterestRateSlopeHigh() external view returns (uint64);

    /// @dev uint64
    function borrowPerSecondInterestRateBase() external view returns (uint64);

    /// @dev uint64
    function storeFrontPriceFactor() external view returns (uint64);

    function baseToken() external view returns (address);

    function baseTokenPriceFeed() external view returns (address);

    function collateralBalanceOf(address account, address asset) external view returns (uint128);

    // total accrued base rewards for an account
    function baseTrackingAccrued(address account) external view returns (uint64);

    function baseAccrualScale() external view returns (uint64);

    function baseIndexScale() external view returns (uint64);

    function factorScale() external view returns (uint64);

    function priceScale() external view returns (uint64);

    function maxAssets() external view returns (uint8);

    function totalsBasic() external view returns (TotalsBasic memory);

    function totalsCollateral(address) external view returns (TotalsCollateral memory);

    function userNonce(address) external returns (uint256);

    function userBasic(address) external returns (UserBasic memory);

    function userCollateral(address, address) external returns (UserCollateral memory);
}

interface TokenInterface {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface ICometRewards {
    function getRewardOwed(address comet, address account) external returns (RewardOwed memory);

    function rewardConfig(address cometProxy) external view returns (RewardConfig memory);

    function rewardsClaimed(address cometProxy, address account) external view returns (uint256);
}

interface ICometConfig {
    function getAssetIndex(address cometProxy, address asset) external view returns (uint256);

    function getConfiguration(address cometProxy) external view returns (Configuration memory);
}