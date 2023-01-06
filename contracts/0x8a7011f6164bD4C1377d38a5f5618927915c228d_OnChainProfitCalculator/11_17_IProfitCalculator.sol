// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ProfitCalculatorDrawingContract{
  struct ProfitCalculator {
      uint256 totalNumberSales;
      uint256 totalBalance;
      uint256 totalGasCost;
      uint256 totalCost;
      uint256 totalProfit;
      int256 potentialTotalProfit;

      uint256 tokenId;
      string holder;

      string numberBought;
      string numberRemaining;
      string realizedProfit;
      string unrealizedProfit;
      string stringPotentialTotalProfit;
      string stringTotalCost;
      string returnRate;
  }
  function image(ProfitCalculator memory pc) public virtual view returns (string memory);
}