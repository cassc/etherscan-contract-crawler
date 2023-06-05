// SPDX-License-Identifier: MIT
/*
 * KasbeerAccessControl.sol
 *
 * Author: Jack Kasbeer
 * Created: October 14, 2021
 *
 * This is an extension of `Ownable` to allow a larger set of addresses to have
 * certain control in the inheriting contracts.
 */

pragma solidity >=0.5.16 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract KasbeerAccessControl is Ownable {
	
	// -----
	// SQUAD
	// -----

	//@dev Ownership - list of squad members (owners)
	mapping (address => bool) internal _squad;

	//@dev Custom "approved" modifier because I don't like that language
	modifier isSquad()
	{
		require(isInSquad(msg.sender), "KasbeerAccessControl: Caller not part of squad.");
		_;
	}

	//@dev Determine if address `a` is an approved owner
	function isInSquad(address a) 
		public view returns (bool) 
	{
		return _squad[a];
	}

	//@dev Add `a` to the squad
	function addToSquad(address a)
		onlyOwner public
	{
		require(!isInSquad(a), "KasbeerAccessControl: Address already in squad.");
		_squad[a] = true;
	}

	//@dev Remove `a` from the squad
	function removeFromSquad(address a)
		onlyOwner public
	{
		require(isInSquad(a), "KasbeerAccessControl: Address already not in squad.");
		_squad[a] = false;
	}

	// ---------
	// WHITELIST
	// ---------

	//@dev Whitelist mapping for client addresses
	mapping (address => bool) internal _whitelist;

	//@dev Whitelist flag for active/inactive states
	bool whitelistActive;

	//@dev Determine if someone is in the whitelsit
	modifier onlyWhitelist(address a)
	{
		require(isInWhitelist(a));
		_;
	}

	//@dev Prevent non-whitelist minting functions from being used 
	// if `whitelistActive` == 1
	modifier whitelistDisabled()
	{
		require(whitelistActive == false, "KasbeerAccessControl: whitelist still active");
		_;
	}

	//@dev Require that the whitelist is currently enabled
	modifier whitelistEnabled() 
	{
		require(whitelistActive == true, "KasbeerAccessControl: whitelist not active");
		_;
	}

	//@dev Turn the whitelist on
	function activateWhitelist()
		isSquad whitelistDisabled public
	{
		whitelistActive = true;
	}

	//@dev Turn the whitelist off
	function deactivateWhitelist()
		isSquad whitelistEnabled public
	{
		whitelistActive = false;
	}

	//@dev Prove that one of our whitelist address owners has been approved
	function isInWhitelist(address a) 
		public view returns (bool)
	{
		return _whitelist[a];
	}

	//@dev Add a single address to whitelist
	function addToWhitelist(address a) 
		isSquad public
	{
		require(!isInWhitelist(a), "KasbeerAccessControl: already whitelisted"); 
		//here we care if address already whitelisted to save on gas fees
		_whitelist[a] = true;
	}

	//@dev Remove a single address from the whitelist
	function removeFromWhitelist(address a)
		isSquad public
	{
		require(isInWhitelist(a), "KasbeerAccessControl: not in whitelist");
		_whitelist[a] = false;
	}

	//@dev Add a list of addresses to the whitelist
	function bulkAddToWhitelist(address[] memory addys) 
		isSquad public
	{
		require(addys.length > 1, "KasbeerAccessControl: use `addToWhitelist` instead");
		uint8 i;
		for (i = 0; i < addys.length; i++) {
			if (!_whitelist[addys[i]]) {
				_whitelist[addys[i]] = true;
			}
		}
	}
}