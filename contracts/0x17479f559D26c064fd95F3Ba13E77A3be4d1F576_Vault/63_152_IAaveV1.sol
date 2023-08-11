// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;
pragma experimental ABIEncoderV2;

struct UserReserveData {
    uint256 currentATokenBalance;
    uint256 currentBorrowBalance;
    uint256 principalBorrowBalance;
    uint256 borrowRateMode;
    uint256 borrowRate;
    uint256 liquidityRate;
    uint256 originationFee;
    uint256 variableBorrowIndex;
    uint256 lastUpdateTimestamp;
    bool enabled;
}

struct UserAccountData {
    uint256 totalLiquidityETH;
    uint256 totalCollateralETH;
    uint256 totalBorrowsETH;
    uint256 totalFeesETH;
    uint256 availableBorrowsETH;
    uint256 currentLiquidationThreshold;
    uint256 ltv;
    uint256 healthFactor;
}

struct ReserveDataV1 {
    uint256 totalLiquidity;
    uint256 availableLiquidity;
    uint256 totalBorrowsStable;
    uint256 totalBorrowsVariable;
    uint256 liquidityRate;
    uint256 variableBorrowRate;
    uint256 stableBorrowRate;
    uint256 averageStableBorrowRate;
    uint256 utilizationRate;
    uint256 liquidityIndex;
    uint256 variableBorrowIndex;
    address aTokenAddress;
    uint40 lastUpdateTimestamp;
}

struct ReserveConfigurationData {
    uint256 ltv;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    address rateStrategyAddress;
    bool usageAsCollateralEnabled;
    bool borrowingEnabled;
    bool stableBorrowRateEnabled;
    bool isActive;
}

interface IAaveV1 {
    function deposit(
        address _reserve,
        uint256 _amount,
        uint16 _referralCode
    ) external;

    function setUserUseReserveAsCollateral(address _reserve, bool _useAsCollateral) external;

    function borrow(
        address _reserve,
        uint256 _amount,
        uint256 _interestRateMode,
        uint16 _referralCode
    ) external;

    function repay(
        address _reserve,
        uint256 _amount,
        address payable _onBehalfOf
    ) external;

    function getReserveConfigurationData(address _reserve) external view returns (ReserveConfigurationData memory);

    function getUserAccountData(address _user) external view returns (UserAccountData memory);

    function getUserReserveData(address _reserve, address _user) external view returns (UserReserveData memory);

    function getReserveData(address _reserve) external view returns (ReserveDataV1 memory);
}