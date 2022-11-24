// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library CometStructs {
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

    struct UserBasic {
        int104 principal;
        uint64 baseTrackingIndex;
        uint64 baseTrackingAccrued;
        uint16 assetsIn;
        uint8 _reserved;
    }

    struct TotalsBasic {
        uint64 baseSupplyIndex;
        uint64 baseBorrowIndex;
        uint64 trackingSupplyIndex;
        uint64 trackingBorrowIndex;
        uint104 totalSupplyBase;
        uint104 totalBorrowBase;
        uint40 lastAccrualTime;
        uint8 pauseFlags;
    }

    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    struct RewardOwed {
        address token;
        uint owed;
    }

    struct TotalsCollateral {
        uint128 totalSupplyAsset;
        uint128 _reserved;
    }

    struct RewardConfig {
        address token;
        uint64 rescaleFactor;
        bool shouldUpscale;
    }
}

interface Comet is IERC20 {
    function baseScale() external view returns (uint);

    function supply(address asset, uint amount) external;

    function supplyTo(address to, address asset, uint amount) external;

    function withdraw(address asset, uint amount) external;

    function getSupplyRate(uint utilization) external view returns (uint);

    function getBorrowRate(uint utilization) external view returns (uint);

    function getAssetInfoByAddress(
        address asset
    ) external view returns (CometStructs.AssetInfo memory);

    function getAssetInfo(
        uint8 i
    ) external view returns (CometStructs.AssetInfo memory);

    function borrowBalanceOf(address account) external view returns (uint256);

    function getPrice(address priceFeed) external view returns (uint128);

    function userBasic(
        address
    ) external view returns (CometStructs.UserBasic memory);

    function totalsBasic()
        external
        view
        returns (CometStructs.TotalsBasic memory);

    function userCollateral(
        address,
        address
    ) external view returns (CometStructs.UserCollateral memory);

    function baseTokenPriceFeed() external view returns (address);

    function numAssets() external view returns (uint8);

    function getUtilization() external view returns (uint);

    function baseTrackingSupplySpeed() external view returns (uint);

    function baseTrackingBorrowSpeed() external view returns (uint);

    function totalSupply() external view override returns (uint256);

    function totalBorrow() external view returns (uint256);

    function baseIndexScale() external pure returns (uint64);

    function baseTrackingAccrued(
        address account
    ) external view returns (uint64);

    function totalsCollateral(
        address asset
    ) external view returns (CometStructs.TotalsCollateral memory);

    function baseMinForRewards() external view returns (uint256);

    function baseToken() external view returns (address);

    function accrueAccount(address account) external;

    function isLiquidatable(address _address) external view returns (bool);

    function baseBorrowMin() external view returns (uint256);
}

interface CometRewards {
    function getRewardOwed(
        address comet,
        address account
    ) external returns (CometStructs.RewardOwed memory);

    function claim(address comet, address src, bool shouldAccrue) external;

    function rewardsClaimed(
        address comet,
        address account
    ) external view returns (uint256);

    function rewardConfig(
        address comet
    ) external view returns (CometStructs.RewardConfig memory);
}