// SPDX-License-Identifier: MIT
/*
 * Pausable.sol
 *
 * Created: December 21, 2021
 *
 * Provides functionality for pausing and unpausing the sale (or other functionality)
 */

pragma solidity >=0.5.16 <0.9.0;

import "./SquadOwnable.sol";

//@title Pausable
//@author Jack Kasbeer (gh:@jcksber, tw:@satoshigoat, ig:overprivilegd)
contract Pausable is SquadOwnable {

	event Paused(address indexed a);
	event Unpaused(address indexed a);

	bool private _paused;

	constructor() {
		_paused = false;
	}

	//@dev This will require the sale to be unpaused
	modifier saleActive()
	{
		require(!_paused, "Pausable: sale paused.");
		_;
	}

	//@dev Pause or unpause minting
	function toggleSaleActive() external isSquad
	{
		_paused = !_paused;

		if (_paused) {
			emit Paused(_msgSender());
		} else {
			emit Unpaused(_msgSender());
		}
	}

	//@dev Determine if the sale is currently paused
	function isPaused() public view virtual returns (bool)
	{
		return _paused;
	}
}