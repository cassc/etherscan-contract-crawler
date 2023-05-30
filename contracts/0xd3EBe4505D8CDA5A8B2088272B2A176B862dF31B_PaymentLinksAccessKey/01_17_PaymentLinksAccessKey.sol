// SPDX-License-Identifier: MIT
/*
 * PaymentLinksAccessKey.sol
 *
 * Author: Jack Kasbeer
 * Created: November 30, 2021
 *
 * Price: 0.5 ETH
 * Rinkeby: 0x9652620B8973C85ba073D2c27B3BFd4Df0E2D812
 * Mainnet:
 *
 * Description: An ERC-721 token that will represent an access key for PaymentLinks
 *
 * - 300 total supply
 * - Blacklist functionality
 * - Pause/unpause minting
 * - Limit of 2 PLAK's per wallet
 */

pragma solidity >=0.5.16 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./PLAK721.sol";

//@title PaymentLinks Access Key
//@author Jack Kasbeer (gh:@jcksber, tw:@satoshigoat)
contract PaymentLinksAccessKey is PLAK721 {

	using Counters for Counters.Counter;
	using SafeMath for uint256;

	//this is how we'll limit it to 2 per wallet
	mapping (address => uint8) internal _walletToCount;

	constructor() PLAK721("PaymentLinks Access Key", "") {
		_contractUri = "ipfs://QmZ5bBxM8Ggz4eDzvYZmShBVMvDeJfCJ5tTBnhYnVm8L2m";
		weiPrice = 500000000000000000;//0.5 ETH
		payoutAddress = address(0x6E62733E401ceEdD8e43Dc3A85F164EFAE9b9462);
		addToWhitelist(0x6E62733E401ceEdD8e43Dc3A85F164EFAE9b9462);
		whitelistActive = true;
	}

	// -----------
	// RESTRICTORS
	// -----------

	//@dev Ensure there's enough supply remaining 
	modifier enoughSupply()
	{
		require(getCurrentId() < MAX_NUM_TOKENS, "PaymentLinksAccessKey: none left to mint");
		_;
	}

	//@dev Limit wallets to 2 tokens max
	modifier roomInWallet(address a)
	{
		require(_walletToCount[a] < 2, "PaymentLinksAccessKey: 2 per wallet max.");
		_;
	}

	//@dev Determine if a certain token ID exists
	modifier tokenExists(uint256 tokenId)
	{
		require(_exists(tokenId), "PaymentLinksAccessKey: nonexistent token");
		_;
	}

	// ---------
	// PLAK CORE
	// ---------

	//@dev Override 'tokenURI' to account for types of passes
	function tokenURI(uint256 tid) 
		tokenExists(tid) public view virtual override 
		returns (string memory) 
	{	
		string memory baseURI = _baseURI();
		string memory hash = _getTokenType(tid);
		
		return string(abi.encodePacked(baseURI, hash));
	}

	//@dev Determine if a token is disabled, standard, or legendary
	function _getTokenType(uint256 tid)
		internal view returns (string memory)
	{
		if (isDisabled(tid)) {
			return _disabledHash;
		} else if (isLegendary(tid)) {
			return _legendaryHash;
		} else {
			return _standardHash;
		}
	}

	//@dev Before transferring, take care of maintenance for wallet's token count
	// If `to` already has 2 tokens, transfer will abort
	function _beforeTokenTransfer(address from, address to, uint256 tid)
		roomInWallet(to) internal virtual override
	{
		// When this is called on a mint, the `from` address will be 0x00..
		if (from != address(0)) {
			_walletToCount[from] -= 1;//`from` loses 1
		}
		// When this is called on a burn, the `to` address will be 0x00..
		if (to != address(0)) {
			_walletToCount[to] += 1;//`to` gains 1
		}

		super._beforeTokenTransfer(from, to, tid);
	}

    //@dev Allows owners to mint for free
    function mint(address to) 
    	onlyOwner enoughSupply public virtual override
    	returns (uint256)
    {
    	return _mintInternal(to);
    }

    //@dev Allows public addresses (non-owners) to purchase
    function purchase(address payable to) 
    	enoughSupply saleActive public payable 
    	returns (bool)
    {
    	if (whitelistActive) {
    		require(isInWhitelist(to), "PaymentLinksAccessKey: address not whitelisted");
    	}
    	require(msg.value >= weiPrice, "PaymentLinksAccessKey: not enough ether");
    	
    	//send change if too much was sent
    	if (msg.value > 0) {
    		uint256 diff = msg.value.sub(weiPrice);
    		if (diff > 0) {
    	    	to.transfer(diff);
    		}
    	}
    	_mintInternal(to);

    	return true;
    }

	//@dev Mints a single PLAK
	function _mintInternal(address to) 
		roomInWallet(to) internal virtual returns (uint256)
	{
		_tokenIds.increment();
		uint256 newId = _tokenIds.current();
		_safeMint(to, newId);
		emit PaymentLinksAccessKeyMinted(newId);

		return newId;
	}

	//@dev Increase the price
	function updatePrice(uint256 newWeiPrice)
		onlyOwner public
	{
		require(newWeiPrice >= 500000000000000000, 
			"PaymentLinksAccessKey: price cannot be lower than 0.5 ETH");
		weiPrice = newWeiPrice;
	}
}