// SPDX-License-Identifier: MIT
/*
 * FutureGalerieSimple.sol
 *
 * Created: September 2, 2022
 */

pragma solidity ^0.8.4;

import "./Satoshigoat.sol";

/*
	NOTES:
		- Owners want ability to release more later 
			-> i say we airdrop 203, supply 1000, then pause 
			   the possible mint function after airdrop
		- Number of levels is not changeable!
*/

//@title AirOrb Membership Pass by Future Galerie
//@author Satoshigoat (gh:@jcksber)
contract FutureGalerieSimple is Satoshigoat {

	event TokenMetadataNotUpdated(uint256 tid);

	uint8 constant public NUM_LEVELS = 4;

	mapping(uint256 => uint8) internal _tidToLevel;//token id -> membership level ([1,4])

	//_levelHashes[0] is Level 1 ... etc
	string [NUM_LEVELS] _levelHashes = ["QmdURAzLmAK929WiUa5scvdM5unNG3esnu8zsZtahY4YcC",
						  	  		    "QmNgVYeXJqBsksmLXpS4Nu9mCEQ3ZtRWSqmT3Trojn6yb6",
						  	   		    "QmYhqq4Fccqi9HjSE8ZiZJoP5Lki8FrXha5zdnCF42eE6L",
						  	   			"QmPBB9iKbFQ9xbVErD8sY6Z7itCRY622G3sJvvJZPgViPm"];
	// -----------
	// RESTRICTORS
	// -----------

	modifier notContract(address to) {
		// Contracts cannot be minted to
		if (_isContract(to)) 
			revert DataError("silly rabbit :P");
		_;
	}

	modifier levelInBounds(uint8 level) {
		if (level < 1 || level > NUM_LEVELS)
			revert DataError("level must be between 1 and 4");
		_;
	}

	// ------------------------------
	// CORE FUNCTIONALITY FOR ERC-721
	// ------------------------------

	constructor() Satoshigoat("AirOrb Membership Pass by Future Galerie", "", "ipfs://") 
	{
		_contractURI = "ipfs://Qmc4tuyaJ1A4VFV5GfSMw6nuQpiMxa7ZmF7ysyTjqGQdoV";
		_owner = address(0xb8323B4B2FBbFa55D6697AdABC18725AA9245Ba3);
		payoutAddress = address(0xa34da04b871A7dD50564487822df56766e442Fa8);
    	purchasePrice = 1000000000000000000000;//1000 ETH (basically not for purchase)
	}
	
	//@dev See {ERC721A-tokenURI}
	function tokenURI(uint256 tid) public view virtual override 
		returns (string memory) 
	{	
		if (!_exists(tid))
			revert URIQueryForNonexistentToken();
		return string(abi.encodePacked(_baseURI(), getHashForLevel(_tidToLevel[tid])));
	}

	//@dev Used in `tokenURI` to determine the proper ipfs hash to use
	function getHashForLevel(uint8 level) private view levelInBounds(level) returns (string memory) 
	{
		if (level == 1) 
			return _levelHashes[0];
		else if (level == 2) 
			return _levelHashes[1];
		else if (level == 3) 
			return _levelHashes[2];
		else 
			return _levelHashes[3];
	}

	//@dev See ERC721A.sol
	function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {

    	// If `to` already has an "orb" (and isn't an owner), 
    	// don't let the transfer occur
    	if (balanceOf(to) > 0 && !isInSquad(to))
    		revert DataError("only 1 per wallet as non-owner");

    	// If this is a transfer associated with minting, ignore
    	if (from == address(0)) return;
    	// This check may seem redudant since `_tidToHash[to]`is assigned
    	//  after the call to `_safeMint` in airdrop functions, but this will save
    	//  on pointless writes to storage for minting

    	// Otherwise, a transfer results in the token's level returning to "member"
    	unchecked {
    		uint i;
    		uint endingId = startTokenId + quantity;
    		for (i = startTokenId; i < endingId; i++) {
				setStorageTokenIDHash(i, 1);
		    }
		}
    }

	// ---------------------
	// AIRDROP FUNCTIONALITY
	// ---------------------

	//@dev Allows owners to airdrop an orb at any level to address `to`
	function singleAirdrop(address to, uint8 level) 
		external
		isSquad 
		nonReentrant
		notContract(to)
		levelInBounds(level)
		enoughSupply(1) 
	{
		_safeMint(to, 1);
		setStorageTokenIDHash(_totalMinted()-1, level);
	}

	//@dev Allows owners to mint/airdrop to a list of addresses
	//NOTE: function is not checking to see if the address is a contract
	function bulkAirdrop(address[] memory airdropAddressesArray)
		external 
		isSquad
		nonReentrant
		enoughSupply(airdropAddressesArray.length)
	{
		unchecked {
			uint i;
			for (i = 0; i < airdropAddressesArray.length; i++) {
				if (balanceOf(airdropAddressesArray[i]) == 0) {
					_safeMint(airdropAddressesArray[i], 1);
					setStorageTokenIDHash(_totalMinted()-1, 1);
				}
			}
		}
	}
	
	// -------------------------------------
	// METADATA (LEVEL) UPDATE FUNCTIONALITY
	// -------------------------------------

	//@dev [GRNAULAR UPDATE] "Level up" `tid`
	// to `level` ([1-4]) (1 corresponds with _levelHashes[0], etc.)
	function changeTokenLevel(uint256 tid, uint8 level)
		external 
		isSquad 
		nonReentrant
		levelInBounds(level)
	{
		setStorageTokenIDHash(tid, level);
	}

	//@dev [BULK UPDATE] "Level up" multiple addresses at once to a chosen level
	// (see `updateTokenMetadata` for details)
	function bulkChangeTokenLevel(uint[] memory tids, uint8 level)
		external
		isSquad
		nonReentrant
		levelInBounds(level)
	{
		unchecked {
			uint i;
			for (i = 0; i < tids.length; i++) {
				if (!_exists(tids[i]))
					emit TokenMetadataNotUpdated(tids[i]);
				else
					setStorageTokenIDHash(tids[i], level);
			}
		}
	}

	// ----------------------------
	// BACKUP / EMERGENCY FUNCTIONS
	// ----------------------------

	//@dev Allow owners to mint however many they want at whatever level to some address
	function mint(address to, uint256 qty, uint8 level) 
		external 
		isSquad 
		nonReentrant
		levelInBounds(level) 
		enoughSupply(qty)
	{
		unchecked {
			uint currentIdx = _totalMinted();
			uint nextIdx = currentIdx + qty;

			_safeMint(to, qty);

			uint i;
			for (i = currentIdx; i < nextIdx; i++) {
				setStorageTokenIDHash(i, level);
			}
		}
	}

	//@dev Allows public addresses to purchase
	function publicPurchase(address payable to) 
		external
		payable 
		saleActive
		nonReentrant
		purchaseArgsOK(to, 1, msg.value)
	{
		_safeMint(to, 1);
		setStorageTokenIDHash(_totalMinted()-1, 1);//current token id & member level (1)
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

	//@dev [BACKUP METHOD] Ability to change the ipfs hashes in `_levelHashes`
	// Allows us to change the ipfs hashes associated with all the nft's in case 
	// something goes wrong
	// NOT TO BE USED CARELESSLY!!
	function setStorageLevelHash(uint8 level, string calldata newHash) 
		external 
		isSquad 
		levelInBounds(level)
		notEqual(_levelHashes[level-1], newHash) 
	{ 
		_levelHashes[level-1] = newHash;
	}

	//@dev [BACKUP METHOD] Ability to view the ipfs hashes in `_levelHashes`
	function getStorageLevelHash(uint8 idx) external view returns (string memory)
	{
		if (0 <= idx && idx < NUM_LEVELS)
			return _levelHashes[idx];
		return "";//oob idx number
	}

	// ------------------
	// PRIVATE PERMISSION
	// ------------------

	//@dev [PRIVATE METHOD] Change the level associated with a token id `tid` 
	function setStorageTokenIDHash(uint256 tid, uint8 newLevel)
		private
		onlyValidTokenID(tid) 
		levelInBounds(newLevel)
	{ 
		if (_tidToLevel[tid] != newLevel)
			_tidToLevel[tid] = newLevel; 
	}
}