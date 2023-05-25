// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

interface IEthUsdOracle {
  /**
   * @notice Spot price
   * @return price The latest price as an [e27]
   */
  function consult() external view returns (uint256 price);
}