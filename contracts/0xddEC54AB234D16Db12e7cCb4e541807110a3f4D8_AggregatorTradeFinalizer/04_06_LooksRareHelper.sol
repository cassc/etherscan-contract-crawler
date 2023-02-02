// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/**
	@title LooksRare Helper
	@author LooksRare

	This library defines the structs needed to interface with the LooksRare 
	exchange for fulfilling aggregated orders.
*/
library LooksRareHelper {

	/**
		This struct defines the maker side of a LooksRare order.

		@param isOrderAsk Whether the order is an ask or a bid.
		@param signer The address of the order signer.
		@param collection The address of the NFT collection.
		@param price The price of fulfilling the order.
		@param tokenId The ID of the NFT in the order.
		@param amount The number of the specific token ID being purchased (strictly 
			one for ERC-721 items, potentially greater than one for fungible ERC-1155 
			items).
		@param strategy The strategy to use for trade execution (fixed price, 
			auction, other).
		@param currency The address of the asset being used to pay for the NFT.
		@param nonce An order nonce (unique unless overriding existing order to 
			lower asking price).
		@param startTime The start time of the order.
		@param endTime The end time of the order.
		@param minPercentageToAsk The acceptable slippage on order fulfillment.
		@param params Additional parameters.
		@param v The v component of a signature.
		@param r The r component of a signature.
		@param s The s component of a signature.
	*/
	struct MakerOrder {
		bool isOrderAsk;
		address signer;
		address collection;
		uint256 price;
		uint256 tokenId;
		uint256 amount;
		address strategy;
		address currency;
		uint256 nonce;
		uint256 startTime;
		uint256 endTime;
		uint256 minPercentageToAsk;
		bytes params;
		uint8 v;
		bytes32 r;
		bytes32 s;
	}

	/**
		This struct defines the taker side of a LooksRare order.

		@param isOrderAsk Whether the order is an ask or a bid.
		@param taker The caller fulfilling the order.
		@param price The price of fulfilling the order.
		@param tokenId The ID of the NFT in the order.
		@param minPercentageToAsk The acceptable slippage on order fulfillment.
		@param params Additional parameters.
	*/
	struct TakerOrder {
		bool isOrderAsk;
		address taker;
		uint256 price;
		uint256 tokenId;
		uint256 minPercentageToAsk;
		bytes params;
	}
}