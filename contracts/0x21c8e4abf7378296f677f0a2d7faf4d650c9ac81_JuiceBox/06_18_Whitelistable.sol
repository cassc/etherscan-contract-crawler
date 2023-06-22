// SPDX-License-Identifier: MIT
/*
 * Whitelistable.sol
 *
 * Created: December 21, 2021
 *
 * Provides functionality for a "whitelist"/"guestlist" for inheriting contracts.
 */

pragma solidity >=0.5.16 <0.9.0;

import "./SquadOwnable.sol";

//@title Whitelistable
//@author Jack Kasbeer (gh:@jcksber, tw:@satoshigoat, ig:overprivilegd)
contract Whitelistable is SquadOwnable {

	// -------------
	// EVENTS & VARS
	// -------------

	event WhitelistActivated(address indexed a);
	event WhitelistDeactivated(address indexed a);

	//@dev Whitelist mapping for client addresses
	mapping (address => bool) internal _whitelist;

	//@dev Whitelist flag for active/inactive states
	bool internal _whitelistActive;

	constructor() {
		_whitelistActive = false;
		//add myself and then logik (client)
		_whitelist[0xB9699469c0b4dD7B1Dda11dA7678Fa4eFD51211b] = true;
		_whitelist[0x6b8C6E15818C74895c31A1C91390b3d42B336799] = true;
	}

	// ---------
	// MODIFIERS
	// ---------

	//@dev Determine if someone is in the whitelsit
	modifier onlyWhitelist(address a)
	{
		require(isWhitelisted(a), "Whitelistable: must be on whitelist");
		_;
	}

	//@dev Prevent non-whitelist minting functions from being used 
	modifier whitelistDisabled()
	{
		require(_whitelistActive == false, "Whitelistable: whitelist still active");
		_;
	}

	//@dev Require that the whitelist is currently enabled
	modifier whitelistEnabled() 
	{
		require(_whitelistActive == true, "Whitelistable: whitelist not active");
		_;
	}

	// ----------
	// MAIN LOGIC
	// ----------

	//@dev Toggle the state of the whitelist (on/off)
	function toggleWhitelist() public isSquad
	{
		_whitelistActive = !_whitelistActive;

		if (_whitelistActive) {
			emit WhitelistActivated(_msgSender());
		} else {
			emit WhitelistDeactivated(_msgSender());
		}
	}

	//@dev Determine if `a` is in the `_whitelist
	function isWhitelisted(address a) public view returns (bool)
	{
		return _whitelist[a];
	}

	//// ----------
	//// ADD/REMOVE
	//// ----------

	//@dev Add a single address to whitelist
	function addToWhitelist(address a) public isSquad
	{
		require(!isWhitelisted(a), "Whitelistable: already whitelisted"); 
		_whitelist[a] = true;
	}

	//@dev Remove a single address from the whitelist
	function removeFromWhitelist(address a) public isSquad
	{
		require(isWhitelisted(a), "Whitelistable: not in whitelist");
		_whitelist[a] = false;
	}

	//@dev Add a list of addresses to the whitelist
	function bulkAddToWhitelist(address[] memory addresses) public isSquad
	{
		uint addrLen = addresses.length;

		require(addrLen > 1, "Whitelistable: use `addToWhitelist` instead");
		require(addrLen < 65536, "Whitelistable: cannot add more than 65535 at once");

		uint16 i;
		for (i = 0; i < addrLen; i++) {
			if (!isWhitelisted(addresses[i])) {
				_whitelist[addresses[i]] = true;
			}
		}
	}
}