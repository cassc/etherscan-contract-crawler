// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;

pragma experimental ABIEncoderV2;

import { IAaveV2LendingPoolAddressesProvider } from "./IAaveV2LendingPoolAddressesProvider.sol";

struct TokenData {
    string symbol;
    address tokenAddress;
}

struct ReserveConfigurationData {
    uint256 decimals;
    uint256 ltv;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    uint256 reserveFactor;
    bool usageAsCollateralEnabled;
    bool borrowingEnabled;
    bool stableBorrowRateEnabled;
    bool isActive;
    bool isFrozen;
}

struct ReserveDataProtocol {
    uint256 availableLiquidity;
    uint256 totalStableDebt;
    uint256 totalVariableDebt;
    uint256 liquidityRate;
    uint256 variableBorrowRate;
    uint256 stableBorrowRate;
    uint256 averageStableBorrowRate;
    uint256 liquidityIndex;
    uint256 variableBorrowIndex;
    uint40 lastUpdateTimestamp;
}

struct UserReserveData {
    uint256 currentATokenBalance;
    uint256 currentStableDebt;
    uint256 currentVariableDebt;
    uint256 principalStableDebt;
    uint256 scaledVariableDebt;
    uint256 stableBorrowRate;
    uint256 liquidityRate;
    uint40 stableRateLastUpdated;
    bool usageAsCollateralEnabled;
}

struct ReserveTokensAddresses {
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
}

interface IAaveV2ProtocolDataProvider {
    // solhint-disable-next-line func-name-mixedcase
    function ADDRESSES_PROVIDER() external view returns (IAaveV2LendingPoolAddressesProvider);

    function getAllReservesTokens() external view returns (TokenData[] memory);

    function getAllATokens() external view returns (TokenData[] memory);

    function getReserveConfigurationData(address _asset) external view returns (ReserveConfigurationData memory);

    function getReserveData(address _asset) external view returns (ReserveDataProtocol memory);

    function getUserReserveData(address _asset, address _user) external view returns (UserReserveData memory);

    function getReserveTokensAddresses(address _asset) external view returns (ReserveTokensAddresses memory);
}