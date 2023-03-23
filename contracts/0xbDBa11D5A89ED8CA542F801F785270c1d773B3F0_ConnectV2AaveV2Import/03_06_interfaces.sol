//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface AaveInterface {
    function deposit(address _asset, uint256 _amount, address _onBehalfOf, uint16 _referralCode) external;
    function withdraw(address _asset, uint256 _amount, address _to) external;
    function borrow(
        address _asset,
        uint256 _amount,
        uint256 _interestRateMode,
        uint16 _referralCode,
        address _onBehalfOf
    ) external;
    function repay(address _asset, uint256 _amount, uint256 _rateMode, address _onBehalfOf) external;
    function setUserUseReserveAsCollateral(address _asset, bool _useAsCollateral) external;
    function getUserAccountData(address user) external view returns (
        uint256 totalCollateralETH,
        uint256 totalDebtETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    );
}

interface AaveLendingPoolProviderInterface {
    function getLendingPool() external view returns (address);
}

// Aave Protocol Data Provider
interface AaveDataProviderInterface {
    function getUserReserveData(address _asset, address _user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled
    );
    function getReserveConfigurationData(address asset) external view returns (
        uint256 decimals,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        uint256 reserveFactor,
        bool usageAsCollateralEnabled,
        bool borrowingEnabled,
        bool stableBorrowRateEnabled,
        bool isActive,
        bool isFrozen
    );

    function getReserveTokensAddresses(address asset) external view returns (
        address aTokenAddress,
        address stableDebtTokenAddress,
        address variableDebtTokenAddress
    );
}

interface AaveAddressProviderRegistryInterface {
    function getAddressesProvidersList() external view returns (address[] memory);
}

interface ATokenInterface {
    function scaledBalanceOf(address _user) external view returns (uint256);
    function isTransferAllowed(address _user, uint256 _amount) external view returns (bool);
    function balanceOf(address _user) external view returns(uint256);
    function transferFrom(address, address, uint) external returns (bool);
    function allowance(address, address) external returns (uint256);
}