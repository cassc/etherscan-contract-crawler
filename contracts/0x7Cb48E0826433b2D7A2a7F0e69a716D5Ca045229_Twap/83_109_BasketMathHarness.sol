// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../BasketMath.sol";

contract BasketMathHarness {
  function _calcBasketFactor(
    uint256 targetPriceInEth,
    uint256 ethStored,
    uint256 floatSupply,
    uint256 targetRatio
  ) external pure returns (uint256 basketFactor) {
    return
      BasketMath.calcBasketFactor(
        targetPriceInEth,
        ethStored,
        floatSupply,
        targetRatio
      );
  }
}