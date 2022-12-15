// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Sales Library
	@author Project Wyvern Developers
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>

	A library for managing supported sale types and sale helper functions.

	@custom:date December 4th, 2022.
*/
library Sales {

	/**
		An enum to track the possible sides of an order to be fulfilled.

		@param Buy A buy order is one in which an offer was made to buy an item.
		@param Sell A sell order is one in which a listing was made to sell an item.
	*/
	enum Side {
		Buy,
		Sell
	}

	/**
		An enum to track the different types of order that can be fulfilled.

		@param FixedPrice A listing of an item for sale by a seller at a static 
			price.
		@param DecreasingPrice A listing of an item for sale by a seller at a price 
			that decreases linearly each second based on extra fields specified in an 
			order.
		@param DirectListing A listing of an item for sale by a seller at a static 
			price fulfillable only by a single buyer specified by the seller.
		@param DirectOffer An offer with a static price made by a buyer for an item 
			owned by a specific seller.
		@param Offer An offer with a static price made by a buyer for an item. The 
			offer is valid no matter who the holder of the item is.
		@param CollectionOffer An offer with a static price made by a buyer for any 
			item in a collection. Any item holder in the collection may fulfill the 
			offer.
	*/
	enum SaleKind {
		FixedPrice,
		DecreasingPrice,
		DirectListing,
		DirectOffer,
		Offer,
		CollectionOffer
	}

	/**
		Return whether or not an order can be settled, verifying that the current
		block time is between order's initial listing and expiration time.

		@param _listingTime The starting time of the order being listed.
		@param _expirationTime The ending time where the order expires.
	*/
	function _canSettleOrder (
		uint _listingTime,
		uint _expirationTime
	) internal view returns (bool) {
		return
			(_listingTime < block.timestamp) &&
			(_expirationTime == 0 || block.timestamp < _expirationTime);
	}

	/**
		Calculate the final settlement price of an order.

		@param _saleKind The sale kind of an order.
		@param _basePrice The base price of the order.
		@param _extra Any extra price or time data for the order; for
			decreasing-price orders, `_extra[1]` is the floor price where price decay
			stops and `_extra[2]` is the timestamp at which the floor price is
			reached.
		@param _listingTime The listing time of the order.

		@return _ The final price of fulfilling an order.
	*/
	function _calculateFinalPrice (
		SaleKind _saleKind,
		uint _basePrice,
		uint[] memory _extra,
		uint _listingTime
	) internal view returns (uint) {

		/*
			If the sale type is a decreasing-price Dutch auction, then the price
			decreases each minute across its configured price range.
		*/
		if (_saleKind == SaleKind.DecreasingPrice) {

			/*
				If the timestamp at which price decrease concludes has been exceeded,
				the item listing price maintains its configured floor price.
			*/
			if (block.timestamp >= _extra[2]) {
				return _extra[1];
			}

			/*
				Calculate the portion of the decreasing total price that has not yet
				decayed.
			*/
			uint undecayed =

				// The total decayable portion of the price.
				(_basePrice - _extra[1]) *

				// The duration in seconds of the time remaining until total decay.
				(_extra[2] - block.timestamp) /

				/*
					The duration in seconds between the order listing time and the time
					of total decay.
				*/
				(_extra[2] - _listingTime);

			// Return the current price as the floor price plus the undecayed portion.
			return _extra[1] + undecayed;

		// In all other types of order sale, the price is entirely static.
		} else {
			return _basePrice;
		}
	}
}