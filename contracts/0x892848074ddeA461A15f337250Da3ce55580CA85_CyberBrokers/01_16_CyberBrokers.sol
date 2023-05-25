// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "./CyberBrokersMetadata.sol";

contract CyberBrokers is ERC721Burnable, Ownable
{
	// Contracts
	CyberBrokersMetadata public cyberBrokersMetadata;

	// Metadata information
	string private _baseUri = 'https://cyberbrokers.io/api/cyberbroker/';

	// Minter address
	address public cyberBrokersMintContract;

	// Constants
	uint256 constant public TOTAL_CYBERBROKERS = 10001;

	// Keeping track
	uint256 public totalMinted = 0;
	uint256 public totalUnplugged = 0;

	// Metadata provenance hash
	string public provenanceHash = "c235983e3a4834b2fe7c153da0123f03b7d50e1e80537782fa8d73e642d799fa";

	constructor(
		address _CyberBrokersMetadataAddress
	)
		ERC721("CyberBrokers", "CYBERBROKERS")
	{
		// Set the addresses
		setCyberBrokersMetadataAddress(_CyberBrokersMetadataAddress);

		// Mint Asherah to Josie
		_mintCyberBroker(0x2999377CD7A7b5FC9Fd61dB33610C891602Ce037, 0);
	}


	/**
	 * Metadata functionality
	 **/
	function setCyberBrokersMetadataAddress(address _CyberBrokersMetadataAddress) public onlyOwner {
		cyberBrokersMetadata = CyberBrokersMetadata(_CyberBrokersMetadataAddress);
	}

	function setBaseUri(string calldata _uri) public onlyOwner {
		_baseUri = _uri;
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return _baseUri;
	}

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

		if (cyberBrokersMetadata.hasOnchainMetadata(tokenId)) {
			return cyberBrokersMetadata.tokenURI(tokenId);
		}

		return super.tokenURI(tokenId);
	}

	function render(uint256 _tokenId)
		external view
		returns (string memory)
	{
		require(_exists(_tokenId), "Non-existent token to render.");
		return cyberBrokersMetadata.render(_tokenId);
	}


	/**
	 * Wrapper for Enumerable functions: totalSupply & getTokens
	 **/
	function totalSupply() public view returns (uint256) {
		return totalMinted - totalUnplugged;
	}

	// Do not use this on-chain, it's O(N)
	// This is why we use a non-standard name instead of tokenOfOwnerByIndex
	function getTokens(address addr) public view returns (uint256[] memory) {
		// Prepare array of tokens
		uint256 numTokensOwned = balanceOf(addr);
		uint[] memory tokens = new uint[](numTokensOwned);

		uint256 currentTokensIdx;
		for (uint256 idx; idx < TOTAL_CYBERBROKERS; idx++) {
			if (_exists(idx) && ownerOf(idx) == addr) {
				tokens[currentTokensIdx++] = idx;

				if (currentTokensIdx == numTokensOwned) {
					break;
				}
			}
		}

		return tokens;
	}


	/**
	 * Minting functionality
	 **/
	function setMintContractAddress(address _mintContract) public onlyOwner {
		cyberBrokersMintContract = _mintContract;
	}

	function mintCyberBrokerFromMintContract(address to, uint256 tokenId) external {
		require(msg.sender == cyberBrokersMintContract, "Only mint contract can mint");
		_mintCyberBroker(to, tokenId);
	}

	function _mintCyberBroker(address to, uint256 tokenId) private {
		require(totalMinted < TOTAL_CYBERBROKERS, "Max CyberBrokers minted");
		_mint(to, tokenId);
		totalMinted++;
	}


	/**
	 * Burn & unplug: alias for burn
	 **/
	function burn(uint256 tokenId) public virtual override {
		super.burn(tokenId);
		totalUnplugged++;
	}

	function unplug(uint256 tokenId) public {
		burn(tokenId);
	}


	/**
	 * Withdraw functions
	 **/
	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		(bool success,) = msg.sender.call{value: balance}('');
		require(success, 'Fail Transfer');
	}


	/**
	 * On-Chain Royalties & Interface
	 **/
	function supportsInterface(bytes4 interfaceId)
		public
		view
		override
		returns (bool)
	{
		return
			interfaceId == this.royaltyInfo.selector ||
			super.supportsInterface(interfaceId);
	}

	function royaltyInfo(uint256, uint256 amount)
		public
		view
		returns (address, uint256)
	{
		// 5% royalties
		return (owner(), (amount * 500) / 10000);
	}

}