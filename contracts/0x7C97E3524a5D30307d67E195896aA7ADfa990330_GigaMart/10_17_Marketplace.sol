// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
	Order,
	Fulfillment,
	deriveOrder
} from "./Order.sol";

import {
	ORDER_IS_PARTIALLY_FILLED,
	ORDER_IS_FULFILLED,
	ORDER_IS_CANCELLED
} from "./OrderConstants.sol";

import {
	IAssetHandler,
	NativeTransfer,
	OrderFulfiller
} from "./OrderFulfiller.sol";

import {
	RoyaltyManager
} from "./RoyaltyManager.sol";

import {
	_getUserNonce,
	_setUserNonce,
	_getOrderStatus,
	_setOrderStatus,
	_getOrderFillAmount
} from "./Storage.sol";

import {
	MemoryPointer,
	FREE_MEMORY_POINTER,
	ECDSA_MAX_LENGTH,
	PREFIX,
	_freeMemoryPointer,
	_resetMemoryPointer,
	_recover,
	_recoverContractSignature
} from "./Helpers.sol";

/// Thrown if order.maker tries to fulfill own order.
error InvalidMaker ();

///	Thrown if order was signed with nonce, lowet than current.
error InvalidNonce ();

/**
	Thrown if order.amount is 0 for ERC1155 AssetType,
	and if order.amount is not 0 for ERC721 AssetType. 
*/
error InvalidAmount ();

/// Thrown if order parameters do not satisfy order.saleKind.
error InvalidSaleKind ();

/// Thrown if item transfer was unsuccsessfull.
error ItemTransferFailed ();

/// Thrown if order period is passed or not yet started.
error InvalidOrderPeriod ();

/**
	Thrown if order.paymentToken is zero address for ERC20
	paymentType, and if order.payment token is not zero for
	ETH paymentType.
*/
error InvalidPaymentToken ();

/** 
	Thrown if order.taker is not address zero, and neither the 
	msg.sender nor the recipient are the order.taker.
*/ 

error OrderTakerNotMatched ();

/**
	Thrown if order was already fulfilled or cancelled, or
	signature check failed.
*/
error OrderValidationFailed ();

/// Thrown if order was already fulfilled.
error OrderAlreadyFulfilled ();

/// Thrown if order was already cancelled.
error OrderAlreadyCancelled ();

/**
	@title GigaMart Executor
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>
	@custom:contributor throw; <@0xthrpw>
	
	This second iteration of the exchange executor is inspired by the old Wyvern 
	architecture `ExchangeCore`.
*/
contract Marketplace is OrderFulfiller, RoyaltyManager {
	using NativeTransfer for address;

	/**
		Emitted when an order is canceled.

		@param maker The order maker's address.
		@param hash The hash of the order.
		@param data function call.
	*/
	event OrderCancelled (
		address indexed maker,
		bytes32 hash, 
		bytes data
	);

	/**
		Emitted when a user cancels all of their orders. All orders with a nonce 
		less than `minNonce` will be canceled.

		@param sender The caller who is canceling their orders.
		@param minNonce The new nonce to use in mass-cancelation.
	*/
	event AllOrdersCancelled (
		address indexed sender,
		uint256 minNonce
	);

	/**
		Construct a new instance of the GigaMart marketplace.

		@param _assetHandler The address of the existing manager.
		@param _validator The address of a privileged validator for permitting 
			collection administrators to control their royalty fees.
		@param _protocolFeeRecipient The address which receives fees from the 
			exchange.
		@param _protocolFeePercent The percent of fees taken by 
			`_protocolFeeRecipient` in basis points (1/100th %; i.e. 200 = 2%).
	*/
	constructor(
		IAssetHandler _assetHandler,
		address _validator,
		address _protocolFeeRecipient,
		uint96 _protocolFeePercent
	) OrderFulfiller (
		_assetHandler
	) RoyaltyManager (
		_validator,
		_protocolFeeRecipient,
		_protocolFeePercent
	){}

	/**
		Reads order status and fill amount.

		@param _order Order calldata pointer.

		@return status Order status.
		@return fillAmount Order fill amount.
	*/
	function _readOrderStatus(
		Order calldata _order
	) internal view returns (uint256 status, uint256 fillAmount) {

		// Derive order hash.
		bytes32 hash = _order.hash();

		// Read status.
		status = _getOrderStatus(hash);

		// Read fill amount.
		fillAmount = _getOrderFillAmount(hash);
	}

	/**
		Validate that a provided order `_hash` does not correspond to a finalized or
		cancelled order, and was actually signed by its maker `_maker`
		with signature `_signature`.

		@param _hash A hash of an `Order` to validate.
		@param _maker The address of the maker who signed the order `_hash`.
		@param _signature The ECDSA signature of the order `_hash`, which must
			have been signed by the order `_maker`.

		@return _ Whether or not the specified order `_hash` is authenticated as 
			valid to continue fulfilling.
	*/
	function _validateOrder (
		bytes32 _hash,
		address _maker,
		bytes calldata _signature
	) internal view returns (bool) {

		// Verify order is still live.
		uint256 status = _getOrderStatus(_hash);

		// If order is partially filled, it is considered authenticated.
		if (status == ORDER_IS_PARTIALLY_FILLED) {
			return true;
		}
		
		// Order must not be cancelled.
		if (status == ORDER_IS_CANCELLED) {
			return false;
		}
		// Order must not be fulfilled.
		if (status == ORDER_IS_FULFILLED) {
			return false;
		}

		// Calculate digest before recovering signer's address.
		bytes32 digest = keccak256(
			abi.encodePacked(
				PREFIX,
				_deriveDomainSeparator(),
				_signature.length > ECDSA_MAX_LENGTH ?
					_computeBulkOrderHash(_signature, _hash) :
					_hash
			)
		);

		// Try recover maker address.
		if (_maker == _recover(digest, _signature)) {
			return true;
		}

		// If maker account is a contract, call it to validate signature.
		if (_maker.code.length > 0) {
			return _recoverContractSignature(
				_maker,
				_hash,
				_signature
			);
		} 

		// Return default.
		return false;
	}

	/**
		Strictly executes the `_order`. 

		1. Allocates each order field.
		2. Validates order parameters.
		3. Checks if order is still active and signature
			is valid.
		4. Distinguishes type of the trade.
		5. Transfers item and payments.
		6. Emits OrderResult
		7. Returns eth leftovers to msg.sender.

		@param _order The order to execute..
		@param _signature The signature provided for fulfilling the order, signed 
			by the order maker.
		@param _recipient The address of the caller who receives item or payment. E.g.
			1. msg.sender pays for the listing, item in question is transferred
				to `_recipient`.
			2. msg.sender fulfills the offer, payment is transferred to `_recipient`.
		@param _fulfillment fulfiller struct, containing information on how to fulfill
			the `_order`.

		@custom:throws InvalidMaker if maker is address(0) or equals to 
			recipient address.
		@custom:throws InvalidNonce if `_order` nonce is lower than current.
		@custom:throws InvalidOrderPeriod if block.timestamp is not in range 
			of `_order`.listingTime and `_order`.expirationTime.
		@custom:throws InvalidPaymentToken If address of paymentToken isn't 
			matched with order.paymentType.
		@custom:throws InvalidAmount if `_order`.amount isn't matched with
			order.assetType.
		@custom:throws InvalidSaleKind if `_order`.resolve data isn't matched
			with order.saleKind.
		@custom:throws OrderTakerNotMatched if order taker is specified and
			not equal to `_recipient`.
		@custom:throws OrderValidationFailed if order previously had been
			fulfilled or cancelled or `_signature` check failed/
		@custom:throws ItemTransferFailed if item transfer failed.
		@custom:throws TransferFailed if ETH transfer failed.
	*/
	function _executeSingle (
		Order calldata _order,
		bytes calldata _signature,
		address _recipient,
		Fulfillment calldata _fulfillment
	) internal {

		// Create a memory pointer to the order.
		Order memory order = deriveOrder(FREE_MEMORY_POINTER);
		// Allocate order type and load order typehash at the pointer slot.
		order.allocateOrderType(_order);
		// Allocate order parameters, which do not require validation.
		order.allocateTradeParameters(_order);

		// Validate and allocate order.maker.
		if (!order.validateMaker(_order, _recipient)) {
			revert InvalidMaker();
		}

		// Validate and allocate order.nonce.
		if (!order.validateNonce(_order, order.maker)) {
			revert InvalidNonce();
		}

		// Validate and allocate order.listingTime and order.expirationTime.
		if (!order.validateOrderPeriod(_order)) {
			revert InvalidOrderPeriod();
		}

		// Put saleKind on the stack.
		uint64 saleKind = order.saleKind();
		// Validate and allocate payment token.
		if (!order.validatePaymentType(_order, saleKind, order.paymentType())) {
			revert InvalidPaymentToken();
		}

		// Validate and allocate order item amount.
		if (!order.validateAssetType(_order, order.assetType())) {
			revert InvalidAmount();
		}

		// Validate resolveData parameters and derive the has of the order.
		(bytes32 hash, bool valid) = order.validateSaleKind(
			FREE_MEMORY_POINTER,
			_order,
			saleKind
		);

		if (!valid) {
			revert InvalidSaleKind();
		}

		// Order.taker must be recipient, if specified.
		if (order.taker != address(0) && order.taker != _recipient) {
			revert OrderTakerNotMatched();
		}

		// Check if order is still open and check the signature.
		if (!_validateOrder(hash, order.maker, _signature)) {
			revert OrderValidationFailed();
		}

		
		/// Transfer the item and payments. Put amount of spent eth on the stack. 
		(uint256 ethSpent, bool itemTransferred) = 
			_fulfill(saleKind, hash, order, _recipient, _fulfillment);

		// Revert if item transfer failed.
		if (!itemTransferred) {
			revert ItemTransferFailed();
		}

		// Return eth leftovers.
		if (msg.value > ethSpent){
			msg.sender.transferEth(msg.value - ethSpent);
		}
	}

	/**
		Executes order in a lenient way - emits OrderResult with error code,
		if the order didn't pass validation or item transfer failed. Reverts only
		on payment failure.

		1. Allocates each order field.
		2. Validates order parameters.
		3. Checks if order is still active and signature
			is valid.
		4. Distinguishes type of the trade.
		5. Transfers item and payments.
		6. Emits OrderResult
		7. Returns eth leftovers amount up the callstack.

		@param _order The order to execute..
		@param _signature The signature provided for fulfilling the order, signed 
			by the order maker.
		@param _recipient The address of the caller who receives item or payment. E.g.
			1. msg.sender pays for the listing, item in question is transferred
				to `_recipient`.
			2. msg.sender fulfills the offer, payment is transferred to `_recipient`.
		@param _fulfillment fulfiller struct, containing information on how to fulfill
			the `_order`.
	*/
	function _executeMultiple (
		Order calldata _order,
		bytes calldata _signature,
		address _recipient,
		Fulfillment calldata _fulfillment
	) internal returns (uint256) {
		
		// Create a memory pointer to the order.
		Order memory order = deriveOrder(_freeMemoryPointer());

		// Allocate order type and load order typehash at the pointer slot.
		order.allocateOrderType(_order);
		// Allocate order parameters, which do not require validation.
		order.allocateTradeParameters(_order);

		// Validate and allocate order.maker.
		if (!order.validateMaker(_order, _recipient)) {
			_emitOrderFailed(
				bytes1(0x01),
				_order.hash(),
				order.toTrade(),
				_recipient
			);
			/// Reset memory pointer for the next order.
			_resetMemoryPointer();
			return 0;
		}

		// Validate and allocate order.nonce.
		if (!order.validateNonce(_order, order.maker)) {
			_emitOrderFailed(
				(0x02),
				_order.hash(),
				order.toTrade(),
				_recipient
			);
			/// Reset memory pointer for the next order.
			_resetMemoryPointer();
			return 0;
		}

		// Validate and allocate order.listingTime and order.expirationTime.
		if (!order.validateOrderPeriod(_order)) {
			_emitOrderFailed(
				bytes1(0x03),
				_order.hash(),
				order.toTrade(),
				_recipient
			);
			/// Reset memory pointer for the next order.
			_resetMemoryPointer();
			return 0;
		}

		// Put saleKind on the stack.
		uint64 saleKind = order.saleKind();
		// Validate and allocate payment token.
		if (!order.validatePaymentType(_order, saleKind, order.paymentType())) {
			_emitOrderFailed(
				bytes1(0x04),
				_order.hash(),
				order.toTrade(),
				_recipient
			);
			/// Reset memory pointer for the next order.
			_resetMemoryPointer();
			return 0;
		}

		// Validate and allocate order item amount.
		if (!order.validateAssetType(_order, order.assetType())) {
			_emitOrderFailed(
				bytes1(0x05),
				_order.hash(),
				order.toTrade(),
				_recipient
			);
			/// Reset memory pointer for the next order.
			_resetMemoryPointer();
			return 0;
		}

		// Validate resolveData parameters and derive the has of the order.
		(bytes32 hash, bool valid) = order.validateSaleKind(
			FREE_MEMORY_POINTER,
			_order,
			saleKind
		);

		if (!valid) {
			_emitOrderFailed(
				bytes1(0x06),
				hash,
				order.toTrade(),
				_recipient
			);
			/// Reset memory pointer for the next order.
			_resetMemoryPointer();
			return 0;
		}

		// Order.taker must be recipient, if specified.
		if (order.taker != address(0) && order.taker != _recipient) {
			_emitOrderFailed(
				bytes1(0x08),
				hash,
				order.toTrade(),
				_recipient
			);
			/// Reset memory pointer for the next order.
			_resetMemoryPointer();
			return 0;
		}

		// Check if order is still open and check the signature.
		if (!_validateOrder(hash, order.maker, _signature)) {
			_emitOrderFailed(
				bytes1(0x07),
				hash,
				order.toTrade(),
				_recipient
			);
			/// Reset memory pointer for the next order.
			_resetMemoryPointer();
			return 0;
		}

		/// Transfer the item and payments. Put amount of spent eth on the stack. 
		(uint256 ethSpent, bool itemTransferred) = 
			_fulfill(saleKind, hash, order, _recipient, _fulfillment);

		/// If item transfer fails, skip payment and emit OrderResult with error code.
		if (!itemTransferred) {
			_emitOrderFailed(
				bytes1(0x09),
				hash,
				order.toTrade(),
				_recipient
			);
			/// Reset memory pointer for the next order.
			_resetMemoryPointer();
			return 0;
		}

		/// Reset memory pointer for the next order.
		_resetMemoryPointer();

		/// Return amount of spent eth up the callstack.
		return ethSpent;
	}


	/**
		Cancel an order, preventing it from being matched. An order must be 
		canceled by its maker.
		
		@param _order The `Order` to cancel.

		@custom:throws OrderAlreadyCancelled if the order has already been 
			individually canceled, or mass-canceled.
		@custom:throws OrderAlreadyFulfilled if the order has already been 
			fulfilled.
		@custom:throws OrderValidationFailed if the caller is not the maker of 
			the order.
	*/
	function _cancelOrder (Order calldata _order) internal {

		// Calculate the order hash.
		bytes32 hash = _order.hash();

		// Verify order is still live.
		uint256 status = _getOrderStatus(hash);
		if (
			status == ORDER_IS_CANCELLED || 
			_order.nonce < _getUserNonce(msg.sender)
		) {
			revert OrderAlreadyCancelled();
		}
		if (status == ORDER_IS_FULFILLED) {
			revert OrderAlreadyFulfilled();
		}

		// Verify the order is being canceled by its maker.
		if (_order.maker != msg.sender) {
			revert OrderValidationFailed();
		}

		// Distinguish the order side. Sell or Buy.
		bool sellSide = _order.saleKind() > 2;

		// Set buyer and seller according to the side of the order.
		uint256 buyer = sellSide ? 0 : uint256(uint160(_order.maker));
		uint256 seller = sellSide ? uint256(uint160(_order.maker)) : 0;

		/* 
			Encode parameters in such manner, for supporting 
			backwards compatibility with previos versions.
		*/
		bytes memory data = abi.encode(
			_order.collection,
			abi.encodePacked(
				bytes4(0),
				seller,
				buyer,
				_order.id,
				_order.amount
			)
		);

		// Update order status.
		_setOrderStatus(hash, ORDER_IS_CANCELLED);

		emit OrderCancelled(
			_order.maker,
			hash,
			data
		);
	}

	/**
		Sets new nonce for the msg.sender.
		
		@param _newNonce The new nonce to use in mass-cancelation.

		@custom:throws InvalidNonce if `_newNonce` is lower than current nonce.
	*/
	function _setNonce (uint256 _newNonce) internal {
		
		// New nonce must be larger than the previous.
		if ( _newNonce <= _getUserNonce(msg.sender) ) {
			revert InvalidNonce();
		}
		
		// Update user nonce.
		_setUserNonce(_newNonce);

		emit AllOrdersCancelled(msg.sender, _newNonce);
	}
}