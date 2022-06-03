// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IDistributer.sol";

interface IDividendsDistributer is IDistributer {
  event SharesAdded(address to, uint256 shares);
  event SharesTransferred(address from, address to, uint256 shares);
  event SharesRemoved(address from, uint256 shares);

  /**
   * @dev Add shares to wallet
   */
  function addShares(address to, uint256 shares) external;

  /**
   * @dev Remove shares from wallet
   */
  function removeShares(address from, uint256 shares) external;

  /**
   * @dev Move shares from one to another
   */
  function transferShares(
    address from,
    address to,
    uint256 shares
  ) external;
}