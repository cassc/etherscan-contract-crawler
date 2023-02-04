// SPDX-License-Identifier: MIT
/*
 * CribOwnable.sol
 *
 * Created: October 3, 2022
 *
 * An extension of `Ownable.sol` to accomodate for a potential list of owners.
 * NOTE: this will need to be the last inherited contract to give all parents
 *       access to the modifiers it provides

* Referrenced: dev: @jcksber - github

 */

pragma solidity >=0.5.16 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

//@title CribOwnable.sol
//@author Twinny 

contract CribOwnable is Ownable {

	//@dev Ownership - list of crib members (owners)
	mapping (address => bool) internal _crib;

	constructor() {
		//add crib and then twinny
		_crib[0x690A0e1Eaf12C8e4734C81cf49d478A2c6473A73] = true;
		_crib[0x567B5E79cE0d465a0FF1e1eeeFE65d180b4C5D41] = true;
	}

	//@dev Custom modifier for multiple owners
	modifier isCrib()
	{
		require(isInCrib(_msgSender()), "CribOwnable: Caller not part of the crib.");
		_;
	}

	//@dev Determine if address `a` is an approved owner
	function isInCrib(address a) public view returns (bool) 
	{
		return _crib[a];
	}

	//@dev Add `a` to the crib
	function addToCrib(address a) public onlyOwner
	{
		require(!isInCrib(a), "CribOwnable: Address already in the crib.");
		_crib[a] = true;
	}

	//@dev Remove `a` from the crib
	function removeFromCrib(address a) public onlyOwner
	{
		require(isInCrib(a), "CribOwnable: Address already not in the crib.");
		_crib[a] = false;
	}
	

}