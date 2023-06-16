// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

interface IMonetaryPolicy {
  /**
   * @notice Consult the monetary policy for the target price in eth
   */
  function consult() external view returns (uint256 targetPriceInEth);

  /**
   * @notice Update the Target price given the auction results.
   * @dev 0 values are used to indicate missing data.
   */
  function updateGivenAuctionResults(
    uint256 round,
    uint256 lastAuctionBlock,
    uint256 floatMarketPrice,
    uint256 basketFactor
  ) external returns (uint256 targetPriceInEth);
}