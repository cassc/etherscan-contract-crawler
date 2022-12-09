// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

interface IInterestCalculator {
  /**
   * @dev Calculates interest per second that is int 1e18
   * @param maturity duration of the bond in seconds
   * @param interest per second
   * @return simple interest per second that is int 1e18
   */
  function simpleInterest(uint256 interest, uint256 maturity) external view returns (uint256);
}