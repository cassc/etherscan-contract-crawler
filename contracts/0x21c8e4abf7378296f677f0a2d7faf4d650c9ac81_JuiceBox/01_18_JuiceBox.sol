// SPDX-License-Identifier: MIT
/*
 * JuiceBox.sol
 *
 * Created: October 27, 2021
 *
 * Price: FREE
 * Rinkeby: 0x09494437a042494eAdA9801A85eE494cFB27D75b
 * Mainnet:
 *
 * Description: An ERC-721 token that will be claimable by anyone who owns 'the Plug'
 *
 *  - There will be 4 variations, each with a different rarity (based on how likely it is
 *    to receive, i.e. v1:60%, v2:20%, v3:15%, v4:5%)
 *  - Owners with multiple Plugs will benefit through a distribution scheme that shifts 
 *    the probability of minting each variation towards 25%
 */

pragma solidity >=0.5.16 <0.9.0;

import "./Kasbeer721.sol";

//@title Juice Box
//@author Jack Kasbeer (gh:@jcksber, tw:@satoshigoat, ig:overprivilegd)
contract JuiceBox is Kasbeer721 {

	// -------------
	// EVENTS & VARS
	// -------------

	event JuiceBoxMinted(uint256 indexed a);
	event JuiceBoxBurned(uint256 indexed a);

	//@dev This is how we'll keep track of who has already minted a JuiceBox
	mapping (address => bool) internal _boxHolders;

	//@dev Keep track of which token ID is associated with which hash
	mapping (uint256 => string) internal _tokenToHash;

	//@dev Initial production hashes
	string [NUM_ASSETS] boxHashes = ["QmbZH1NZLvUTqeaHXH37fVnb7QHcCFDsn4QKvicM1bmn5j", 
									 "QmVXiZFCwxBiJQJCpiSCKz8TkaWmnEBpT6stmxYqRK4FeY", 
									 "Qmds7Ag48sfeodwmtWmTokFGZoHiGZXYN2YbojtjTR7GhR", 
									 "QmeUPdEvAU5sSEv1Nwixbu1oxkSFCY194m8Drm9u3rtVWg"];
									 //cherry, berry, kiwi, lemon

	//@dev Associated weights of probability for hashes
	uint16 [NUM_ASSETS] boxWeights = [60, 23, 15, 2];//cherry, berry, kiwi, lemon

	//@dev Secret word to prevent etherscan claims
	string private _secret;

	constructor(string memory secret) Kasbeer721("Juice Box", "") {
		_whitelistActive = true;
		_secret = secret;
		_contractUri = "ipfs://QmdafigFsnSjondbSFKWhV2zbCf8qF5xEkgNoCYcnanhD6";
		payoutAddress = 0x6b8C6E15818C74895c31A1C91390b3d42B336799;//logik
	}

	// -----------
	// RESTRICTORS
	// -----------

	modifier boxAvailable()
	{
		require(getCurrentId() < MAX_NUM_TOKENS, "JuiceBox: no JuiceBox's left to mint");
		_;
	}

	modifier tokenExists(uint256 tokenId)
	{
		require(_exists(tokenId), "JuiceBox: nonexistent token");
		_;
	}

	// ---------------
	// JUICE BOX MAGIC 
	// ---------------

	//@dev Override 'tokenURI' to account for asset/hash cycling
	function tokenURI(uint256 tokenId) 
		public view virtual override tokenExists(tokenId) 
		returns (string memory) 
	{	
		return string(abi.encodePacked(_baseURI(), _tokenToHash[tokenId]));
	}

	//@dev Get the secret word
	function _getSecret() private view returns (string memory)
	{
		return _secret;
	}

	//// ----------------------
    //// IPFS HASH MANIPULATION
    //// ----------------------

    //@dev Get the hash stored at `idx` 
	function getHashByIndex(uint8 idx) public view hashIndexInRange(idx)
	  returns (string memory)
	{
		return boxHashes[idx];
	}

	//@dev Allows us to update the IPFS hash values (one at a time)
	// 0:cherry, 1:berry, 2:kiwi, 3:lemon
	function updateHashForIndex(uint8 idx, string memory str) 
		public isSquad hashIndexInRange(idx)
	{
		boxHashes[idx] = str;
	}

    // ------------------
    // MINTING & CLAIMING
    // ------------------

    //@dev Allows owners to mint for free
    function mint(address to) public virtual override isSquad boxAvailable
    	returns (uint256 tid)
    {
    	tid = _mintInternal(to);
    	_assignHash(tid, 1);
    }

    //@dev Mint a specific juice box (owners only)
    function mintWithHash(address to, string memory hash) public isSquad returns (uint256 tid)
    {
    	tid = _mintInternal(to);
    	_tokenToHash[tid] = hash;
    }

    //@dev Claim a JuiceBox if you're a Plug holder
    function claim(address to, uint8 numPlugs, string memory secret) public 
    	boxAvailable whitelistEnabled onlyWhitelist(to) saleActive
    	returns (uint256 tid, string memory hash)
    {
    	require(!_boxHolders[to], "JuiceBox: cannot claim more than 1");
    	require(!_isContract(to), "JuiceBox: silly rabbit :P");
    	require(_stringsEqual(secret, _getSecret()), "JuiceBox: silly rabbit :P");

    	tid = _mintInternal(to);
    	hash = _assignHash(tid, numPlugs);
    }

	//@dev Mints a single Juice Box & updates `_boxHolders` accordingly
	function _mintInternal(address to) internal virtual returns (uint256 newId)
	{
		_incrementTokenId();

		newId = getCurrentId();

		_safeMint(to, newId);
		_markAsClaimed(to);

		emit JuiceBoxMinted(newId);
	}

	//@dev Based on the number of Plugs owned by the sender, randomly select 
	// a JuiceBox hash that will be associated with their token id
	function _assignHash(uint256 tid, uint8 numPlugs) private tokenExists(tid)
		returns (string memory hash)
	{
		uint8[] memory weights = new uint8[](NUM_ASSETS);
		//calculate new weights based on `numPlugs`
		if (numPlugs > 50) numPlugs = 50;
		weights[0] = uint8(boxWeights[0] - 35*((numPlugs-1)/50));//cherry: 60% -> 25%
		weights[1] = uint8(boxWeights[1] +  2*((numPlugs-1)/50));//berry:  23% -> 25%
		weights[2] = uint8(boxWeights[2] + 10*((numPlugs-1)/50));//kiwi:   15% -> 25%
		weights[3] = uint8(boxWeights[3] + 23*((numPlugs-1)/50));//lemon:   2% -> 25%

		uint16 rnd = random() % 100;//should be b/n 0 & 100
		//randomly select a juice box hash
		uint8 i;
		for (i = 0; i < NUM_ASSETS; i++) {
			if (rnd < weights[i]) {
				hash = boxHashes[i];
				break;
			}
			rnd -= weights[i];
		}
		//assign the selected hash to this token id
		_tokenToHash[tid] = hash;
	}

	//@dev Update `_boxHolders` so that `a` cannot claim another juice box
	function _markAsClaimed(address a) private
	{
		_boxHolders[a] = true;
	}

	function getHashForTid(uint256 tid) public view tokenExists(tid) 
		returns (string memory)
	{
		return _tokenToHash[tid];
	}

	//@dev Pseudo-random number generator
	function random() public view returns (uint16 rnd)
	{
		return uint16(uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, boxWeights))));
	}
}