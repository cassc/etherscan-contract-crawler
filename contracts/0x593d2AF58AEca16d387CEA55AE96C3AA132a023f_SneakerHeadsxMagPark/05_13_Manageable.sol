// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

error Manageable__WalletIsAlreadyAManager();
error Manageable__WalletIsNotAManager();
error Manageable__ZeroAddress();

/**
 * @title Manageable
 * @author DeployLabs.io
 *
 * @dev This module is an extention of {Ownable} contract. It will make available
 * the modifier `onlyManager`, which can be applied to your functions to restrict their use to managers.
 * Managers can be added and removed by the owner.
 * Note, that the owner of the contract is also considered a manager.
 */
abstract contract Manageable is Ownable {
	/// @dev Mapping of wallet to their manager status.
	mapping(address => bool) private s_managers;

	/// @dev Throws if called by any account other than a manager.
	modifier onlyManager() {
		_checkManager();
		_;
	}

	constructor() {}

	/// @dev Add a list of addresses to a list of managers.
	function addManagers(address[] calldata wallets) external onlyOwner {
		for (uint256 index = 0; index < wallets.length; index++) {
			_addManager(wallets[index]);
		}
	}

	/// @dev Remove a list of addresses from a list of managers.
	function removeManagers(address[] calldata wallets) external onlyOwner {
		for (uint256 index = 0; index < wallets.length; index++) {
			_removeManager(wallets[index]);
		}
	}

	/// @dev Check, whether a wallet is a manager or not.
	function isManager(address wallet) public view returns (bool) {
		if (owner() == wallet) return true;
		return s_managers[wallet];
	}

	/// @dev Add an address to a list of managers.
	function _addManager(address wallet) internal {
		if (isManager(wallet)) revert Manageable__WalletIsAlreadyAManager();
		if (wallet == address(0)) revert Manageable__ZeroAddress();

		s_managers[wallet] = true;
	}

	/// @dev Remove an address from a list of managers.
	function _removeManager(address wallet) internal {
		if (!isManager(wallet)) revert Manageable__WalletIsNotAManager();
		if (wallet == address(0)) revert Manageable__ZeroAddress();

		s_managers[wallet] = false;
	}

	/// @dev Throws if the sender is not a manager.
	function _checkManager() internal view {
		if (!isManager(_msgSender())) revert Manageable__WalletIsNotAManager();
	}
}