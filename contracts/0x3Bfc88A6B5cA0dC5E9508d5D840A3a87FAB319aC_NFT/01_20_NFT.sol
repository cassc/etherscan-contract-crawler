//SPDX-License-Identifier: Unlicensed

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Multicall.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';

import '../interface/INFT.sol';

pragma solidity ^0.8.0;

contract NFT is ERC721, ERC721Enumerable, ERC2981, ERC721URIStorage, Ownable, INFT, Multicall {
	///@notice counters to count tokens minted
	///@dev counters to keep track of tokens
	using Counters for Counters.Counter;
	Counters.Counter private _tokenIds;

	///@notice blockNumber when contract is deployed
	uint256 public blockNumber;

	constructor() ERC721('ArtSwap', 'Art') {
		blockNumber = block.number;
	}

	modifier onlyTokenOwner(uint256 _tokenId) {
		address owner = ownerOf(_tokenId);
		require(owner == msg.sender, 'Not Authorized');
		_;
	}

	///@notice mint the nfts
	///@param _tokenURI uri of the nft to be minted
	///@param _to address to mint the token
	///@dev anyone can mint
	function mint(string calldata _tokenURI, address _to) public override returns (uint256) {
		uint256 newId = _tokenIds.current();
		_tokenIds.increment();
		_mint(_to, newId);
		_setTokenURI(newId, _tokenURI);
		return newId;
	}

	///@notice burn the given tokenId
	///@param _tokenId token Id to be burned
	///@dev only TokenOwner can burn his/her nft
	function burn(uint256 _tokenId) public override onlyTokenOwner(_tokenId) {
		_burn(_tokenId);
	}

	///@notice check the existence of given tokenId
	///@param _tokenId token Id to check
	function checkNft(uint256 _tokenId) public view override returns (bool exist) {
		return _exists(_tokenId);
	}

	///@notice set the royalty fee for the artist
	///@param _tokenId token id for which royalty is to be fixed
	///@param _receiver address of the artist
	///@param _feeNumerator royalty amount
	///@dev ERC2981 standard function to set artist royalty
	function setArtistRoyalty(
		uint256 _tokenId,
		address _receiver,
		uint96 _feeNumerator
	) public override {
		_setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
	}

	///@notice get the artist royalty info
	///@param _tokenId token id of nft
	///@param _salePrice selling amount
	///@dev provides royalty info for given token id with given selling price
	function getRoyaltyInfo(uint256 _tokenId, uint256 _salePrice)
		public
		view
		override(INFT)
		returns (address reciever, uint256 _rate)
	{
		return royaltyInfo(_tokenId, _salePrice);
	}

	// overrides base ERC721 contract's function

	function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
		super._burn(tokenId);
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal override(ERC721, ERC721Enumerable) {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721, ERC721Enumerable, ERC2981)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}

	function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage, INFT) returns (string memory) {
		return super.tokenURI(tokenId);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public override(ERC721, INFT) {
		return super.safeTransferFrom(from, to, tokenId);
	}

	function ownerOf(uint256 tokenId) public view override(ERC721, INFT) returns (address) {
		return super.ownerOf(tokenId);
	}

	function setApprovalForAll(address operator, bool approved) public override(ERC721, INFT) {
		return super.setApprovalForAll(operator, approved);
	}

	function approve(address _to, uint256 _tokenId) public override(ERC721, INFT) {
		return super.approve(_to, _tokenId);
	}
}