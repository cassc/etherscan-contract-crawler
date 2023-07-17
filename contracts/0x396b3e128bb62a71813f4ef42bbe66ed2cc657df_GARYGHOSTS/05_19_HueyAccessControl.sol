// SPDX-License-Identifier: MIT
/*
 * HueyAccessControl.sol
 *
 * Author: Don Huey
 * Created: December 8th, 2021
 *
 * This is an extension of `Ownable` to allow a larger set of addresses to have
 * certain control in the inheriting contracts.
 * goldlist feature as well.
 *
 * Referrenced: KasbeerAccessControl.sol / dev: @jcksber - github
 */

pragma solidity >=0.5.16 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol"; // "../node_modules/@openzeppelin/contracts/access/Ownable.sol"

contract HueyAccessControl is Ownable {
	
	// -----
	// Gang
	// -----

	//@dev Ownership - list of squad members (owners)
	mapping (address => bool) internal _gang;

	//@dev Custom "approved" modifier because I don't like that language (Jack is right, the language sucks.)
	modifier isGang()
	{
		require(isInGang(msg.sender), "HueyAccessControl: Caller not part of gang.");
		_;
	}

	//@dev Determine if address `addy` is an approved owner
	function isInGang(address addy) 
		public view returns (bool) 
	{
		return _gang[addy];
	}

	//@dev Add `addy` to the gang
	function addToGang(address addy)
		onlyOwner public
	{
		require(!isInGang(addy), "HueyAccessControl: Address already in gang.");
		_gang[addy] = true;
	}

	//@dev Remove `addy` from the gang
	function removeFromGang(address addy)
		onlyOwner public
	{
		require(isInGang(addy), "HueyAccessControl: Address already not in gang.");
		_gang[addy] = false;
	}

	// ---------
	// GOLDLIST
	// ---------

	//@dev goldlist mapping for client addresses
	mapping (address => bool) internal _goldlist;

	//@dev goldlist flag for active/inactive states
	bool goldlistActive;

	//@dev Determine if someone is in the goldlsit
	modifier onlygoldlist(address addy)
	{
		require(isIngoldlist(addy));
		_;
	}

	//@dev Prevent non-goldlist minting functions from being used 
	// if `goldlistActive` == 1
	modifier goldlistDisabled()
	{
		require(goldlistActive == false, "HueyAccessControl: goldlist still active");
		_;
	}

	//@dev Require that the goldlist is currently enabled
	modifier goldlistEnabled() 
	{
		require(goldlistActive == true, "HueyAccessControl: goldlist not active");
		_;
	}

	//@dev Turn the goldlist on
	function activategoldlist()
		isGang goldlistDisabled public
	{
		goldlistActive = true;
	}

	//@dev Turn the goldlist off
	function deactivategoldlist()
		isGang goldlistEnabled public
	{
		goldlistActive = false;
	}

	//@dev Prove that one of our goldlist address owners has been approved
	function isIngoldlist(address addy) 
		public view returns (bool)
	{
		return _goldlist[addy];
	}

	//@dev Add a single address to goldlist
	function addTogoldlist(address addy) 
		isGang public
	{
		require(!isIngoldlist(addy), "HueyAccessControl: already goldlisted"); 
		//here we care if address already goldlisted to save on gas fees
		_goldlist[addy] = true;
	}

	//@dev Remove a single address from the goldlist
	function removeFromgoldlist(address addy)
		isGang public
	{
		require(isIngoldlist(addy), "HueyAccessControl: not in goldlist");
		_goldlist[addy] = false;
	}

	//@dev Add a list of addresses to the goldlist
	function bulkAddTogoldlist(address[] memory addys) 
		isGang public
	{
		require(addys.length > 1, "HueyAccessControl: use `addTogoldlist` instead");
		uint256 i;
		for (i = 0; i < addys.length; i++) {
			if (!_goldlist[addys[i]]) {
				_goldlist[addys[i]] = true;
			}
		}
	}
}