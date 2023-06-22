// SPDX-License-Identifier: MIT
/*
 * SquadOwnable.sol
 *
 * Created: December 21, 2021
 *
 * An extension of `Ownable.sol` to accomodate for a potential list of owners.
 * NOTE: this will need to be the last inherited contract to give all parents
 *       access to the modifiers it provides
 */

pragma solidity >=0.5.16 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

//@title SquadOwnable
//@author Jack Kasbeer (gh:@jcksber, tw:@satoshigoat, ig:overprivilegd)
contract SquadOwnable is Ownable {

	//@dev Ownership - list of squad members (owners)
	mapping (address => bool) internal _squad;

	constructor() {
		//add myself and then logik (client)
		_squad[0xB9699469c0b4dD7B1Dda11dA7678Fa4eFD51211b] = true;
		_squad[0x6b8C6E15818C74895c31A1C91390b3d42B336799] = true;
	}

	//@dev Custom modifier for multiple owners
	modifier isSquad()
	{
		require(isInSquad(_msgSender()), "SquadOwnable: Caller not part of squad.");
		_;
	}

	//@dev Determine if address `a` is an approved owner
	function isInSquad(address a) public view returns (bool) 
	{
		return _squad[a];
	}

	//@dev Add `a` to the squad
	function addToSquad(address a) public onlyOwner
	{
		require(!isInSquad(a), "SquadOwnable: Address already in squad.");
		_squad[a] = true;
	}

	//@dev Remove `a` from the squad
	function removeFromSquad(address a) public onlyOwner
	{
		require(isInSquad(a), "SquadOwnable: Address already not in squad.");
		_squad[a] = false;
	}
}