// SPDX-License-Identifier: MIT
/*
 * Zurich.sol
 *
 * Created: June 14, 2023
 * Address: 
 */

pragma solidity ^0.8.4;

import "./Satoshigoat.sol";

/*
	NOTES:
		- Four possible states of the NFT, which will be based
		  on the current weather in Zurich, Switzerland:
		    (1) Day time (sunrise to sunset) calm weather
		    (2) Day time (sunrise to sunset) stormy weather
		    (3) Night time (sunset to sunrise) calm weather
		    (4) Night time (sunset to sunrise) stormy weather
		- 1 of 1 NFT collection
*/

//@title Zürich
//@author Satoshigoat (gh:@jcksber)
contract Zurich is Satoshigoat {

	// -----------
	// RESTRICTORS
	// -----------

	modifier notContract(address to) {
		if (_isContract(to)) 
			revert DataError("silly rabbit :P");
		_;
	}

	// ------------------------------
	// CORE FUNCTIONALITY FOR ERC-721
	// ------------------------------

	constructor() Satoshigoat("Zurich", "", "http://143.244.213.74/zurich?tid=") 
    {
		_contractURI = "ipfs://QmTVMAPCzwD9djLt7tHUURaWEHmv7sFJWWqL4fryf9uAdm";
		_owner = address(0xF1c2eC71b6547d0b30D23f29B9a0e8f76C7Af743);
		payoutAddress = address(0xF1c2eC71b6547d0b30D23f29B9a0e8f76C7Af743);
    	purchasePrice = 5.4 ether;
	}
	
	//@dev See {ERC721A-tokenURI}
	function tokenURI(uint256 tid) public view virtual override 
		returns (string memory) 
	{	
		if (!_exists(tid))
			revert URIQueryForNonexistentToken();
		return string(abi.encodePacked(_baseURI(), "0"));
	}

	//@dev Mint the only token (owners only)
	function mint(address payable to) 
		external
		payable
		isSquad
		nonReentrant
		enoughSupply(1)
		notContract(to)
	{
		_safeMint(to, 1);
	}

	//@dev Purchase the only token
	function purchase(address payable to)
		external
		payable
		nonReentrant
		enoughSupply(1)
		purchaseArgsOK(to, msg.value)
	{
		_safeMint(to, 1);
	}

	// ----------------
	// BACKUP FUNCTIONS
	// ----------------

	//@dev [BACKUP METHOD] Allow squad to burn any token
	function burn(uint256 tid) external isSquad
	{
		_burn(tid);
	}

	//@dev [BACKUP METHOD] Destroy contract and reclaim leftover funds
	function kill() external onlyOwner
	{
		selfdestruct(payable(_msgSender()));
	}

	//@dev [BACKUP METHOD] See `kill`; protects against being unable to delete a collection on OpenSea
	function safe_kill() external onlyOwner
	{
		if (balanceOf(_msgSender()) != totalSupply())
			revert DataError("potential error - not all tokens owned");
		selfdestruct(payable(_msgSender()));
	}
}