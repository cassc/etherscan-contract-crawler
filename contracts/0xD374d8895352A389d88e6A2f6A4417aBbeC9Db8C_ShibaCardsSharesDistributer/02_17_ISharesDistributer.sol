// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IDistributer.sol";

interface ISharesDistributer is IDistributer {
  /**
   * @dev Move shares from one to another
   */
  function moveShares(
    address from,
    address to,
    uint256 shares
  ) external;
}