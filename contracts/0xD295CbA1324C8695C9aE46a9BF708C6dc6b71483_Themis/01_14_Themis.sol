// SPDX-License-Identifier: MIT
/*
 * Themis.sol
 *
 * Created: January 8, 2023
 */

pragma solidity ^0.8.4;

import "./Satoshigoat.sol";

/*
	NOTES:
		- Changes based on `lawBusinessIndexScore` which is an integer retrieved from
		  https://www.ceicdata.com/en/mali/governance-policy-and-institutions
		- 1 of 1 NFT collection
*/

//@title VenusGarden
//@author Satoshigoat (gh:@jcksber)
contract Themis is Satoshigoat {

	//0: wrath
	//1: trial
	//2: redemption
	//3: equilibrium
	string [4] private _hashes = ["QmZyMSgDr35tkU1JR9VqXwF6HPck4MspUQQQGByeq74pDD",
								  "QmYTp62n9m721vUcoMkm9LU1M1TzMZTrx9g44KPZyTzcn8",
								  "QmSDYWishYCtBDTx8UjNbukV3hNw9dEj6TLJw4fBx6QLvn",
								  "QmXEr2nNYE3UM81vR5h9LrN7w5QpMBfwmyeeeu7Kpnk4hx"];

	bool public isPublic;

	uint16 public lawBusinessIndexScore;//[0,100]

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

	constructor() Satoshigoat("Themis", "", "ipfs://") 
	{
		_contractURI = "ipfs://QmPfsfWqkSMrCwSqLgMY2iTarLJsC4hf9z55Wdqz8R63mu";
		_owner = address(0xF1c2eC71b6547d0b30D23f29B9a0e8f76C7Af743);
		payoutAddress = address(0xF1c2eC71b6547d0b30D23f29B9a0e8f76C7Af743);
    	purchasePrice = 5.2 ether;//~$8k @ launch
    	lawBusinessIndexScore = 61;
	}
	
	//@dev See {ERC721A-tokenURI}
	function tokenURI(uint256 tid) public view virtual override 
		returns (string memory) 
	{	
		if (!_exists(tid))
			revert URIQueryForNonexistentToken();
		return string(abi.encodePacked(_baseURI(), _getIPFSHash()));
	}

	//@dev Get the appropriate IPFS hash based on the `lawBusinessIndexScore`
	function _getIPFSHash() private view returns (string memory)
	{	
		if (59 <= lawBusinessIndexScore && lawBusinessIndexScore <= 75)
			return _hashes[1];//trial (state during launch)
		else if (76 <= lawBusinessIndexScore && lawBusinessIndexScore <= 90)
			return _hashes[2];//redemption (forward movement)
		else if (lawBusinessIndexScore >= 91)
			return _hashes[3];//equilibrium (completion)
		else
			return _hashes[0];//wrath (backwards movement)
	}

	//@dev Mint a token (owners only)
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

	//@dev Purchase a token
	function purchase()
		external
		payable
		nonReentrant
		enoughSupply(1)
		purchaseArgsOK(_msgSender(), msg.value)
	{
		_safeMint(_msgSender(), 1);
	}

	//@dev Change the law business index score
	function setLawBusinessIndexScore(uint16 newScore) external isSquad
	{
		if (newScore < 0 || newScore > 100)
			revert DataError("score must be between 0 and 100");
		lawBusinessIndexScore = newScore;
	}

	// ----------------
	// BACKUP FUNCTIONS
	// ----------------

	//@dev [BACKUP METHOD] Change one of the ipfs hashes for the project
	function setIPFSHash(uint8 idx, string memory newHash) external isSquad
	{
		if (idx < 0 || idx > 3) 
			revert DataError("index out of bounds");
		if (_stringsEqual(_hashes[idx], newHash)) 
			revert DataError("hash is the same");
		_hashes[idx] = newHash;
	}

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