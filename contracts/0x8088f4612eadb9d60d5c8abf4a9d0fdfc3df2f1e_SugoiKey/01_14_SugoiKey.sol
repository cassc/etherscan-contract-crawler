// SPDX-License-Identifier: MIT
/*
 * SugoiKey.sol
 *
 * Created: May 30, 2022
 */

pragma solidity ^0.8.4;

import "./Satoshigoat.sol";

abstract contract Plug {
	function balanceOf(address a) public view virtual returns (uint);
	function ownerOf(uint256 tid) public view virtual returns (address);
	function tokenURI(uint256 tid) public view virtual returns (string memory);
}

//@title Sugoi NYC 2022 Event Ticket
//@author Satoshigoat (gh:@jcksber)
contract SugoiKey is Satoshigoat {

	Plug constant public thePlug = Plug(0x2Bb501A0374ff3Af41f2009509E9D6a36D56A6c0);//mainnet

	uint256 constant VANGUARD_LAST_ID = 887;//first 888 are vanguard

	mapping(uint256 => string) internal _tokens;//tid -> ipfs hash

	string [3] _hashes = ["QmeRLXAm3p8sQuWpJ99944iPJwqXNwvMZJR3PYtAKchb85",
						  "QmZ5cybBXyhvmEYVmc3bcNRqVWmyGCsgbPi4VT4WSYoKCz",
						  "QmVz3uxZC6EcrgPhdxHq5CT2qwRABTcr9z19cVaDZf1zfg"];
	string [3] _vanguardHashes = ["QmZNFmkUzMKU8pdx2Lqhy6k4A2k9X5nyV2wgmXsYvdqpkn",
						  		  "Qmbb8pNMPAhvBVqgdV2hP8X5zGSeHssa7Zo4b3YELqxkCz",
						  		  "QmZjSQ9GpjwRDZQXz5xCgnhSbV5QWQK1gUvxojmckQEkig"];
	string [3] _hustlers = ["ipfs://QmQ47S4WESzCBp2vUh4AVKmkejVmrbSW6YcrjiLtfnBtAM",
							"ipfs://QmYicdR5xgQbiwdMvhokPrqQYc6Znejnx2oJZeosMujoq5",
							"ipfs://QmSsLuP2VayEgVL1iLDnkHF5Hp8pdqeMeDRm6dzKMY1h1Y"];

	bool private _public = false;

	// -----
	// Core
	// -----

	modifier claimArgsOK(address to, uint256 qty, uint256 plugTid) {

		// Cannot mint to a contract
		if (_isContract(to))
			revert DataError("silly rabbit :P");

		// The owner of `plugTid` must be the receiving/minting address
		if (thePlug.ownerOf(plugTid) != to)
			revert DataError("address `to` must own `plugTid`");

		uint numPlugs = thePlug.balanceOf(to);
		// Must be a Plug holder
		if (numPlugs == 0)
			revert DataError("not plug holder");

		uint64 numClaimed = _getAux(to);
		// The `qty` can only be greater than 5 if more than 5 plugs are owned,
		// and can only go up to the number of plugs owned
		if (qty + numClaimed > 5 && qty + numClaimed > numPlugs)
			revert DataError("attempting to claim too many keys");
		_;
	}

	modifier publicClaimArgsOK(address to) {

		// If sale is private you cannot use this function
		if (!_public) revert 
			DataError("sale is private rn");

		// Contracts cannot be minted to
		if (_isContract(to)) 
			revert DataError("silly rabbit :P");

		// Can only claim one as non-Plug holder
		if (_getAux(to) > 0) 
			revert DataError("attempting to claim too many keys");
		_;
	}

	constructor() Satoshigoat("Sugoi NFT NYC 2022", "", "ipfs://") 
	{
		payoutAddress = address(0x6b8C6E15818C74895c31A1C91390b3d42B336799);
	}
	
	//@dev See {ERC721A-tokenURI}
	function tokenURI(uint256 tid) public view virtual override 
		returns (string memory) 
	{	
		if (!_exists(tid))
			revert URIQueryForNonexistentToken();
		return string(abi.encodePacked(_baseURI(), _tokens[tid]));
	}

	//@dev Allows owners to mint for free (all 'frens' tickets)
	function mint(address to, uint256 qty) external isSquad enoughSupply(qty)
	{
		unchecked {
			uint currentIdx = _totalMinted();
			uint nextIdx = currentIdx + qty;

			_safeMint(to, qty);

			uint i;
			for (i = currentIdx; i < nextIdx; i++) {
				if (i <= VANGUARD_LAST_ID)
					_tokens[i] = _vanguardHashes[0];
				else
					_tokens[i] = _hashes[0];//frens ticket
			}
		}
	}

	//@dev Plug holders can claim 5 tickets, unless they have more than 5 plugs, then
	// they can claim up to the same number of tickets as owned Plugs
	function claim(
		address to, 
		uint256 qty, 
		uint256 plugTid
	) 
		external 
		nonReentrant
		enoughSupply(qty)
		claimArgsOK(to, qty, plugTid)
	{
		uint64 numClaimed = _getAux(to);
		unchecked {
			string memory uri = thePlug.tokenURI(plugTid);
			uint currentIdx = _totalMinted();
			uint nextIdx = currentIdx + qty;

			_safeMint(to, qty);

			// First-time claimers get a special first key
			if (numClaimed == 0) {
				// Depending on level of hodler, create first key
				if (_stringsEqual(uri, _hustlers[0]) || 
					_stringsEqual(uri, _hustlers[1]) || 
					_stringsEqual(uri, _hustlers[2])) 
				{
					// hustlers get a rare version
					if (currentIdx <= VANGUARD_LAST_ID) 
						_tokens[currentIdx] = _vanguardHashes[2];//early-bird hustlers key
					else 
						_tokens[currentIdx] = _hashes[2];//hustler key
				} else {
					// other plug holders get the normal version
					if (currentIdx <= VANGUARD_LAST_ID)
						_tokens[currentIdx] = _vanguardHashes[1];//early-bird plug key
					else
						_tokens[currentIdx] = _hashes[1];//plug key
				}
				currentIdx++;//move pointer along
			}

			// Create frens keys
			uint i;
			for (i = currentIdx; i < nextIdx; i++) {
				if (i <= VANGUARD_LAST_ID)
					_tokens[i] = _vanguardHashes[0];//early-bird frens key
				else
					_tokens[i] = _hashes[0];//frens key
			}
		}

		// Record number of keys claimed
		_setAux(to, numClaimed + uint64(qty));
	}

	//@dev Public claim - one per person
	function publicClaim(address to) 
		external 
		nonReentrant 
		enoughSupply(1)
		publicClaimArgsOK(to)
	{	
		uint currentIdx = _totalMinted();
		
		_safeMint(to, 1);

		if (currentIdx <= VANGUARD_LAST_ID)
			_tokens[currentIdx] = _vanguardHashes[0];//early-bird frens key
		else
			_tokens[currentIdx] = _hashes[0];//frens key

		// Record number of keys claimed
		_setAux(to, 1);
	}
	
	//@dev Allow squad to burn - completely a backup function
	function burn(uint256 tid) external isSquad
	{
		_burn(tid);
	}

	//@dev Destroy contract and reclaim leftover funds
	function kill() external onlyOwner 
	{
		selfdestruct(payable(_msgSender()));
	}

	//@dev See `kill`; protects against being unable to delete a collection on OpenSea
	function safe_kill() external onlyOwner
	{
		if (balanceOf(_msgSender()) != totalSupply())
			revert DataError("potential error - not all tokens owned");
		selfdestruct(payable(_msgSender()));
	}

	//@dev Toggle public sale
	function togglePublicSale() external isSquad {
		_public = _public ? false : true;
	}

	//@dev Ability to change the ipfs hashes
	function setHash(uint8 idx, string calldata newHash) 
		external isSquad notEqual(_hashes[idx], newHash) { _hashes[idx] = newHash; }

	//@dev Ability to change the ipfs hashes
	function setVanguardHash(uint8 idx, string calldata newHash) 
		external isSquad notEqual(_vanguardHashes[idx], newHash) { _vanguardHashes[idx] = newHash; }

	//@dev Ability to change the Hustler hashes (no reason to ever)
	function setHustlerURI(uint8 idx, string calldata newHash) 
		external isSquad notEqual(_hustlers[idx], newHash) { _hustlers[idx] = newHash; }
}