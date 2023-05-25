// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
	MemoryPointer,
	ONE_WORD,
	TWO_WORDS,
	THREE_WORDS,
	HASH_OF_ZERO_BYTES,
	PREFIX,
	ZERO_MEMORY_SLOT,
	LUCKY_NUMBER
} from "./Helpers.sol";

import {
	_getUserNonce
} from "./Storage.sol";

import {
	FIXED_PRICE,
	DECREASING_PRICE,
	OFFER,
	COLLECTION_OFFER,
	ORDER_SIZE,
	ORDER_TYPEHASH,
	ERC20_PAYMENT,
	ETH_PAYMENT,
	ASSET_ERC721,
	ASSET_ERC1155,
	TYPEHASH_AND_ORDER_SIZE,
	COLLECTION_OFFER_SIZE,
	DECREASING_PRICE_ORDER_SIZE,
	ORDER_NONCE,
	ORDER_LISTING_TIME,
	ORDER_EXPIRATION_TIME,
	ORDER_MAKER,
	ORDER_ROYALTY,
	ORDER_BASE_PRICE,
	ORDER_TYPE,
	ORDER_COLLECTION,
	ORDER_ID,
	ORDER_AMOUNT,
	ORDER_PAYMENT_TOKEN,
	ORDER_TAKER,
	ORDER_RESOLVE_DATA,
	ORDER_RESOLVE_DATA_LENGTH,
	ORDER_PRICE_DECREASE_FLOOR,
	ORDER_PRICE_DECREASE_END_TIME,
	ORDER_DECREASE_FLOOR_MEMORY,
	ORDER_PRICE_DECREASE_END_TIME_MEMORY
} from "./OrderConstants.sol";

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Order Library
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>

	A library for managing supported order entities.
*/

/*
	Struct for providing information on how to fulfill the order.

		strict - flags Partial orders fulfillment strategy:
			true - if order is partially filled and order amount left is 
				lower than fulfillment.amount, order execution stops.
			false - if order is partially filled and order amount left is 
				lower than fulfillment.amount, order executed with
				available amount.
		amount - amount for ERC1155 Partial orders.
		id - token id to fulfill a Collection Offer with.
		proofs - proofs that tokenId belonges to signed collection
			offer merkle tree.
*/
struct Fulfillment {
    bool strict;
    uint256 amount;
    uint256 id;
    bytes32[] proofs;
}

/*
	Wraps the Order struct. Points to specific fulfillment
	index in the array of Fulfillments.

	fillerIndex - points to the specific fulfillment.
*/
struct Execution {
	uint256 fillerIndex;
	uint256 nonce; 
	uint256 listingTime;
	uint256 expirationTime;
	address maker; 
	address taker;
	uint256 royalty; 
	address paymentToken;
	uint256 basePrice; 
	uint256 orderType; 
	address collection; 
	uint256 id;
	uint256 amount;
	bytes resolveData;
}

/*
	Order struct. Contains parameters for trading an ERC721 or
		an ERC1155 for ETH or ERC20.

	nonce - user nonce, with which order had been signed with.
	listingTime - start of the trading period.
	expirationTime - end of the trading period.
	maker - account, which created and signed the order.
	taker - account, which supposed to fulfill the order, or
		order must be fulfilled on behalf of the account.
	royalty - index of the collection royalty, which was used
		at the time of order creation.
	paymentToken - address of the ERC20, or address(0) for ETH.
	basePrice - amount of ERC20 or ETH, item should be sold for.
	orderType - config of the order, contains:
		1. uint64 saleKind: 
			1. FixedPrice
			2. DutchAuction
			3. Offer
			4. Collection offer
		2. uint64 assetType:
			1. ERC721
			2. ERC1155
		3. uint64 fulfillmentType:
			1. Strict - entire order.amount should be filled at once.
			2. Partial - amount can be fulfilled partially.
		4. uint64 paymentType:
			1. ETH
			2. ERC20
	collection - address of the collection contract
	id - id of the token
	amount - amount of the token
	resolveData - array for additional arguments:
		1. DutchAuction - contains 64 bytes of additional arguments:
			uint256 floor - the minimum price for the decay.
			uint256 endTime - when the price should reach it's floor.
		2. CollectionOffer - contains 32 bytes of additional arguments:
			bytes32 root - root of the Merkle Tree, which contains a set
				of selected by the order.maker token ids. Can be empty,
				if CollectionOffer can be fulfilled with any id of the collection.
*/
struct Order {
	uint256 nonce;
	uint256 listingTime;
	uint256 expirationTime;
	address maker;
	address taker;
	uint256 royalty;
	address paymentToken;
	uint256 basePrice;
	uint256 orderType;
	address collection;
	uint256 id;
	uint256 amount;
	bytes resolveData;
}

// Runtime struct for processing FixedPrice listing and Offer.
struct Trade {
	address maker;
	address taker;
	uint256 royalty;
	address paymentToken;
	uint256 basePrice;
	uint256 orderType;
	address collection;
	uint256 id;
	uint256 amount;
}

/*
	Runtime struct for processing DutchAuction.

	floor - lowest boundary of the basePrice decay.
	endTime - when order price reaches floor.
*/
struct DutchAuction {
	address maker;
	address taker;
	uint256 royalty;
	address paymentToken;
	uint256 basePrice;
	uint256 orderType;
	address collection;
	uint256 id;
	uint256 amount;
	uint256 floor;
	uint256 endTime;
}

/*
	Runtime struct for processing CollectionOffer.

	rootHash - hash of the collection offer merkle tree.
*/
struct CollectionOffer {
	address maker;
	address taker;
	uint256 royalty;
	address paymentToken;
	uint256 basePrice;
	uint256 orderType;
	address collection;
	uint256 id;
	uint256 amount;
	bytes32 rootHash;
}

/**
	Creates memory pointer to the order.

	@param _memPtr Memory slot address.

	@return order Order memory type pointer.
*/
function deriveOrder(
	MemoryPointer _memPtr
) pure returns(Order memory order) {
	assembly {
		mstore(
			_memPtr,
			ORDER_TYPEHASH
		)
		order := add(_memPtr, ONE_WORD)
	}
}

using OrderLib for Order global;
using OrderLib for Execution global;
using OrderLib for Trade global;
using OrderLib for CollectionOffer global;
using OrderLib for DutchAuction global;

library OrderLib {

	/// Translates Execution to Order.
	function toOrder (
		Execution calldata _execution
	) internal pure returns (Order calldata order) {
		assembly {
			order := add(_execution, ONE_WORD)
		}
	}

	/// Shrinks Order to Trade size.
	function toTrade (
		Order memory _order
	) internal pure returns (Trade memory trade) {
		assembly {
			trade := add(_order, THREE_WORDS)
		}
	}

	/// Converts DutchAuction to Trade.
	function toTrade (
		DutchAuction memory _auction
	) internal pure returns (Trade memory trade) {
		assembly {
			trade := _auction
		}
	}

	/// Converts CollectionOffer to Trade.
	function toTrade (
		CollectionOffer memory _offer
	) internal pure returns (Trade memory trade) {
		assembly {
			trade := _offer
		}
	}

	/// Converts Order to DutchAuction.
	function toDutchAuction (
		Order memory _order
	) internal pure returns (DutchAuction memory auction) {
		assembly {
			auction := add(_order, THREE_WORDS)
		}
	}

	/// Converts Order to CollectionOffer.
	function toCollectionOffer (
		Order memory _order
	) internal pure returns (CollectionOffer memory offer) {
		assembly {
			offer := add(_order, THREE_WORDS)
		}
	}

	/**
		Read order type and cast to paymentType.

		@param _order Order memory pointer.

		@return _ Payment type value.
	*/
	function paymentType (
		Order memory _order
	) internal pure returns (uint64){
		return uint64(_order.orderType >> 192);
	}

	/**
		Read order type and cast to paymfulfillmentTypeentType.

		@param _order Order memory pointer.

		@return _ Fulfillment type value.
	*/
	function fulfillmentType (
		Order memory _order
	) internal pure returns (uint64) {
		return uint64(_order.orderType >> 128);
	}

	/**
		Read order type and cast to assetType.

		@param _order Order memory pointer.

		@return _ Asset type value.
	*/
	function assetType (
		Order memory _order
	) internal pure returns (uint64) {
		return uint64(_order.orderType >> 64);
	}

	/**
		Read order type and cast to saleKind.

		@param _order Order memory pointer.

		@return _  Sale kind value.
	*/
	function saleKind (
		Order memory _order
	) internal pure returns (uint64) {
		return uint64(_order.orderType);
	}

	/**
		Read order type and cast to paymentType.

		@param _trade Trade memory pointer.

		@return _  Payment type value.
	*/
	function paymentType (
		Trade memory _trade
	) internal pure returns (uint64){
		return uint64(_trade.orderType >> 192);
	}

	/**
		Read order type and cast to fulfillmentType.

		@param _trade Trade memory pointer.

		@return _  Fulfillment type value.
	*/
	function fulfillmentType (
		Trade memory _trade
	) internal pure returns (uint64) {
		return uint64(_trade.orderType >> 128);
	}

	/**
		Read order type and cast to assetType.

		@param _trade Trade memory pointer.

		@return _  Asset type value.
	*/
	function assetType (
		Trade memory _trade
	) internal pure returns (uint64) {
		return uint64(_trade.orderType >> 64);
	}

	/**
		Read order type and cast to saleKind.

		@param _trade Trade memory pointer.

		@return _  Sale kind value.
	*/
	function saleKind (
		Trade memory _trade
	) internal pure returns (uint64) {
		return uint64(_trade.orderType);
	}

	/**
		Validates and then allocates order.maker.

		@param _order Order memory pointer.
		@param _cdPtr Order calldata pointer.

		@return _ Flag of the maker being valid.
	*/
	function validateMaker (
		Order memory _order,
		Order calldata _cdPtr,
		address _fulfiller
	)  internal view returns (bool) {

		// Read maker address from the calldata.
		address maker;
		assembly {
			maker := calldataload(
				add(_cdPtr, ORDER_MAKER)
			)
		}
		/*
			Verify that the order maker is not the `_fulfiller`, nor the msg.sender, nor 
			the zero address.
		*/
		if (
				maker == _fulfiller ||
				maker == msg.sender ||
				maker == address(0)
			) {
				return false;
		}
		// Store maker address at the order memory pointer with an offset.
		assembly {
			mstore(
				add(_order, ORDER_MAKER),
				maker
			)
		}
		return true;
	}

	/**
		Validates and then allocates order.nonce.
		
		@param _order Order memory pointer.
		@param _cdPtr Order calldata pointer.
		@param _maker Order maker from the stack.

		@return _ Flag of the nonce being valid.
	*/
	function validateNonce (
		Order memory _order,
		Order calldata _cdPtr,
		address _maker
	) internal view  returns (bool) {

		// Read nonce from the calldata.
		uint256 nonce;
		assembly {
			nonce := calldataload(
				add(_cdPtr, ORDER_NONCE)
			)
		}
		// Verify that the order was not signed with an expired nonce.
		if (nonce < _getUserNonce(_maker)) {
			return false;
		}
		// Store nonce at the order memory pointer with an offset.
		assembly {
			mstore(
				add(_order, ORDER_NONCE),
				nonce
			)
		}
		return true;
	}

	/**
		Allocate order.orderType.

		@param _order Order memory pointer.
		@param _cdPtr Order calldata pointer.
	*/
	function allocateOrderType (
		Order memory _order,
		Order calldata _cdPtr
	) internal pure {

		//Read order type and store at the order memory pointer with an offset.
		assembly {
			mstore(
				add(_order, ORDER_TYPE),
				calldataload(
					add(_cdPtr, ORDER_TYPE)
				)
			)
		}
	}

	/**
		Return whether or not an order can be settled, verifying that the current
		block time is between order's initial listing and expiration time.

		@param _listingTime The starting time of the order being listed.
		@param _expirationTime The ending time where the order expires.

		@return _ Result of the order period check.
	*/
	function _canSettleOrder (
		uint256 _listingTime,
		uint256 _expirationTime
	) private view returns (bool) {
		return
			(_listingTime < block.timestamp) &&
			(_expirationTime == 0 || block.timestamp < _expirationTime);
	}

	/** 
		Validates trading period and allocates order.listingTime and
		order.expirationTime.
		
		@param _order Order memory pointer.
		@param _cdPtr Order calldata pointer.

		@return _ Flag of order period being valid.	
	*/
	function validateOrderPeriod (
		Order memory _order,
		Order calldata _cdPtr
	) internal view  returns (bool) {
		// Read order period boundaries from the calldata.
		uint256 listingTime_;
		uint256 expirationTime;
		assembly {
			listingTime_ := calldataload(
				add(_cdPtr, ORDER_LISTING_TIME)
			)
			expirationTime := calldataload(
				add(_cdPtr, ORDER_EXPIRATION_TIME)
			)
		}
		// Check if order is within trading period.
		if (
			!_canSettleOrder(
				listingTime_ - LUCKY_NUMBER,
				expirationTime
			)
			) {
			return false;
		}

		// Store period boundaries at the order memory slot with an offset.
		assembly {
			mstore(
				add(_order, ORDER_LISTING_TIME),
				listingTime_
			)
			mstore(
				add(_order, ORDER_EXPIRATION_TIME),
				expirationTime
			)
		}
		return true;
	}

	/**
		Allocates order.taker, order.royalty, order.basePrice, order.collection,
		order.id.

		@param _order Order memory pointer.
		@param _cdPtr Order calldata pointer.
	*/
	function allocateTradeParameters (
		Order memory _order,
		Order calldata _cdPtr
	) internal pure {
		assembly {
			/*
				Read taker from the calldata and store in the order memory slot
				with an offset.
			*/
			mstore(
				add(_order, ORDER_TAKER),
				calldataload(
					add(_cdPtr, ORDER_TAKER)
				)
			)
			/*
				Read  royalty from the calldata and store in the order memory slot
				with an offset.
			*/
			mstore(
				add(_order, ORDER_ROYALTY),
				calldataload(
					add(_cdPtr, ORDER_ROYALTY)
				)
			)
			/*
				Read taker from the calldata and store in the order memory slot
				with an offset.
			*/
			mstore(
				add(_order, ORDER_BASE_PRICE),
				calldataload(
					add(_cdPtr, ORDER_BASE_PRICE)
				)
			)
			/*
				Read collection from the calldata and store in the order memory slot
				with an offset.
			*/
			mstore(
				add(_order, ORDER_COLLECTION),
				calldataload(
					add(_cdPtr, ORDER_COLLECTION)
				)
			)
			/*
				Read id from the calldata and store in the order memory slot
				with an offset.
			*/
			mstore(
				add(_order, ORDER_ID),
				calldataload(
					add(_cdPtr, ORDER_ID)
				)
			)
		}
	}

	/**
		Validate and allocate order payment token address.
		
		@param _order Order memory pointer.
		@param _cdPtr Order calldata pointer.
		@param _saleKind Order sale kind from the stack.
		@param _paymentType Order payment type from the stack.

		@return _ Flag of payment being valid.	
	*/
	function validatePaymentType (
		Order memory _order,
		Order calldata _cdPtr,
		uint64 _saleKind,
		uint64 _paymentType
	) internal pure returns (bool) {
		/*
			Load payment token address from the calldata
			and verify that it is not a zero address.
		*/
		address paymentToken;
		assembly {
			paymentToken := calldataload(
				add(_cdPtr, ORDER_PAYMENT_TOKEN)
			)
		}

		// Validate ERC20 payment type.
		if (_paymentType == ERC20_PAYMENT) {

			if (paymentToken == address(0)) {
				return false;
			}
			// Store payment token address in the order memory slot with an offset.
			assembly{
				mstore(
					add(_order, ORDER_PAYMENT_TOKEN),
					paymentToken
				)
			}
			return true;
		}
	
		// Validate ETH payment type.
		if (_paymentType == ETH_PAYMENT) {

			if (
				paymentToken != address (0) ||
				_saleKind > 1
			) {
				return false;
			}
			// Store payment token address in the order memory slot with an offset.
			assembly{
				mstore(
					add(_order, ORDER_PAYMENT_TOKEN),
					paymentToken
				)
			}
			return true;
		}
		// Return false if payment type didn't match any known type.
		return false;
	}

	/**
		Validate and allocate order amount.

		@param _order Order memory pointer.
		@param _cdPtr Order calldata pointer.
		@param _assetType Order asset type from the stack.
	*/
	function validateAssetType ( 
		Order memory _order,
		Order calldata _cdPtr,
		uint64 _assetType
	) internal pure returns (bool){

		// Read order amount from the calldata.
		uint256 amount;
		assembly {
			amount := calldataload(
				add(_cdPtr, ORDER_AMOUNT)
			)
		}

		// Validate amount for ERC1155 asset.
		if (_assetType == ASSET_ERC1155) {
			
			if (amount == 0) {
				return false;
			}

			// Store amount in the order memory slot with an offset.
			assembly{
				mstore(
					add(_order, ORDER_AMOUNT),
					amount
				)
			}
			return true;
		}

		// Validate amount for ERC721 asset.
		if (_assetType == ASSET_ERC721) {

			if (amount != 0) {
				return false;
			}

			// Store amount in the order memory slot with an offset.
			assembly{
				mstore(
					add(_order, ORDER_AMOUNT),
					amount
				)
			}
			return true;
		}
		return false;
	}

	/**
		Validate saleKind and allocate order resolveData arguments.

		@param _order Order memory pointer.
		@param _memPtr Memory pointer for hashing order.
		@param _cdPtr Order calldata pointer.
		@param _saleKind Order sale kind from the stack.
	*/
	function validateSaleKind (
		Order memory _order,
		MemoryPointer _memPtr,
		Order calldata _cdPtr,
		uint64 _saleKind
	) internal pure returns (bytes32 hash_, bool) {

		// Read additional argument length from the calldata..
		uint256 length;
		assembly {
			length := calldataload(
				add(_cdPtr, ORDER_RESOLVE_DATA_LENGTH)
			)
		}

		// FixedPrice or Offer validation.
		if (_saleKind == FIXED_PRICE || _saleKind == OFFER) {
			
			if (length != 0) {
				return (hash_, false);
			}
			// Store precomputed hash of zero bytes at the resolveData location.
			assembly {
				mstore(
					add(_order, ORDER_RESOLVE_DATA),
					HASH_OF_ZERO_BYTES
				)
				// Derive order hash.
				hash_ := keccak256(
					_memPtr,
					TYPEHASH_AND_ORDER_SIZE
				)
				// Shift memory pointer to the end of the regular order.
				mstore(0x40, add(_order, ORDER_SIZE))
			}
			return (hash_, true);
		}

		// DecreasingPrice validation.
		if (_saleKind == DECREASING_PRICE) {

			if (length != TWO_WORDS) {
				return (hash_, false);
			}

			//Read additional arguments from the calldata.
			uint256 floor;
			uint256 endTime;
			assembly {
				floor := calldataload(add(_cdPtr, ORDER_PRICE_DECREASE_FLOOR))
				endTime := calldataload(add(_cdPtr, ORDER_PRICE_DECREASE_END_TIME))
				mstore(0, floor)
				mstore(ONE_WORD, endTime)

				/*
					Store the hash of the additional arguments at the
					resloveData location.
				*/
				mstore(
					add(_order, ORDER_RESOLVE_DATA),
					keccak256(0, TWO_WORDS)
				)
				// Derive order hash.
				hash_ := keccak256(
					_memPtr,
					TYPEHASH_AND_ORDER_SIZE
				)

				// Store floor in the order memory slot with an offset.
				mstore(
					add(_order, ORDER_DECREASE_FLOOR_MEMORY),
					floor
				)
				// Store endTime in the order memory slot with an offset.
				mstore(
					add(_order, ORDER_PRICE_DECREASE_END_TIME_MEMORY),
					endTime
				)

				// Shift memory pointer to the end of the DecreasingPrice.
				mstore(0x40, add(_order, DECREASING_PRICE_ORDER_SIZE))
			}
			return (hash_, true);
		}
		
		// CollectionOffer validation.
		if (_saleKind == COLLECTION_OFFER) {

			if (_order.id != 0) {
					return (hash_, false);
				}
			
			if (length > ONE_WORD) {
				return (hash_, false);
			}

			// If length is zero, offer can be fulfilled with any token id.
			if ( length != 0) {
				// Read rootHash from the calldata.
				bytes32 rootHash;
				assembly{
					rootHash := calldataload(add(_cdPtr, ORDER_PRICE_DECREASE_FLOOR))
					// Store rootHash in the first memory slot.
					mstore(
						0,
						rootHash
					)
					/*
						Store the hash of the rootHash at the
						resloveData location.
					*/
					mstore(
						add(_order, ORDER_RESOLVE_DATA),
						keccak256(0, ONE_WORD)
					)
					// Derive order hash.
					hash_ := keccak256(
						_memPtr,
						TYPEHASH_AND_ORDER_SIZE
					)
					// Store rootHash in the order memory slot with an offset.
					mstore(
						add(_order, ORDER_RESOLVE_DATA),
						rootHash
					)
					// Shift memory pointer to the end of the Collection Offer.
					mstore(0x40, add(_order, COLLECTION_OFFER_SIZE))
				}
			} else {
				assembly{
					// Store precomputed hash of zero bytes at the resolveData location.
					mstore(
						add(_order, ORDER_RESOLVE_DATA),
						HASH_OF_ZERO_BYTES
					)
					// Derive order hash.
					hash_ := keccak256(
						_memPtr,
						TYPEHASH_AND_ORDER_SIZE
					)
					// Store 0 in the rootHash field of the order.
					mstore(
						add(_order, ORDER_RESOLVE_DATA),
						0
					)
					// Shift memory pointer to the end of the Collection Offer.
					mstore(0x40, add(_order,COLLECTION_OFFER_SIZE))
				}
			}
			return (hash_, true);
		}
		// Did not match any kind of sale.
		return (hash_, false);
	}

	/**
		Derives order hash.

		@param _order Order calldata pointer.

		@return _ Hash of the order.
	*/
	function hash (
		Order calldata _order
	) internal pure returns (bytes32) {
		return keccak256(
			abi.encode(
				ORDER_TYPEHASH,
				_order.nonce,
				_order.listingTime,
				_order.expirationTime,
				_order.maker,
				_order.taker,
				_order.royalty,
				_order.paymentToken,
				_order.basePrice,
				_order.orderType,
				_order.collection,
				_order.id,
				_order.amount,
				keccak256(_order.resolveData)
			)
		);
	}
}