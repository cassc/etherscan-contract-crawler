// SPDX-License-Identifier: MIT

/**
 *
 * @title IArrngConsumer.sol. Use arrng
 *
 * @author arrng https://arrng.xyz/
 *
 */

pragma solidity 0.8.19;

interface IArrngConsumer {
  /**
   *
   * @dev avast: receive RNG
   *
   * @param skirmishID_: unique ID for this request
   * @param barrelORum_: array of random integers requested
   *
   */
  function yarrrr(
    uint256 skirmishID_,
    uint256[] memory barrelORum_
  ) external payable;
}