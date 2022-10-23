// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import './ERC2981ContractWideRoyalties.sol';

/// @title Music Hole NFT contract
contract MusicHole is ERC721, ERC721URIStorage, ERC721Burnable, Ownable, ERC2981ContractWideRoyalties, ReentrancyGuard {

	using Counters for Counters.Counter;
	Counters.Counter private _tokenIdCounter;

	uint256 public price;
	uint256 public max;
	string public uri;

	/// @notice constructor
	/// @param _name name of ERC-721 token
	/// @param _symbol symbol of ERC-721 token
	/// @param _uri metadata of NFT when redeeemable
	/// @param _royalties resale rights percentage (using 2 decimals: 10000 = 100%, 150 = 1.5%, 0 = 0%)
	/// @param _price price per mint (in wei)
	constructor(
		string memory _name,
		string memory _symbol,
		string memory _uri,
		uint256 _royalties,
		uint256 _price,
		uint256 _max
	)
	ERC721(_name, _symbol)
	{
		uri = _uri;
		_setRoyalties(owner(), _royalties);
		setPrice(_price);
		max = _max;
	}

	receive() external payable {
		require(false, "CANNOT_DIRECTLY_SEND_ANY_VALUE");
	}

	fallback() external payable {
		require(false, "CANNOT_DIRECTLY_SEND_ANY_DATA");
	}

	function totalSupply()
		public
		view
		returns (uint256)
	{
		return _tokenIdCounter.current();
	}

	/// @notice mint NFT
	function mint()
		payable
		public
		nonReentrant
	{
		require(msg.value == price, "MSG_VALUE_DOES_NOT_MATCH_PRICE");
		require(_tokenIdCounter.current() < max, "CANNOT_MINT_MORE_THAN_MAX");
		_tokenIdCounter.increment();
		_safeMint(msg.sender, _tokenIdCounter.current());
		_setTokenURI(_tokenIdCounter.current(), uri);
		payable(owner()).transfer(msg.value);
	}

	/// @notice only owner can mint without paying
	function adminMint(uint256 _amount)
		public
		onlyOwner
	{
		for(uint256 i=0 ; i<_amount ; i++) 
		{
			require(_tokenIdCounter.current() < max, "CANNOT_MINT_MORE_THAN_MAX");
			_tokenIdCounter.increment();
			_safeMint(msg.sender, _tokenIdCounter.current());
			_setTokenURI(_tokenIdCounter.current(), uri);
		}
	}

	/// @notice mint NFT
	/// @param _price price per mint (in wei)
	function setPrice(uint _price)
		payable
		public
		onlyOwner
	{
		price = _price;
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId)
		internal
		override(ERC721)
	{
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function _afterTokenTransfer(address from, address to, uint256 tokenId)
		internal
		override(ERC721)
	{
		super._afterTokenTransfer(from, to, tokenId);
	}

	function burn(uint256 tokenId) public override {
		require(_exists(tokenId), "Redeem query for nonexistent token");
		require(ownerOf(tokenId) == msg.sender, "You are not the owner of this token");
		_burn(tokenId);
	}

	function _burn(uint256 tokenId)
		internal
		override(ERC721, ERC721URIStorage)
	{
		super._burn(tokenId);
	}

	function tokenURI(uint256 tokenId)
		public
		view
		override(ERC721, ERC721URIStorage)
		returns (string memory)
	{
		return super.tokenURI(tokenId);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721, ERC2981ContractWideRoyalties)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}
}