// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IBasketReader {
  /**
   * @notice Underlying token that is kept in this Basket
   */
  function underlying() external view returns (address);

  /**
   * @notice Given a target price, what is the basket factor
   * @param targetPriceInUnderlying the current target price to calculate the
   * basket factor for in the units of the underlying token.
   */
  function getBasketFactor(uint256 targetPriceInUnderlying)
    external
    view
    returns (uint256 basketFactor);
}