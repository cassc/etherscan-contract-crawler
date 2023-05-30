// SPDX-License-Identifier: MIT
/*
 * PLAKAccessControl.sol
 *
 * Author: Jack Kasbeer
 * Created: November 30, 2021
 */

pragma solidity >=0.5.16 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PLAKAccessControl is Ownable {

	// -----
	// PAUSE
	// -----

	bool public salePaused;//starts as false

	//@dev This will require the sale to be unpaused & active
	modifier saleActive()
	{
		require(!salePaused, "PLAKAccessControl: minting paused.");
		_;
	}

	//@dev Pause or unpause minting
	function toggleSaleActive() public onlyOwner
	{
		salePaused = !salePaused;
	}

	// ---------
	// LEGENDARY
	// ---------

	//@dev Legendary mapping for token ID's
	mapping (uint256 => bool) internal _legends;

	//@dev Determine if a token id is legendary status
	function isLegendary(uint256 tid)
		public view returns (bool)
	{
		return _legends[tid];
	}

	//@dev Make a token ID legendary
	function makeLegendary(uint256 tid)
		onlyOwner public
	{
		require(!isLegendary(tid), "PLAKAccessControl: token already legendary");
		require(!isDisabled(tid), "PLAKAccessControl: this token is disabled");
		_legends[tid] = true;
	}

	//@dev Remove legendary status from token ID
	function removeLegendary(uint256 tid)
		onlyOwner public
	{
		require(isLegendary(tid), "PLAKAccessControl: token not legendary");
		_legends[tid] = false;
	}

	//@dev Make a bunch of token ID's legendary at once
	function bulkMakeLegendary(uint256[] memory tids)
		onlyOwner public
	{
		uint tidsLen = tids.length;
		require(tidsLen > 1, "PLAKAccessControl: use `makeLegendary` instead");
		require(tidsLen < 256, "PLAKAccessControl: cannot add more than 255 at once");
		uint8 i;
		for (i = 0; i < tidsLen; i++) {
			if (!isLegendary(tids[i])) {
				_legends[tids[i]] = true;
			}
		}
	}

	//@dev Make a bunch of token ID's standard at once
	function bulkRemoveLegendary(uint256[] memory tids)
		onlyOwner public
	{
		uint tidsLen = tids.length;
		require(tidsLen > 1, "PLAKAccessControl: use `removeLegendary` instead");
		require(tidsLen < 256, "PLAKAccessControl: cannot add more than 255 at once");
		uint8 i;
		for (i = 0; i < tidsLen; i++) {
			if (isLegendary(tids[i])) {
				_legends[tids[i]] = false;
			}
		}
	}

	// --------
	// DISABLED
	// --------

	//@dev Blacklist mapping for token IDs
	mapping (uint256 => bool) internal _disabled;

	//@dev Determine if `tid` is disabled
	function isDisabled(uint256 tid) 
		public view returns (bool)
	{
		return _disabled[tid];
	}

	//@dev Disable a single token ID
	function disable(uint256 tid) 
		onlyOwner public
	{
		require(!isDisabled(tid), "PLAKAccessControl: already disabled"); 
		_disabled[tid] = true;
	}

	//@dev Enable a single token ID
	function enable(uint256 tid)
		onlyOwner public
	{
		require(isDisabled(tid), "PLAKAccessControl: already enabled");
		_disabled[tid] = false;
	}

	//@dev Disable a list of token ID's
	function bulkDisable(uint256[] memory tids) 
		onlyOwner public
	{
		uint tidsLen = tids.length;
		require(tidsLen > 1, "PLAKAccessControl: use `disable` instead");
		require(tidsLen < 256, "PLAKAccessControl: cannot add more than 255 at once");
		uint8 i;
		for (i = 0; i < tidsLen; i++) {
			if (!isDisabled(tids[i])) {
				_disabled[tids[i]] = true;
			}
		}
	}

	//@dev Enable a list of token ID's 
	function bulkEnable(uint256[] memory tids) 
		onlyOwner public
	{
		uint tidsLen = tids.length;
		require(tidsLen > 1, "PLAKAccessControl: use `enable` instead");
		require(tidsLen < 256, "PLAKAccessControl: cannot remove more than 255 at once");
		uint8 i;
		for (i = 0; i < tidsLen; i++) {
			if (isDisabled(tids[i])) {
				_disabled[tids[i]] = false;
			}
		}
	}

	// ---------
	// WHITELIST
	// ---------

	//@dev Whitelist mapping for client addresses
	mapping (address => bool) internal _whitelist;

	//@dev Whitelist flag for active/inactive states
	bool public whitelistActive;

	//@dev Toggle the whitelist
	function toggleWhitelistActive()
		onlyOwner public
	{
		whitelistActive = !whitelistActive;
	}

	//@dev Prove that one of our whitelist address owners has been approved
	function isInWhitelist(address a) 
		public view returns (bool)
	{
		return _whitelist[a];
	}

	//@dev Add a single address to whitelist
	function addToWhitelist(address a) 
		onlyOwner public
	{
		require(!isInWhitelist(a), "PLAKAccessControl: already whitelisted"); 
		//here we care if address already whitelisted to save on gas fees
		_whitelist[a] = true;
	}

	//@dev Remove a single address from the whitelist
	function removeFromWhitelist(address a)
		onlyOwner public
	{
		require(isInWhitelist(a), "PLAKAccessControl: not in whitelist");
		_whitelist[a] = false;
	}

	//@dev Add a list of addresses to the whitelist
	function bulkAddToWhitelist(address[] memory addresses) 
		onlyOwner public
	{
		require(addresses.length > 1, "PLAKAccessControl: use `addToWhitelist` instead");
		uint8 i;
		for (i = 0; i < addresses.length; i++) {
			if (!_whitelist[addresses[i]]) {
				_whitelist[addresses[i]] = true;
			}
		}
	}
}