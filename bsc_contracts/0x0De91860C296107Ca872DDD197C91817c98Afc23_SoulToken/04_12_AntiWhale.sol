// contracts/AntiWhale.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AntiWhale is Ownable {
	bool public isAntiWhaleEnabled = true;
	uint256 public maxTransferAmount = 500000 * 10**18; // 500k tokens

	/**
	 * @dev Checks if _amount is too high (whale).
	 *
	 * Returns if _amount of tokens being sent is higher than {maxTransferAmount}.
	 */
	function isWhale(uint256 _amount) public view returns (bool) {
		return isAntiWhaleEnabled && _amount > maxTransferAmount;
	}

	/**
	 * @dev Changes the status of the anti-whale system {isAntiWhaleEnabled} to {_status}
	 */
	function setAntiWhaleStatus(bool _status) external onlyOwner {
		isAntiWhaleEnabled = _status;
	}

	/**
	 * @dev Changes the maximum amount of tokens {maxTransferAmount} a wallet can send at once to {_maxTransferAmount}
	 */
	function setMaxTransferAmount(uint256 _maxTransferAmount) external onlyOwner {
		maxTransferAmount = _maxTransferAmount;
	}
}