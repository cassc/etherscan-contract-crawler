// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20MintableBurnable is IERC20 {
  /**
   * @dev Destroys `amount` tokens from the caller.
   */
  function burn(uint256 amount) external;

  /**
   * @dev Destroys `amount` tokens from `account`, deducting from 
   * the caller's allowance.
   */
  function burnFrom(address account, uint256 amount) external;

  /**
   * @dev Creates `amount` new tokens for `to`.
   */
  function mint(address to, uint256 amount) external;
}