// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IGeneralVault {
  function pricePerShare() external view returns (uint256);

  function vaultYieldInPrice() external view returns (uint256);

  function withdrawOnLiquidation(address _asset, uint256 _amount) external returns (uint256);

  function convertOnLiquidation(address _assetOut, uint256 _amountIn) external;

  function processYield() external;

  function getYieldAmount() external view returns (uint256);

  function setTreasuryInfo(address _treasury, uint256 _fee) external;

  function depositCollateral(address _asset, uint256 _amount) external payable;

  function depositCollateralFrom(
    address _asset,
    uint256 _amount,
    address _user
  ) external payable;

  function withdrawCollateral(
    address _asset,
    uint256 _amount,
    uint256 _slippage,
    address _to
  ) external;
}