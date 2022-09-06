// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract PausableMint is Pausable, Ownable {
	/*
	 * Pause util functions
	 */
	function pauseMint() external onlyOwner {
		_pause();
	}

	function unpauseMint() external onlyOwner {
		_unpause();
	}
}