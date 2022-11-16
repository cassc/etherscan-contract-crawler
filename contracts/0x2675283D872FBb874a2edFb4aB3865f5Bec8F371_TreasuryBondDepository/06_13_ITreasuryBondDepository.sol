// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IBondDepositoryCommon.sol";

interface ITreasuryBondDepository is IBondDepositoryCommon {
  function purchase(
    uint256 amount,
    uint256 maxPrice,
    address recipient
  ) external returns (uint256 bondId);

  function currentDebt() external view returns (uint256 debt);

  function debtDecay() external view returns (uint256 decay);

  function debtRatio() external view returns (uint256 ratio);

  function setFeeCollector(address dao) external;

  function calculateBondPrice(
    uint256 controlVariable,
    uint256 minimumPrice,
    uint256 ratio
  ) external view returns (uint256 price);

  event UpdatedFeeCollector(address dao);
  event RedeemPaused(bool indexed isPaused);
  event PurchasePaused(bool indexed isPaused);
}