// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBank {
  event SharesClaimed(address account, uint256 amount);
  event DividendsClaimed(address account, uint256 amount);
  event ERC20Burned(uint256 amount);

  /**
   * @dev Make payment
   */
  function makePayment(address from, uint256 amount) external;

  /**
   * @dev Distribute Shares
   */
  function distribute(uint256 amount) external;

  /**
   * @dev Transfer ERC20
   */
  function transfer(
    address from,
    address to,
    uint256 amount
  ) external;

  /**
   * @dev Claim your shares
   */
    function claimShares() external;

  /**
   * @dev Claim your dividends
   */
  function claimDividends() external;
}