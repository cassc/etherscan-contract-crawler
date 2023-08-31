// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface ILybra {
    function totalDepositedAsset() external view returns (uint256);
    function safeCollateralRatio() external view returns (uint256);
    function depositedAsset(address user) external view returns (uint256);
    function getBorrowedOf(address user) external view returns (uint256);
    function getVaultType() external view returns (uint8);
    function totaldepositedAsset() external view returns (uint256);
    function getPoolTotalCirculation() external view returns (uint256);
    function getAssetPrice() external view returns (uint256);
    function getAsset() external view returns (address);
    function getAsset2EtherExchangeRate() external view returns (uint256);
    function burn(address onBehalfOf, uint256 amount) external;
}