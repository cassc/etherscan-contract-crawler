// SPDX-License-Identifier: MIT
// DIVI TBD

pragma solidity ^0.8.7;

import "../token/IERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy their own
 * tokens, mint token amount for arbitrary address, pause and unpause token 
 * trnasfers, in a way that can be recognized off-chain (via event analysis).
 */
abstract contract IDivi is IERC20 {
	/**
	 * @dev Triggers stopped state.
	 *
	 * - The contract must not be paused.
	 */
	function pause() external virtual;

	/**
	 * @dev Returns to normal state.
	 *
	 * - The contract must be paused.
	 */
	function unpause() external virtual;

	/**
	 * @dev Destroys `amount` tokens from the caller.
	 *
	 * - See {ERC20-_burn}.
	 */
	function burn(uint256 amount) external virtual;

	/**
	 * @dev Creates `amount` tokens for `account`.
	 *
	 * - See {ERC20-_mint}.
	 */
	function mint(address account, uint256 amount) external virtual;
}