// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * DG Realta Parallela Collection.
 * https://drops.unxd.com/dgfamily
 */
contract DGRealtaParallela is ERC721A, ERC721ABurnable, Pausable, Ownable {

	// royalty percentage for secondary sales in UNXD marketplace.
	uint256 public royaltyPercentage = 10;

	// status flag for when minting is allowed. once the required amount of tokens are minted, this will be stopped.
	bool public mintingAllowed = true;

	// base uri for collection.
	string private baseURI = "https://nfts.unxd.com/nfts/dg-realta-parallela/";

	// royalty % change event.
	event RoyaltyPercentageChanged(uint256 indexed newPercentage);

	// minting status change event.
	event MintingStatusChanged(bool indexed status);

	// base URI updated event.
	event BaseUriUpdated(string indexed uri);

	constructor() ERC721A("DGRealtaParallela", "DGRP") {}

	/*****************************************************************************************************
	* Override default start index.
	*****************************************************************************************************/
	function _startTokenId() internal pure override returns (uint256) {
		return 1;
	}

	/*****************************************************************************************************
	* Base URI for collection metadata.
	*****************************************************************************************************/

	function setBaseURI(string memory newBaseURI) external onlyOwner {
		baseURI = newBaseURI;
		emit BaseUriUpdated(baseURI);
	}

	function _baseURI() internal view override returns (string memory) {
		return baseURI;
	}

	/*****************************************************************************************************
	* Pause mint and transfers.
	*****************************************************************************************************/
	function pause() public onlyOwner {
		_pause();
	}

	/*****************************************************************************************************
	* Unpause mint and transfers.
	*****************************************************************************************************/
	function unpause() public onlyOwner {
		_unpause();
	}

	/*****************************************************************************************************
	* Before token transfer hook. Activate whenNotPaused check.
	*****************************************************************************************************/
	function _beforeTokenTransfers(
		address from,
		address to,
		uint256 startTokenId,
		uint256 quantity
	)
		internal
		whenNotPaused
		override(ERC721A)
	{
		super._beforeTokenTransfers(from, to, startTokenId, quantity);
	}

	/*****************************************************************************************************
	* Transfer From
	* @param from: from address
	* @param to: destination address
	* @param tokenId: tokenId to transfer
	*****************************************************************************************************/
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	)
		public
		whenNotPaused
		override(ERC721A)
	{
		super.transferFrom(from, to, tokenId);
	}

	/*****************************************************************************************************
	* Safe Transfer From
	* @param from: from address
	* @param to: destination address
	* @param tokenId: tokenId to transfer
	* @param data: additional data field
	*****************************************************************************************************/
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory data
	)
		public
		whenNotPaused
		override(ERC721A)
	{
		super.safeTransferFrom(from, to, tokenId, data);
	}

	/*****************************************************************************************************
	 * @notice Stops minting. Once required amount of tokens are minted, minting will be stopped forever.
     * @dev Emits "MintingStatusChanged"
     *****************************************************************************************************/
	function endMinting()
		external
		onlyOwner
	{
		require(mintingAllowed, "MINTING_IS_ALREADY_STOPPED");
		mintingAllowed = false;
		emit MintingStatusChanged(false);
	}

	/*****************************************************************************************************
	 * @notice Sets royalty percentage for secondary sale
     * @dev Emits "RoyaltyPercentageChanged"
     * @param percentage The percentage of royalty to be deducted
     *****************************************************************************************************/
	function setRoyaltyPercentage(uint256 percentage)
		external
		onlyOwner
	{
		royaltyPercentage = percentage;
		emit RoyaltyPercentageChanged(royaltyPercentage);
	}

	/*****************************************************************************************************
	 * Get royalty amount at any specific price.
	 * @param price: price for sale.
     *****************************************************************************************************/
	function getRoyaltyInfo(uint256 price)
		external
		view
		returns (uint256 royaltyAmount, address royaltyReceiver)
	{
		require(price > 0, "PRICE_CAN_NOT_BE_ZERO");
		uint256 royalty = (price * royaltyPercentage)/100;
		return (royalty, owner());
	}

	/*****************************************************************************************************
	 * Mint NFT
	 * @param to: destination address.
	 * @param quantity: quantity to mint.
     *****************************************************************************************************/
	function mint(address to, uint256 quantity)
		public
		onlyOwner
		whenNotPaused
	{
		require(mintingAllowed, "MINTING_IS_STOPPED");
		_mint(to, quantity);
	}

	/*****************************************************************************************************
	 * Batch Mint NFTs
	 * @param to: array of destination addresses.
	 * @param amounts: array of quantities to mint to specific address.
     *****************************************************************************************************/
	function batchMint(address[] memory to, uint256[] memory amounts)
		public
		onlyOwner
		whenNotPaused
	{
		require(mintingAllowed, "MINTING_IS_STOPPED");
		require(to.length == amounts.length, "INVALID_DATA");
		for (uint256 i = 0; i < to.length; i = i + 1) {
			_mint(to[i], amounts[i]);
		}
	}

}