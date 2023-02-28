// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
     ::::::::      :::     ::::::::: ::::::::::: 
    :+:    :+:   :+: :+:   :+:    :+:    :+:     
    +:+         +:+   +:+  +:+    +:+    +:+     
    +#+        +#++:++#++: +#++:++#:     +#+     
    +#+        +#+     +#+ +#+    +#+    +#+     
    #+#    #+# #+#     #+# #+#    #+#    #+#     
     ########  ###     ### ###    ###    ###     

    UAE NFT - Art Dubai Cart
    All rights reserved 2023
    Developed by DeployLabs.io ([email protected])
*/

import "./ArtDubai.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Art Dubai Cart
 * @author DeployLabs.io
 *
 * @dev This contract is used for batch minting of Art Dubai NFTs.
 */
contract ArtDubaiCart is Ownable, ReentrancyGuard {
	enum CollectionName {
		Alexis,
		Jason
	}

	/**
	 * @dev The cart item for batch minting.
	 *
	 * @param signaturePackage The signature package.
	 * @param tokenId The token ID.
	 * @param quantity The quantity to mint.
	 */
	struct CartItem {
		SignaturePackage signaturePackage;
		uint8 tokenId;
		uint16 quantity;
	}

	event TokenMinted(CollectionName indexed collectionName, uint8 indexed tokenId, uint16 quantity);

	mapping(CollectionName => ArtDubai) private s_collections;

	constructor(ArtDubai alexisCollection, ArtDubai jasonCollection) {
		s_collections[CollectionName.Alexis] = alexisCollection;
		s_collections[CollectionName.Jason] = jasonCollection;
	}

	/**
	 * @dev Batch mint NFTs from the cart.
	 *
	 * @param alexisCartItems The cart items for the Alexis collection.
	 * @param jasonCartItems The cart items for the Jason collection.
	 * @param mintTo The address to mint the NFTs to.
	 */
	function cartMint(
		CartItem[] calldata alexisCartItems,
		CartItem[] calldata jasonCartItems,
		address mintTo
	) external payable nonReentrant {
		_mintArtDubaiTokens(CollectionName.Alexis, alexisCartItems, mintTo);
		_mintArtDubaiTokens(CollectionName.Jason, jasonCartItems, mintTo);

		uint256 change = address(this).balance;
		if (change > 0) payable(msg.sender).transfer(change);
	}

	/**
	 * @dev Set the Art Dubai collection address.
	 *
	 * @param collectionName The name of the collection.
	 * @param collection The collection address.
	 */
	function setCollectionContract(
		CollectionName collectionName,
		ArtDubai collection
	) external onlyOwner {
		s_collections[collectionName] = collection;
	}

	/**
	 * @dev Get the addresses of the collections.
	 *
	 * @return alexisCollection The Alexis collection address.
	 * @return jasonCollection The Jason collection address.
	 */
	function getCollectionAddresses()
		external
		view
		returns (address alexisCollection, address jasonCollection)
	{
		alexisCollection = address(s_collections[CollectionName.Alexis]);
		jasonCollection = address(s_collections[CollectionName.Jason]);
	}

	/**
	 * @dev Mint NFTs from the cart.
	 *
	 * @param collectionName The name of the collection.
	 * @param cartItems The cart items.
	 * @param mintTo The address to mint the NFTs to.
	 */
	function _mintArtDubaiTokens(
		CollectionName collectionName,
		CartItem[] calldata cartItems,
		address mintTo
	) internal {
		ArtDubai collection = s_collections[collectionName];

		for (uint8 i = 0; i < cartItems.length; i++) {
			CartItem memory cartItem = cartItems[i];
			SaleConditions memory saleCondition = collection.getSaleConditions(cartItem.tokenId);

			uint16 remainingSupply = saleCondition.supplyLimit -
				uint16(collection.totalSupply(cartItem.tokenId));
			uint16 remainingTokensPerWallet = saleCondition.maxTokensPerWallet -
				collection.getMintedCount(cartItem.tokenId, mintTo);
			uint16 quantityToMint = _min(cartItem.quantity, remainingSupply, remainingTokensPerWallet);

			uint256 cost = saleCondition.weiTokenPrice * quantityToMint;

			collection.mint{ value: cost }(
				cartItem.signaturePackage,
				mintTo,
				cartItem.tokenId,
				quantityToMint
			);

			emit TokenMinted(collectionName, cartItem.tokenId, quantityToMint);
		}
	}

	/**
	 * @dev Returns the minimum of three numbers.
	 *
	 * @param a The first number.
	 * @param b The second number.
	 * @param c The third number.
	 *
	 * @return minimal The minimum of the two numbers.
	 */
	function _min(uint16 a, uint16 b, uint16 c) internal pure returns (uint16 minimal) {
		minimal = a < b ? a : b;
		minimal = minimal < c ? minimal : c;
	}
}