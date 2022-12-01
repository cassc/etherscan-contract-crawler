// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../types/DataTypes.sol";

interface ILedger {

    function getProtocolConfig() external view returns (DataTypes.ProtocolConfig memory);

    function setProtocolConfig(DataTypes.ProtocolConfig memory config) external;

    function initAssetConfiguration(address asset) external returns (uint256 assetId);

    function setAssetConfiguration(address asset, DataTypes.AssetConfig memory configuration) external;

    function initReserve(address asset) external returns (uint256 poolId);

    function initCollateral(address asset, address reinvestment) external returns (uint256 poolId);

    function setReserveBonusPool(uint256 poolId, address newBonusPool) external;

    function setReserveReinvestment(uint256 poolId, address newReinvestment) external;

    function setReserveLongReinvestment(uint256 poolId, address newReinvestment) external;

    function setCollateralReinvestment(uint256 poolId, address newReinvestment) external;

    function setReserveConfiguration(uint256 poolId, DataTypes.ReserveConfiguration memory configuration) external;

    function setCollateralConfiguration(uint256 poolId, DataTypes.CollateralConfiguration memory configuration) external;

    function managePoolReinvestment(uint256 actionId, uint256 poolId) external;

    function getAssetConfiguration(address asset) external view returns (DataTypes.AssetConfig memory);

    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    function getCollateralData(address asset, address reinvestment) external view returns (DataTypes.CollateralData memory);

    function getReserveIndexes(address asset) external view returns (uint256, uint256, uint256);

    function reserveSupplies(address asset) external view returns (uint256, uint256, uint256, uint256, uint256);

    function collateralTotalSupply(address asset, address reinvestment) external view returns (uint256);

    function getUserLiquidity(address user) external view returns (DataTypes.UserLiquidity memory);

    function depositReserve(address asset, uint256 amount) external;
}