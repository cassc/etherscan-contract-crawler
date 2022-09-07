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

error NotInSquad();
error AlreadyInSquad();

//@title SquadOwnable
//@author Satoshigoat (gh:@jcksber)
contract SquadOwnable is Ownable {

	//@dev Ownership - list of squad members (owners)
	mapping (address => bool) internal _squad;

	constructor() {
		//add myself and then future galerie
		_squad[0xB9699469c0b4dD7B1Dda11dA7678Fa4eFD51211b] = true;
		_squad[0xb8323B4B2FBbFa55D6697AdABC18725AA9245Ba3] = true;
	}

	//@dev Custom modifier for multiple owners
	modifier isSquad()
	{
		if (!isInSquad(_msgSender()))
			revert NotInSquad();
		_;
	}

	//@dev Determine if address `a` is an approved owner
	function isInSquad(address a) public view returns (bool) 
	{
		return _squad[a];
	}

	//@dev Add `a` to the squad
	function addToSquad(address a) external onlyOwner
	{
		if (isInSquad(a))
			revert AlreadyInSquad();
		_squad[a] = true;
	}

	//@dev Remove `a` from the squad
	function removeFromSquad(address a) external onlyOwner
	{
		if (!isInSquad(a))
			revert NotInSquad();
		_squad[a] = false;
	}
}