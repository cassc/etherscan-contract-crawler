// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable is IERC20 {
  /**
   * @dev Creates `amount` new tokens for `to`.
   */
  function mint(address to, uint256 amount) external;
}