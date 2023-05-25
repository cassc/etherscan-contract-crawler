// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "../libraries/BaseContract.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PausableFacet is
	Context,
	BaseContract
{
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _pause();
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused()
		public view virtual returns (bool)
	{
        return getState().paused;
    }

	function pause()
		public onlyOwner
	{
        _pause();
    }

    function unpause()
		public onlyOwner
	{
        _unpause();
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause()
		internal virtual whenNotPaused
	{
        getState().paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause()
		internal virtual whenPaused
	{
        getState().paused = false;
        emit Unpaused(_msgSender());
    }
}