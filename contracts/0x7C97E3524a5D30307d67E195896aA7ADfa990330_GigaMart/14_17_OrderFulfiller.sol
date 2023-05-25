// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
	MemoryPointer,
	FREE_MEMORY_POINTER,
	TRANSFER_ITEM_SELECTOR,
	TRANSFER_ITEM_DATA_LENGTH,
	ERC721_ITEM_TYPE,
	ERC1155_ITEM_TYPE,
	PRECISION,
	ONE_WORD,
	TWO_WORDS,
	ONE_WORD_SHIFT,
	_freeMemoryPointer
} from "./Helpers.sol";

import {
	Fulfillment,
	Order,
	Trade,
	CollectionOffer,
	DutchAuction
} from "./Order.sol";

import {
	NativeTransfer
} from "./NativeTransfer.sol";

import {
	FIXED_PRICE,
	DECREASING_PRICE,
	OFFER,
	COLLECTION_OFFER,
	STRICT,
	PARTIAL,
	ASSET_ERC721,
	ASSET_ERC1155,
	ETH_PAYMENT,
	ERC20_PAYMENT,
	TRADE_COLLECTION,
	ORDER_IS_PARTIALLY_FILLED,
	ORDER_IS_FULFILLED,
	ORDER_RESULT_SELECTOR,
	ORDER_RESULT_DATA_LENGTH,
	SUCCESS_CODE
} from "./OrderConstants.sol";

import {
	_getProtocolFee,
	_getRoyalty,
	_getOrderFillAmount,
	_setOrderFillAmount,
	_setOrderStatus
} from "./Storage.sol";

import {
	Item,
	ItemType,
	ERC20Payment,
	IAssetHandler
} from "../../manager/interfaces/IGigaMartManager.sol";

/// Thrown if msg.value is lover than required ETH amount.
error NotEnoughValueSent();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Order Fulfiller
	@author Rostislav Khlebnikov <@catpic5buck>

	A contract for distinguishing Order execution strategy, transferring Items
	and handling payments.
*/
contract OrderFulfiller {
	using NativeTransfer for address;

	/**
		Emitted at each attempt of exchanging an item.

		@param order The hash of the order.
		@param maker The order maker's address.
		@param taker The order taker's address.
		@param data An array of bytes that contains the success status,
			order sale kind, price, payment token, target, and transfer data.
	*/
	event OrderResult (
		bytes32 order,
		address indexed maker,
		address indexed taker,
		bytes data
	);

    IAssetHandler internal immutable _ASSET_HANDLER;

	/**
		Construct a new instance of the OrderFulfiller.

		@param _assetHandler The address of the existing manager contract.
	*/
    constructor (
        IAssetHandler _assetHandler
    ){
        _ASSET_HANDLER = _assetHandler;
    }

	/**
		Helper function for emitting OrderResult
			with the error code and lesser memory usage.

		@param _code error code.
		@param _hash order hash.
		@param _trade trade parameters
	*/
	function _emitOrderFailed (
		bytes1 _code,
		bytes32 _hash,
		Trade memory _trade,
		address _taker
	) internal {
		address maker = _trade.maker;
		assembly {
			mstore(0, _hash)
			mstore(add(0, 0x20), _code)
			log3(
				0,
				0x21,
				ORDER_RESULT_SELECTOR,
				maker,
				_taker
			)
		}
	}

	/**
		Helper function for emitting OrderResult

		@param _hash order hash.
		@param _price price, with which order was fulfilled.
		@param _trade trade parameters.
		@param _id id of the token.
		@param _amount amount of traded ERC721 or ERC1155.
		@param _taker account, which fulfilled the order or on
			whose behalf order was executed..
	*/
	function _emitOrderResultSuccess (
		bytes32 _hash,
		uint256 _price,
		Trade memory _trade,
		uint256 _id,
		uint256 _amount,
		address _taker
	) private {
		// read needed parameters from the trade.
		bytes1 saleKind = bytes1(uint8(_trade.saleKind()));
		address paymentToken = _trade.paymentToken;
		address collection = _trade.collection;
		address maker = _trade.maker;

		assembly {
			// Read free memory pointer.
			let ptr := mload(0x40)
			// Allocate OrderResult data at free pointer.
			mstore(ptr, _hash)
			mstore(add(ptr, 0x20), SUCCESS_CODE)
			mstore(add(ptr, 0x21), saleKind)
			mstore(add(ptr, 0x22), _price)
			mstore(add(ptr, 0x42), shl(96, paymentToken))
			mstore(add(ptr, 0x56), shl(96, collection))
			mstore(add(ptr, 0x6a), _id)
			mstore(add(ptr, 0x8a), _amount)
			// Emit OrderResult.
			log3(
				ptr,
				ORDER_RESULT_DATA_LENGTH,
				ORDER_RESULT_SELECTOR,
				maker,
				_taker
			)
		}
	}

	/**
		Calculates and transfers payments to the seller.

		@param _trade trade parameters.
		@param _price calculated price for the order.
		@param _seller address of the item seller.
		@param _buyer address of the item buyer.

		@custom:throws NotEnoughValueSent if msg.value lower than `_price`.
		@custom:throws TransferFailed if ETH transfer fails.
	*/
	function _pay (
		Trade memory _trade,
		uint256 _price,
		address _seller,
		address _buyer
	) private returns (uint256 ethPayment) {
		// Do nothing if price is 0.
		if (_price > 0) {
			// Distinguish paymentType.
			uint64 paymentType = _trade.paymentType();

			// Execute ETH payment.
			if (paymentType == ETH_PAYMENT) {
				// Check if enough ETH is sent with the call.
				if (msg.value < _price) {
					revert NotEnoughValueSent();
				}
				// track ethPayment.
				ethPayment = _price;

				// Track amount of eth to be received by the seller.
				uint256 receiveAmount = _price;

				// Read protocol fee config.
				uint256 config = _getProtocolFee();
				if (uint96(config) != 0) {
					// Calculate fee amount.
					uint256 fee = (_price * uint96(config)) / PRECISION;
					// Transfer ETH to the fee recipient.
					address(uint160(config >> 96)).transferEth(fee);
					//Substract fee from receive.amount.
					receiveAmount -= fee;
				}

				// Read royalty fee config.
				config = _getRoyalty(_trade.collection, _trade.royalty);
				if (uint96(config) != 0) {
					// Calculate fee amount.
					uint256 fee = (_price * uint96(config)) / PRECISION;
					// Transfer ETH to the fee recipient.
					address(uint160(config >> 96)).transferEth(fee);
					//Substract fee from receiveAmount.
					receiveAmount -= fee;
				}
				// Transfer the remainder of the payment to the item seller.
				_seller.transferEth(receiveAmount);
			}

			// Execute ERC20 payment.
			if (paymentType == ERC20_PAYMENT) {
				// Track amount of ERC20 to be received by the seller.
				uint256 receiveAmount = _price;

				// Read protocol fee config.
				uint256 config = _getProtocolFee();
				if (uint96(config) != 0) {
					// Calculate fee amount.
					uint256 fee = (_price * uint96(config)) / PRECISION;
					// Transfer ERC20 to the fee recipient.
					_ASSET_HANDLER.transferERC20(
						_trade.paymentToken,
						_buyer,
						 address(uint160(config >> 96)),
						fee
					);
					//Substract fee from receiveAmount.
					receiveAmount -= fee;
				}

				// Read royalty fee config.
				config = _getRoyalty(_trade.collection, _trade.royalty);
				if (uint96(config) != 0) {
					// Calculate fee amount.
					uint256 fee = (_price * uint96(config)) / PRECISION;
					// Transfer ERC20 to the fee recipient.
					_ASSET_HANDLER.transferERC20(
						_trade.paymentToken,
						_buyer,
						 address(uint160(config >> 96)),
						fee
					);
					//Substract fee from receiveAmount.
					receiveAmount -= fee;
				}

				// Transfer the remainder of the payment to the item seller.
				_ASSET_HANDLER.transferERC20(
					_trade.paymentToken,
					_buyer,
					_seller,
					receiveAmount
				);
			}
		}
	}

	/**
		Updates order status and, in case of partial order,
		updates fill amount.

		@param _hash Hash of the order.
		@param _amount Amount fill with this call.
		@param _previousAmount Previously filled amount.
		@param _totalAmount Total order amount.
		@param _fulfillmentType Order fulfillment type.
	*/
	function _updateOrderStatus(
		bytes32 _hash,
		uint256 _amount,
		uint256 _previousAmount,
		uint256 _totalAmount,
		uint64 _fulfillmentType
	) private {
		if (_fulfillmentType == STRICT) {
			// Mark order as fulfilled.
			_setOrderStatus(
				_hash,
				ORDER_IS_FULFILLED
			);
		} else {
			/* 
				If order amount is exhausted, update order status to Fullfilled,
				if not set order status as PARTIALLY_FILLED.
			*/
			_setOrderStatus(
				_hash,
				_previousAmount + _amount < _totalAmount ?
					ORDER_IS_PARTIALLY_FILLED :
					ORDER_IS_FULFILLED
			);

			// Update order fill amount.
			_setOrderFillAmount(
				_hash,
				_previousAmount + _amount
			);
		}
	}

	/**
		Transfers item from the seller to the recipient.

		@param _trade trade parameters.
		@param _hash hash of the order.
		@param _id id of the token.
		@param _fulfillmentType order fulfillmentType.
		@param _seller address of the seller.
		@param _recipient address of the recipent.
		@param _fulfillment fulfiller struct, containing information on how to fulfill
			the order.

		@return result flags if transfer was successfull.
		@return price calculated price.
		@return amount amount of transferred item.
	*/
	function _transferItem (
		Trade memory _trade,
		bytes32 _hash,
		uint256 _id,
		uint64 _fulfillmentType,
		address _seller,
		address _recipient,
		Fulfillment calldata _fulfillment
	) private returns (
		bool result,
		uint256 price,
		uint256 amount,
		uint256 previousAmount
	) {
		// Put handler address on the stack, for using in assembly.
		IAssetHandler handler = _ASSET_HANDLER;
		// Create a memory pointer to the Item.
		Item memory item;
		// Read current free memory pointer.
		MemoryPointer memPtr = _freeMemoryPointer();

		assembly {
			// Store IAssetHandler.transferItem.selector
			mstore(
				memPtr,
				TRANSFER_ITEM_SELECTOR
			)
			// Update item pointer.
			item := add(memPtr, 0x4)
			// Store collection address as Item.collection field.
			mstore(
				add(item, 0x20),
				mload(add(_trade, TRADE_COLLECTION))
			)
			// Store seller address as Item.from field.
			mstore(
				add(item, 0x40),
				_seller
			)
			// Store recipient address as Item.to field.
			mstore(
				add(item, 0x60),
				_recipient
			)
			// Store recipient address as Item.id field.
			mstore(
				add(item, 0x80),
				_id
			)
		}

		/*
			If order.assetType is ERC721 store ItemType.ERC721 as
			Item.itemType field.
		*/ 
		if (_trade.assetType() == ASSET_ERC721) {
			// Price equals original order.basePrice.
			price = _trade.basePrice;
			//Set amount to 1. 
			amount = 1;
			assembly {
				mstore(
					item,
					ERC721_ITEM_TYPE
				)
				mstore(
					add(item, 0xa0),
					0
				) 
			}
		}

		/*
			If order.assetType is ERC1155 store ItemType.ERC1155 as
			Item.itemType field.
		*/ 
		if (_trade.assetType() == ASSET_ERC1155) {

			// Check if desired amount is greater than order.amount.
			if (_fulfillment.amount > _trade.amount) {
				return (false, 0, 0, 0);
			}

			// If fullfilmentType is STRICT.
			if (_fulfillmentType == STRICT) {
				// Amount equals original order.amount.
				amount = _trade.amount;
			}

			// If fullfilmentType is PARTIAL.
			if (_fulfillmentType == PARTIAL) {
				// Amount equals desired amount.
				amount = _fulfillment.amount;

				//Read already filled amount
				previousAmount =_getOrderFillAmount(_hash);
				// Calculate this order's leftover amount.
				uint256 leftover =_trade.amount - previousAmount;

				// If fulfillment must be strict.
				if (_fulfillment.strict) {
					// Check if leftover satisfies desired amount.
					if ( leftover < amount) {
						return (false, 0, 0, 0);
					}
				} else {
					// If fulfillment is lenient and leftover is less than desired amount.
					if ( leftover < amount) {
						// Set amount to leftover amount.
						amount = leftover;
					}
				}
			}

			assembly {
				// Store ItemType.ERC1155 as Item.itemType field.
				mstore(
					item,
					ERC1155_ITEM_TYPE
				)
				// Store amount as Item.amount field.
				mstore(
					add(item, 0xa0),
					amount
				)
			}
			// Calculate the price of this portion of order.amount.
			price = amount * _trade.basePrice / _trade.amount;
		}

		// Execute item transfer call and return it's result.
		assembly {
			result := call(
				gas(),
				handler,
				0,
				memPtr,
				TRANSFER_ITEM_DATA_LENGTH,
				0, 0
			)
		}
	}

	/**
		Contains logic for fulfilling a FixedPrice listing.

		@param _trade trade parameters.
		@param _hash hash of the order.
		@param _fulfillmentType order fulfillment type, STRICT or PARTIAL
			 in case of ERC1155.
		@param _itemRecipient recipient of the item in question.
		@param _fulfillment fulfiller struct, containing information on how to fulfill
			the order.
	*/
	function _fulfillListing (
		Trade memory _trade,
		bytes32 _hash,
		uint64 _fulfillmentType,
		address _itemRecipient,
		Fulfillment calldata _fulfillment
	) private returns (uint256, bool) {

		// Execute item transfer, calculate price and amount.
		(
			bool result,
			uint256 basePrice,
			uint256 amount,
			uint256 previousAmount
		) = _transferItem(
			_trade,
			_hash,
			_trade.id,
			_fulfillmentType,
			_trade.maker,
			_itemRecipient,
			_fulfillment
		);

		// Exit if item transfer failed.
		if (!result) {
			return (0, false);
		}

		// Pay for item, track spent ETH.
		uint256 ethPayment = _pay(
			_trade,
			basePrice,
			_trade.maker,
			msg.sender
		);

		// Update order status.
		_updateOrderStatus(
			_hash,
			amount, 
			previousAmount,
			_trade.amount,
			_fulfillmentType
		);

		// Emit the event with computed parameters.
		_emitOrderResultSuccess(
			_hash,
			basePrice,
			_trade,
			_trade.id,
			amount,
			_itemRecipient
		);

		// Return amount of spent ETH and success.
		return (ethPayment, true);
	}

	/**
		Contains logic for fulfilling an Offer.

		@param _trade trade parameters.
		@param _hash hash of the order.
		@param _fulfillmentType order fulfillment type, STRICT or 
			PARTIAL in case of ERC1155.
		@param _paymentRecipient recipient of the payment for the item.
		@param _fulfillment fulfiller struct, containing information on how to fulfill
			the order.
	*/
	function _fulfillOffer (
		Trade memory _trade,
		bytes32 _hash,
		uint64 _fulfillmentType,
		address _paymentRecipient,
		Fulfillment calldata _fulfillment
	) private returns (uint256, bool) {

		// Execute item transfer, calculate price and amount.
		(
			bool result,
			uint256 basePrice,
			uint256 amount,
			uint256 previousAmount
		) = _transferItem(
			_trade,
			_hash,
			_trade.id,
			_fulfillmentType,
			msg.sender,
			_trade.maker,
			_fulfillment
		);

		// Exit if item transfer failed.
		if (!result) {
			return (0, false);
		}

		// Pay for item.
		_pay(
			_trade,
			basePrice,
			_paymentRecipient,
			_trade.maker
		);

		// Update order status.
		_updateOrderStatus(
			_hash,
			amount, 
			previousAmount,
			_trade.amount,
			_fulfillmentType
		);
		
		// Emit the event with computed parameters.
		_emitOrderResultSuccess(
			_hash,
			basePrice,
			_trade,
			_trade.id,
			amount,
			_paymentRecipient
		);

		// Return success.
		return (0, true);
	}

	/**
		Verifies that leaf belongs to the merkle tree.

		@param _leaf leaf of the merkle tree.
		@param _root root of the merkle tree.
		@param _proofs supplied proofs for computing root of the merkle tree.

		@return valid flags if leaf belongs to the merkle tree.
	*/
	function _verifyProof (
		uint256 _leaf,
		bytes32 _root,
		bytes32[] calldata _proofs
	) private pure returns (bool valid) {
		assembly {
			mstore(0, _leaf)
			let hash := keccak256(0, ONE_WORD)
			let length := _proofs.length

			for {
				let idx := 0
			} lt(idx, length) {
				// Increment by one word at a time.
				idx := add(idx, 1)
			} {
				// Get the proof.
				let proof := calldataload(add(_proofs.offset, mul(idx, ONE_WORD)))

				// Store lesser value in the zero slot
				let ptr := shl(ONE_WORD_SHIFT, gt(hash, proof))
				mstore(ptr, hash)
				mstore(xor(ptr, ONE_WORD), proof)

				// Calculate the hash.
				hash := keccak256(0, TWO_WORDS)
			}

			// Compare the final hash to the supplied root.
			valid := eq(hash, _root)
		}
	}

	/**
		Verifies that token id belongs to set of token ids defined in
		the merkle tree, which root had been put in the order.resolveData
		and signed by the order.maker.

		@param _offer collection offer.
		@param _fulfillment fulfiller struct, containing information on how to fulfill
			the `_offer`.
	*/
	function _verifyTokenId (
		CollectionOffer memory _offer,
		Fulfillment calldata _fulfillment
	) private pure returns (bool) {
		// If rootHash was not supplied, offer can be executed with any token.
		if (_offer.rootHash != 0){
			return _verifyProof(
				_fulfillment.id,
				_offer.rootHash,
				_fulfillment.proofs
			);
		}
		return true;
	}

	/**
		Contains logic for fulfilling a CollectionOffer.

		@param _offer collection offer parameters.
		@param _hash hash of the order.
		@param _fulfillmentType order fulfillment type, STRICT or 
			PARTIAL in case of ERC1155.
		@param _paymentRecipient recipient of the payment for the item.
		@param _fulfillment fulfiller struct, containing information on how to fulfill
			the order.
	*/
	function _fulfillCollectionOffer (
		CollectionOffer memory _offer,
		bytes32 _hash,
		uint64 _fulfillmentType,
		address _paymentRecipient,
		Fulfillment calldata _fulfillment
	) private returns (uint256, bool) {
		
		// Check if can fulfill with provided token id.
		if (!_verifyTokenId(
				_offer,
				_fulfillment
			)
		) {
			return (0, false);
		}

		// Execute item transfer, calculate price and amount.
		(
			bool result,
			uint256 basePrice,
			uint256 amount,
			uint256 previousAmount
		) = _transferItem(
			_offer.toTrade(),
			_hash,
			_fulfillment.id,
			_fulfillmentType,
			msg.sender,
			_offer.maker,
			_fulfillment
		);

		// Exit if item transfer failed.
		if (!result) {
			return (0, false);
		}

		// Pay for item.
		_pay(
			_offer.toTrade(),
			basePrice,
			_paymentRecipient,
			_offer.maker
		);

		// Update order status.
		_updateOrderStatus(
			_hash,
			amount, 
			previousAmount,
			_offer.amount,
			_fulfillmentType
		);

		// Emit the event with computed parameters.
		_emitOrderResultSuccess(
			_hash,
			basePrice,
			_offer.toTrade(),
			_fulfillment.id,
			amount,
			_paymentRecipient
		);

		return (0, true);
	}

	/**
		Calculate the final settlement price of an auction.

		@param _listingTime order listing time.
		@param _auction _auction parameters.

		@return _ decayed price.
	*/
	function _priceDecay (
		uint256 _amount,
		uint256 _listingTime,
		DutchAuction memory _auction
	) private view returns (uint256) {
		/*
			If the timestamp at which price decrease concludes has been exceeded,
			the item listing price maintains its configured floor price.
		*/
		if (block.timestamp >= _auction.endTime) {
			return _auction.floor * _amount / 
				(_auction.amount == 0 ? 1 : _auction.amount);
		}

		/*
			Calculate the portion of the decreasing total price that has not yet
			decayed.
		*/
		uint undecayed =

			// The total decayable portion of the price.
			(_auction.basePrice - _auction.floor) *

			// The duration in seconds of the time remaining until total decay.
			(_auction.endTime - block.timestamp) /

			/*
				The duration in seconds between the order listing time and the time
				of total decay.
			*/
			(_auction.endTime - _listingTime);

		// Return the current price as the floor price plus the undecayed portion.
		return (_auction.floor + undecayed) * _amount / 
			(_auction.amount == 0 ? 1 : _auction.amount);
	}

	/**
		Contains logic for fulfilling a DutchAuction.

		@param _auction trade parameters.
		@param _hash hash of the order.
		@param _fulfillmentType order fulfillment type, STRICT or 
			PARTIAL in case of ERC1155.
		@param _itemRecipient recipient of the item in question.
		@param _fulfillment fulfiller struct, containing information on how to fulfill
			the order.
	*/
	function _fulfillDutchAuction (
		DutchAuction memory _auction,
		bytes32 _hash,
		uint64 _fulfillmentType,
		address _itemRecipient,
		uint256 _listingTime,
		Fulfillment calldata _fulfillment
	) private returns (uint256, bool) {

		// Execute item transfer, calculate price and amount.
		(
			bool result, ,
			uint256 amount,
			uint256 previousAmount
		) = _transferItem(
			_auction.toTrade(),
			_hash,
			_auction.id,
			_fulfillmentType,
			_auction.maker,
			_itemRecipient,
			_fulfillment
		);

		// Exit if item transfer failed.
		if (!result) {
			return (0, false);
		}

		// Calculate price decay.
		uint256 price = _priceDecay(
			amount,
			_listingTime,
			_auction
		);

		// Pay for item, track spent ETH.
		uint256 ethPayment = _pay(
			_auction.toTrade(),
			price,
			_auction.maker,
			msg.sender
		);

		// Update order status.
		_updateOrderStatus(
			_hash,
			amount, 
			previousAmount,
			_auction.amount,
			_fulfillmentType
		);

		// Emit the event with computed parameters.
		_emitOrderResultSuccess(
			_hash,
			price,
			_auction.toTrade(),
			_auction.id,
			amount,
			_itemRecipient
		);

		// Return amount of spent ETH and success.
		return (ethPayment, true);
	}

	/**
		Distinguishes function to execute order with.

		@param _saleKind order sale kind.
		@param _hash hash of the order.
		@param _order order parameters.
		@param _recipient account, which receives item or payment.
		@param _fulfillment fulfiller struct, containing information on how to fulfill
			the order.
		
		@return _ spent ETH amount.
		@return _ flags if item transfer was successful.
	*/
	function _fulfill (
		uint64 _saleKind,
		bytes32 _hash,
		Order memory _order,
		address _recipient,
		Fulfillment calldata _fulfillment
	) internal returns (uint256, bool){

		// Execute FixedPrice listing strategy.
		if ( _saleKind == FIXED_PRICE) {
			return _fulfillListing(
				_order.toTrade(),
				_hash,
				_order.fulfillmentType(),
				_recipient,
				_fulfillment
			);
		}

		// Execute Offer strategy.
		if ( _saleKind == OFFER) {
			return _fulfillOffer(
				_order.toTrade(),
				_hash,
				_order.fulfillmentType(),
				_recipient,
				_fulfillment
			);
		}

		// Execute Collection Offer strategy.
		if ( _saleKind == COLLECTION_OFFER) {
			return _fulfillCollectionOffer(
				_order.toCollectionOffer(),
				_hash,
				_order.fulfillmentType(),
				_recipient,
				_fulfillment
			);
		}

		// Execute Dutch Auction strategy.
		if ( _saleKind == DECREASING_PRICE) {
			return _fulfillDutchAuction(
				_order.toDutchAuction(),
				_hash,
				_order.fulfillmentType(),
				_recipient,
				_order.listingTime,
				_fulfillment
			);
		}

		// Unknown strategy.
		return (0, false);
	}
}