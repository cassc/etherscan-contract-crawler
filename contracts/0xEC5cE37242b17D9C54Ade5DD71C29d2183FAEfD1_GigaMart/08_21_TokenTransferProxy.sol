// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IProxyRegistry.sol";

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Token Transfer Proxy
	@author Project Wyvern Developers
	@author Tim Clancy <@_Enoch>
	@custom:contributor Rostislav Khlebnikov <@catpic5buck>

	A token transfer proxy contract. This contract was originally developed by 
	Project Wyvern. It has been modified to support a more modern version of 
	Solidity with associated best practices. The documentation has also been 
	improved to provide more clarity.

	@custom:date December 4th, 2022.
*/
contract TokenTransferProxy {
	using SafeERC20 for IERC20;

	/// The address of the immutable authentication registry.
	IProxyRegistry public immutable registry;

	/**
		Construct a new instance of this token transfer proxy given the associated 
		registry.

		@param _registry The address of a proxy registry.
	*/
	constructor (
		address _registry
	) {
		registry = IProxyRegistry(_registry);
	}

	/**
		Perform a transfer on a targeted ERC-20 token, rejecting unauthorized callers.

		@param _token The address of the ERC-20 token to transfer.
		@param _from The address to transfer ERC-20 tokens from.
		@param _to The address to transfer ERC-20 tokens to.
		@param _amount The amount of ERC-20 tokens to transfer.

		@custom:throws NonAuthorizedCaller if the caller is not authorized to 
			perform the ERC-20 token transfer.
	*/
	function transferERC20 (
		address _token,
		address _from,
		address _to,
		uint _amount
	) public {
		if (!registry.authorizedCallers(msg.sender)) {
			revert NonAuthorizedCaller();
		}
		IERC20(_token).safeTransferFrom(_from, _to, _amount);
	}
}