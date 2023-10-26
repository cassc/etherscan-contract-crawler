// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ICompoundV3 {
    function getUtilization() external view returns (uint);

    function getSupplyRate(uint256) external view returns (uint64);

    function getBorrowRate(uint256) external view returns (uint64);

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
    function getAssetInfo(uint8 i) external view returns (AssetInfo memory);

    function userCollateral(address,address) external view returns (uint128, uint128);

    function baseTokenPriceFeed() external view returns (address);
    
    function borrowBalanceOf(address) external view returns (uint256);
    
    function decimals() external view returns (uint8);

    function numAssets() external view returns (uint8);
}

interface IPriceFeed {
    struct RoundData {
        uint80 roundId;
        int256 answer; // (price)
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }
    function latestRoundData() external view returns (RoundData memory);

    function decimals() external view returns (uint8);
}

interface IERC20 {
    function decimals() external view returns (uint8);
}


contract CompoundV3Helper {
    uint256 public constant SECONDS_PER_YEAR = 31536000; // 60 * 60 * 24 * 365

    function getCompoundV3SupplyAPR(address market) public view returns (uint256) {
        uint utilization = ICompoundV3(market).getUtilization();
        uint64 supplyRate = ICompoundV3(market).getSupplyRate(utilization);
        uint256 supplyApr = supplyRate * SECONDS_PER_YEAR * 100;

        return supplyApr;
    }

    function getCompoundV3BorrowAPR(address market) public view returns (uint256) {
        uint utilization = ICompoundV3(market).getUtilization();
        uint64 borrowRate = ICompoundV3(market).getBorrowRate(utilization);
        uint256 borrowApr = borrowRate * SECONDS_PER_YEAR * 100;

        return borrowApr;
    }

    function getCompoundV3AccountLiquidity(address market, address account) public view returns (uint256) {
        uint8 numAssets = ICompoundV3(market).numAssets();
        uint256 userColleteral = 0;

        for (uint8 i = 0; i < numAssets; i++) {
            ICompoundV3.AssetInfo memory assetInfo = ICompoundV3(market).getAssetInfo(i);
            (uint128 collateralBalance, ) = ICompoundV3(market).userCollateral(account, assetInfo.asset);

            if (collateralBalance > 0) {
                IPriceFeed.RoundData memory roundData = IPriceFeed(assetInfo.priceFeed).latestRoundData();
                uint8 assetDecimals = IERC20(assetInfo.asset).decimals();
                uint8 priceFeedDecimals = IPriceFeed(assetInfo.priceFeed).decimals();

                uint256 collateralValue = uint256(collateralBalance) * 
                                          uint256(roundData.answer) * 
                                          uint256(assetInfo.liquidateCollateralFactor) * 
                                          (10 ** ((18 - priceFeedDecimals) + (18 - assetDecimals)));
                userColleteral += collateralValue;
            }
        }

        uint256 userBaseBalance = ICompoundV3(market).borrowBalanceOf(account);
        address basePriceFeed = ICompoundV3(market).baseTokenPriceFeed();
        uint256 basePrice = uint256(IPriceFeed(basePriceFeed).latestRoundData().answer);
        uint8 basePriceFeedDecimals = IPriceFeed(basePriceFeed).decimals();
        uint8 baseTokenDecimals = IERC20(market).decimals();

        uint256 userBaseBalanceUsd = userBaseBalance * 
                                     basePrice * 
                                     (10 ** (18 + (18 - basePriceFeedDecimals) + (18 - baseTokenDecimals)));

        // This number need to be divided by 10 ** 54
        return userColleteral - userBaseBalanceUsd;
    }
}