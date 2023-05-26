// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract RichKids is ERC721Enumerable, Ownable {
	//call up functions
	using Strings for uint256;

	//global variables
	uint256 public constant RK_PRIVATE = 1600;
	uint256 public constant RK_PUBLIC = 5827;
	uint256 public constant RK_MAX = RK_PRIVATE + RK_PUBLIC;
	uint256 public constant RK_PRICE = 0.09 ether;
	uint256 public constant RK_PER_MINT = 20;

	//private variables addresses
	address private _signerAddress;
	address private _withdraw1 = 0x874552a6902841A3f8A4eE5B9427982E3930782D;
	address private _withdraw2 = 0x39C280B23b892a32ad7867497d45fAd2Be02D519;
	string private _contractURI;
	string private _tokenBaseURI;

	//mappings
	mapping(address => bool) public presalerList;
	mapping(address => uint256) public presalerListPurchases;

	//contract states
	uint256 public publicAmountMinted;
	uint256 public privateAmountMinted;
	uint256 public presalePurchaseLimit = 2;
	bool public presaleLive;
	bool public saleLive;
	bool public locked;

	constructor() ERC721('RichKids', 'RKS') {
		for (uint256 i = 0; i < 100; i++) {
			_signerAddress = _msgSender();
			_safeMint(_signerAddress, totalSupply() + 1);
		}
	}

	modifier notLocked() {
		require(!locked, 'Contract metadata methods are locked');
		_;
	}

	//whitelisted addresses that will be able to mint before public launch
	function addToPresaleList(address[] calldata entries) external onlyOwner {
		for (uint256 i = 0; i < entries.length; i++) {
			address entry = entries[i];
			require(entry != address(0), 'NULL_ADDRESS');
			require(!presalerList[entry], 'DUPLICATE_ENTRY');

			presalerList[entry] = true;
		}
	}

	//removes addresses from whitelisted users
	function removeFromPresaleList(address[] calldata entries)
		external
		onlyOwner
	{
		for (uint256 i = 0; i < entries.length; i++) {
			address entry = entries[i];
			require(entry != address(0), 'NULL_ADDRESS');

			presalerList[entry] = false;
		}
	}

	//allows users to mint a richkid
	function buy(uint256 tokenQuantity) external payable {
		require(saleLive, 'SALE_CLOSED');
		require(!presaleLive, 'ONLY_PRESALE');

		require(totalSupply() < RK_MAX, 'OUT_OF_STOCK');
		require(publicAmountMinted + tokenQuantity <= RK_PUBLIC, 'EXCEED_PUBLIC');
		require(tokenQuantity <= RK_PER_MINT, 'EXCEED_RK_PER_MINT');
		require(RK_PRICE * tokenQuantity <= msg.value, 'INSUFFICIENT_ETH');

		for (uint256 i = 0; i < tokenQuantity; i++) {
			publicAmountMinted++;
			_safeMint(msg.sender, totalSupply() + 1);
		}
	}

	function presaleBuy(uint256 tokenQuantity) external payable {
		require(!saleLive && presaleLive, 'PRESALE_CLOSED');
		require(presalerList[msg.sender], 'NOT_QUALIFIED');
		require(totalSupply() < RK_MAX, 'OUT_OF_STOCK');
		require(
			privateAmountMinted + tokenQuantity <= RK_PRIVATE,
			'EXCEED_PRIVATE'
		);
		require(
			presalerListPurchases[msg.sender] + tokenQuantity <= presalePurchaseLimit,
			'EXCEED_ALLOC'
		);
		require(RK_PRICE * tokenQuantity <= msg.value, 'INSUFFICIENT_ETH');

		for (uint256 i = 0; i < tokenQuantity; i++) {
			privateAmountMinted++;
			presalerListPurchases[msg.sender]++;
			_safeMint(msg.sender, totalSupply() + 1);
		}
	}

	function withdraw() external onlyOwner {
		payable(_withdraw1).transfer(address(this).balance / 2);
		payable(_withdraw2).transfer(address(this).balance);
	}

	function isPresaler(address addr) external view returns (bool) {
		return presalerList[addr];
	}

	function presalePurchasedCount(address addr) external view returns (uint256) {
		return presalerListPurchases[addr];
	}

	// Owner functions for enabling presale, sale, revealing and setting the provenance hash
	function lockMetadata() external onlyOwner {
		locked = true;
	}

	function togglePresaleStatus() external onlyOwner {
		presaleLive = !presaleLive;
	}

	function toggleSaleStatus() external onlyOwner {
		saleLive = !saleLive;
	}

	function setContractURI(string calldata URI) external onlyOwner notLocked {
		_contractURI = URI;
	}

	function setBaseURI(string calldata URI) external onlyOwner notLocked {
		_tokenBaseURI = URI;
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function tokenURI(uint256 tokenId)
		public
		view
		override(ERC721)
		returns (string memory)
	{
		require(_exists(tokenId), 'Cannot query non-existent token');

		return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
	}
}