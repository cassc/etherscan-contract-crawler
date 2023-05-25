// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// This is the Nemesis Contract
// This contract is based on the ERC721 standard, with the following extensions:
// - ERC721URIStorage: allows to set a token URI
// - ERC721Burnable: allows to burn a token
// - Ownable: allows to set a whitelist
// - Counters: allows to count the number of tokens minted

// The Contract generates NFTs and has the following features:
// - max supply
// - price
// - whitelist

// The admin can:
// - set the base URI for token metadata
// - set the price
// - set the whitelist

// The user
// - can mint a token
// - can burn a token
contract NEMESIS is ERC721, ERC721Burnable, Ownable, Pausable {
	using Counters for Counters.Counter;
	using Strings for uint256;

	//////////////////////////
	// VARIABLES
	//////////////////////////

	Counters.Counter private _tokenIdCounter; // counter for token ids

	uint256 public totalSupply = 8000;
	uint256 public totalMinted = 0;
	uint256 public price = 0.15 ether;
	bool public released = false; // if true, the URI is generated dynamically using the base URI and the token id

	mapping(address => uint256) public minted; // number of tokens minted by an address
	mapping(address => uint256) public whitelists; // whitelists for addresses

	string public baseURI; // base URI for token metadata

	//////////////////////////
	// CONSTRUCTOR
	//////////////////////////

	/**
	 * @dev Constructor
	 * @param default_uri string : default URI for token metadata
	 */
	constructor(string memory default_uri) ERC721("NEMESIS", "NMS") {
		baseURI = default_uri;
		_pause();
	}

	//////////////////////////
	// USER FUNCTIONS
	//////////////////////////

	/**
	 * @dev Mints a new token
	 * @param to | address : address of the future owner of the token
	 *
	 * requirements
	 * - msg.value must be equal to price or the sender must be whitelisted
	 * - max supply must not be reached
	 */
	function safeMint(address to, uint256 amount) public payable {
		require(!paused(), "Sale is Finished");
		uint256 current_price = 0;

		for (uint256 i = 0; i < amount; i++) {
			require(_tokenIdCounter.current() < totalSupply, "Max supply reached");

			if (!(whitelists[to] > 0 && minted[to] < whitelists[to])) current_price += price;

			uint256 tokenId = _tokenIdCounter.current();
			minted[to] += 1;
			totalMinted += 1;
			_safeMint(to, tokenId);
			_tokenIdCounter.increment();
		}
		require(msg.value == current_price, "Ether value sent is not correct");
	}

	//////////////////////////
	// ADMIN FUNCTIONS
	//////////////////////////

	/**
	 * @dev Sets the whitelist for a list of addresses
	 * @param addresses address[] : list of addresses
	 * @param limits uint256[] : list of limits
	 *
	 * requirements
	 * - addresses and limits length must match
	 * - only owner can call this function
	 */
	function addToWhitelist(address[] memory addresses, uint256[] memory limits) public onlyOwner {
		require(addresses.length == limits.length, "Addresses and limits length mismatch");

		for (uint256 i = 0; i < addresses.length; i++) {
			whitelists[addresses[i]] = limits[i];
		}
	}

	/**
	 * @dev Sets the price for minting
	 * @param _price uint256 : price in wei
	 * requirements
	 * - only owner can call this function
	 */
	function setPrice(uint256 _price) public onlyOwner {
		price = _price;
	}

	/**
	 * @dev Sets the base URI for token metadata
	 * @param __baseURI string : base URI for token metadata
	 *
	 * requirements:
	 * - only owner can call this function
	 */
	function setBaseURI(string memory __baseURI) public onlyOwner {
		baseURI = __baseURI;
	}

	/**
	 * @dev Activates the dynamic URI and Locks the Minting
	 * @param __baseURI string : base URI for token metadata
	 *
	 * requirements:
	 * - only owner can call this function
	 */
	function reveal(string memory __baseURI) public onlyOwner {
		baseURI = __baseURI;
		released = true;
	}

	/**
	 * @dev unPauses the contract
	 *
	 * requirements:
	 * - only owner can call this function
	 */
	function unpause() public onlyOwner whenPaused {
		_unpause();
	}

	/**
	 * @dev Pauses the contract
	 *
	 * requirements:
	 * - only owner can call this function
	 */
	function pause() public onlyOwner whenNotPaused {
		_pause();
	}

	/**
	 * @dev Withdraws the contract balance
	 *
	 * requirements:
	 * - only owner can call this function
	 * - contract balance must be greater than 0
	 */
	function withdraw() public onlyOwner {
		require(address(this).balance > 0, "Contract balance is 0");

		payable(msg.sender).transfer(address(this).balance);
	}

	//////////////////////////
	// VIEW FUNCTIONS
	//////////////////////////

	/**
	 * @dev See {IERC721Metadata-tokenURI}.
	 * @param tokenId uint256 ID of the token to query
	 *
	 * This is a modified version of the original function, which allows to set a base URI and a dynamic URI
	 * If dynamicURI is set to true, the URI is generated dynamically using the base URI and the token id
	 * If dynamicURI is set to false, the base URI is returned
	 *
	 * requirements:
	 * - token must be minted
	 *
	 * @return string URI for the token
	 */
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		_requireMinted(tokenId);

		if (released) return string(abi.encodePacked(baseURI, (tokenId + 1).toString(), ".json"));
		else return baseURI;
	}

	//////////////////////////
	// INTERNAL
	//////////////////////////

	/**
	 * @dev See {IERC721Metadata-_baseURI}.
	 * @return string base URI for token metadata
	 */
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}
}