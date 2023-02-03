// contracts/AntiBot.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AntiBot is Ownable {
	bool public transfersPaused = true;
	uint256 public antiBotSecondCooldown = 60; // 60 seconds by default
	mapping(address => uint256) public lastTransactionTime;

	/**
	 * @dev Returns if _sender is a bot.
	 *
	 * _sender is considered a bot if his last transfer was made less than {antiBotSecondCooldown} seconds ago.
	 */
	function isBot(address _sender) public view returns (bool) {
		return
			block.timestamp - lastTransactionTime[_sender] < antiBotSecondCooldown;
	}

	/**
	 * @dev Returns if transfers are paused.
	 */
	function areTransfersPaused() public view returns (bool) {
		return transfersPaused;
	}

	/**
	 * @dev Changes the value of {transfersPaused} to {_paused}.
	 */
	function setTransfersPaused(bool _paused) external onlyOwner {
		transfersPaused = _paused;
	}

	/**
	 * @dev Changes the transfer cooldown value of {antiBotSecondCooldown} to {_antiBotSecondCooldown}.
	 */
	function setAntiBotSecondCooldown(uint256 _antiBotSecondCooldown)
		external
		onlyOwner
	{
		antiBotSecondCooldown = _antiBotSecondCooldown;
	}
}