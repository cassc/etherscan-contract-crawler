// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISupplyControlledERC20 is IERC20 {
  /**
   * @dev Creates `amount` new tokens for `to`.
   *
   * See {ERC20-_mint}.
   *
   * Requirements:
   * - the caller must have the `MINTER_ROLE`.
   */
  function mint(address to, uint256 amount) external;

  /**
   * @dev Destroys `amount` tokens from the caller.
   *
   * See {ERC20-_burn}.
   */
  function burn(uint256 amount) external;

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * See {ERC20-_burn}.
   */
  function burnFrom(address account, uint256 amount) external;
}