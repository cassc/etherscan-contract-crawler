// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import "./RollOwned.sol";

// https://docs.synthetix.io/contracts/Pausable
abstract contract RollPausable is RollOwned {
	uint256 public lastPauseTime;
	bool public paused;

	constructor() {
		// This contract is abstract, and thus cannot be instantiated directly
		require(owner != address(0), "Owner must be set");
		// Paused will be false, and lastPauseTime will be 0 upon initialisation
	}

	/**
	 * @notice Change the paused state of the contract
	 * @dev Only the contract owner may call this.
	 */
	function setPaused(bool _paused) external onlyOwner {
		// Ensure we're actually changing the state before we do anything
		if (_paused == paused) {
			return;
		}

		// Set our paused state.
		paused = _paused;

		// If applicable, set the last pause time.
		if (_paused) {
			lastPauseTime = block.timestamp;
		}

		// Let everyone know that our pause state has changed.
		emit PauseChanged(_paused);
	}

	event PauseChanged(bool isPaused);

	modifier notPaused {
		_notPaused();
		_;
	}

	function _notPaused() private view {
		require(
			!paused,
			"This action cannot be performed while the contract is paused"
		);
	}
}