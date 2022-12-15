// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {
	Entities,
	Sales,
	AuthenticatedProxy
} from "./Entities.sol";
import {
	RoyaltyManager
} from "./RoyaltyManager.sol";
import {
	NativeTransfer
} from "../libraries/NativeTransfer.sol";
import {
	OwnableDelegateProxy
} from "../proxy/OwnableDelegateProxy.sol";
import {
	TokenTransferProxy,
	IProxyRegistry,
	Address
} from "../proxy/TokenTransferProxy.sol";

/// Thrown if the user proxy does not exist (bytecode length is zero).
error UserProxyDoesNotExist ();

/**
	Thrown if the user-proxy implementation is pointing to an unexpected 
	implementation.
*/
error UnknownUserProxyImplementation ();

/// Thrown if a call to the user-proxy are fails.
error CallToProxyFailed ();

/**
	Thrown on order cancelation if the order already has been fulfilled or 
	canceled.
*/
error OrderIsAlreadyCancelled ();

/**
	Thrown when attempting order cancelation functions, if checks for msg.sender,
	order nonce or signatures are failed. 
*/
error CannotAuthenticateOrder ();

/**
	Thrown if order terms are invalid, expired, or the provided exchange address 
	does not match this contract.
*/
error InvalidOrder ();

/**
	Thrown if insufficient value is sent to fulfill an order price.
*/
error NotEnoughValueSent ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Executor
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>
	@custom:contributor throw; <@0xthrpw>
	
	This first iteration of the exchange executor is inspired by the old Wyvern 
	architecture `ExchangeCore`.

	@custom:version 1.1
	@custom:date December 14th, 2022.
*/
abstract contract Executor is RoyaltyManager {
	using Entities for Entities.Order;
	using NativeTransfer for address;

	/**
		A specific 13 second duration, slightly longer than the duration of one 
		block, so as to allow the successful execution of orders within a leeway of 
		approximately one block.
	*/
	uint256 private constant LUCKY_NUMBER = 13;

	/// The selector for EIP-1271 contract-based signatures.
	bytes4 internal constant EIP_1271_SELECTOR = bytes4(
		keccak256("isValidSignature(bytes32,bytes)")
	);

	/// A reference to the immutable proxy registry.
	IProxyRegistry public immutable registry;

	/// A global, shared token transfer proxy for fulfilling exchanges.
	TokenTransferProxy public immutable tokenTransferProxy;

	/**
		A mapping from each caller to the minimum nonce of their order books. When 
		a caller increments their nonce, all user offers with nonces below the 
		value in this mapping are canceled.
	*/
	mapping ( address => uint256 ) public minOrderNonces;

	/// A mapping of all orders which have been canceled or finalized.
	mapping ( bytes32 => bool ) public cancelledOrFinalized;

	/**
		Emitted when an order is canceled.

		@param maker The order maker's address.
		@param hash The hash of the order.
		@param data The parameters of the order concatenated together, e.g. 
			{collection address, encoded transfer function call}.
	*/
	event OrderCancelled (
		address indexed maker,
		bytes32 hash,
		bytes data
	);

	/**
		Emitted at each attempt of exchanging an item.

		@param order The hash of the order.
		@param maker The order maker's address.
		@param taker The order taker's address.
		@param data An array of bytes that contains the success status, order sale 
			kind, price, payment token, target, and transfer data.
	*/
	event OrderResult (
		bytes32 order,
		address indexed maker,
		address indexed taker,
		bytes data
	);

	/**
		Construct a new instance of the GigaMart order executor.

		@param _registry The address of the existing proxy registry.
		@param _tokenTransferProxy The address of the token transfer proxy contract.
		@param _validator The address of a privileged validator for permitting 
			collection administrators to control their royalty fees.
		@param _protocolFeeRecipient The address which receives fees from the 
			exchange.
		@param _protocolFeePercent The percent of fees taken by 
			`_protocolFeeRecipient` in basis points (1/100th %; i.e. 200 = 2%).
	*/
	constructor (
		IProxyRegistry _registry,
		TokenTransferProxy _tokenTransferProxy,
		address _validator,
		address _protocolFeeRecipient,
		uint96 _protocolFeePercent
	) RoyaltyManager(_validator, _protocolFeeRecipient, _protocolFeePercent) {
		tokenTransferProxy = _tokenTransferProxy;
		registry = _registry;
	}

	/**
		Hash an order and return the hash that a client must sign, including the 
		standard message prefix.

		@param _order The order to sign.

		@return _ The order hash that must be signed by the client.
	*/
	function _hashToSign (
		Entities.Order memory _order
	) private view returns (bytes32) {
		return keccak256(
			abi.encodePacked(
				"\x19\x01",
				_deriveDomainSeparator(),
				_order.hash()
			)
		);
	}

	/**
		Cancel an order, preventing it from being matched. An order must be 
		canceled by its maker.
		
		@param order The `Order` to cancel.

		@custom:throws OrderAlreadyCancelled if the order has already been 
			fulfilled, individually canceled, or mass-canceled.
		@custom:throws CannotAuthenticateOrder if the caller is not the maker of 
			the order.
	*/
	function _cancelOrder (
		Entities.Order calldata order
	) internal {

		// Calculate the order hash.
		bytes32 hash = _hashToSign(order);

		// Verify order is still live.
		if (
			cancelledOrFinalized[hash] ||	order.nonce < minOrderNonces[msg.sender]
		) {
			revert OrderIsAlreadyCancelled();
		}

		// Verify the order is being canceled by its maker.
		if (order.outline.maker != msg.sender) {
			revert CannotAuthenticateOrder();
		}

		// Cancel the order and log the event.
		cancelledOrFinalized[hash] = true;
		emit OrderCancelled(
			order.outline.maker,
			hash,
			abi.encode(order.outline.target, order.data)
		);
	}

	/**
		Transfer multiple items using the user-proxy and executable bytecode.

		@param _targets The array of addresses which should be called with the 
			function calls encoded in `_data`.
		@param _data The array of encoded function calls performed against the 
			addresses in `_targets`.

		@custom:throws UserProxyDoesNotExist if the targeted delegate proxy for the 
			user does not exist.
		@custom:throws UnknownUserProxyImplementation if the targeted delegate 
			proxy implementation is not as expected.
		@custom:throws CallToProxyFailed if an encoded call to the proxy fails.
	*/
	function _multiTransfer (
		address[] calldata _targets,
		bytes[] calldata _data
	) internal {

		// Store the registry object in memory to save gas.
		IProxyRegistry proxyRegistry = registry;

		// Retrieve the caller's delegate proxy, verifying that it exists.
		address delegateProxy = proxyRegistry.proxies(msg.sender);
		if (!Address.isContract(delegateProxy)) {
			revert UserProxyDoesNotExist();
		}

		// Verify that the implementation of the user's delegate proxy is expected.
		if (
			OwnableDelegateProxy(payable(delegateProxy)).implementation() !=
			proxyRegistry.delegateProxyImplementation()
		) {
			revert UnknownUserProxyImplementation();
		}

		// Access the passthrough `AuthenticatedProxy` to make transfer calls.
		AuthenticatedProxy proxy = AuthenticatedProxy(payable(delegateProxy));
		for (uint256 i; i < _targets.length; ) {

			// Perform each encoded call and verify that they succeeded.
			if (
				!proxy.call(
					_targets[i],
					AuthenticatedProxy.CallType.Call,
					_data[i]
				)
			) {
				revert CallToProxyFailed();
			}
			unchecked {
				++i;
			}
		}
	}

	/**
		Perform validation on the supplied `_taker` and `_order` address. This 
		validation ensures that the correct exchange is used and that the order 
		maker is neither the recipient, message sender, or zero address. This 
		validation also ensures that the salekind is sensible and matches the 
		provided order parameters.

		@param _taker The address of the order taker.
		@param _order The order to perform parameter validation against.

		@return _ Whether or not the specified `_order` is valid to be fulfilled by 
			the `_taker`.
	*/
	function _validateOrderParameters (
		address _taker,
		Entities.Order memory _order
	) private view returns (bool) {

		// Verify that the order is targeted at this exchange contract.
		if (_order.outline.exchange != address(this)) {
			return false;
		}

		/*
			Verify that the order maker is not the `_taker`, nor the msg.sender, nor 
			the zero address.
		*/
		if (
			_order.outline.maker == _taker ||
			_order.outline.maker == msg.sender ||
			_order.outline.maker == address(0)
		) {
			return false;
		}

		/*
			In a typical Wyvern order flow, this is the point where one would ensure 
			that the order target exists. This is done to prevent the low-hanging 
			attack of a malicious item collection self-destructing and rendering 
			orders worthless. This protection uses a not-insignificant amount of gas 
			and does not prevent against additional malicious attacks such as 
			front-running from an upgradeable contract. Given the number of other 
			possible rugpulls that an item collection could pull against its holders, 
			this seems like a reasonable trade-off.
		*/

		/*
			Allow the fulfillment of an order if the current block time is within the 
			listing and expiration time of that order, less a small gap to support 
			the case of immediate signature creation and fulfillment within a single 
			block.
		*/
		if (
			!Sales._canSettleOrder(
				_order.outline.listingTime - LUCKY_NUMBER,
				_order.outline.expirationTime
			)
		) {
			return false;
		}

		// Validate the call to ensure the correct function selector is being used.
		if (!_order.validateCall()) {
			return false;
		}

		// The order must possess a valid sale kind parameter.
		uint8 saleKind = uint8(_order.outline.saleKind);
		if (saleKind > 5) {
			return false;
		}

		// Reject item sales which are presented as buy-sided.
		if (saleKind < 3 && _order.outline.side == Sales.Side.Buy) {
			return false;
		}

		// Reject item offers which are presented as sell-sided.
		if (saleKind > 2 && _order.outline.side == Sales.Side.Sell) {
			return false;
		}

		/*
			There is no need to validate the `_taker` that may be later inserted into 
			the order call data for our `FixedPrice` or `DecreasingPrice` sale kinds. 
			In each of these cases, the message sender cannot achieve anything 
			malicious by attempting to modify the `_taker` which is later inserted 
			into the order.
		*/

		/*
			This sale kind is a `DirectListing`, which is meant to be a private 
			listing of an item fulfillable by a single specific taker. For this kind 
			of order, we validate that the `_taker` specified is the same as the 
			taker encoded in the order.
		*/
		if (saleKind == 2 && _taker != _order.outline.taker) {
			return false;
		}

		/*
			This sale kind is a `DirectOffer`, which is meant to be a private offer 
			fulfillable against only a single item by a single specific taker. In 
			other words, the offer does not follow the item if the item finds itself 
			in the hands of a new holder. For this kind of order, we validate that 
			the `_taker` is both the message sender and the taker encoded in the 
			order.
		*/
		if (
			saleKind == 3 &&
			(_order.outline.taker != msg.sender || _taker != _order.outline.taker)
		) {
			return false;
		}

		/*
			These two sale kinds correspond to `Offer` and `CollectionOffer`, each of 
			which are publically fulfillable by multiple potential takers. For 
			fulfilling these kinds of orders, the `_taker` specified must be the 
			message sender, lest an item holder be forced to accept an offer against 
			their will.
		*/
		if ((saleKind == 4 || saleKind == 5) && _taker != msg.sender) {
			return false;
		}

		// All is validated successfully.
		return true;
	}

	/**
		A helper function to validate an EIP-1271 contract signature.

		@param _orderMaker The smart contract maker of the order.
		@param _hash The hash of the order.
		@param _sig The signature of the order to validate.

		@return _ Whether or not `_sig` is a valid signature of `_hash` by the 
			`_orderMaker` smart contract.
	*/
	function _recoverContractSignature (
		address _orderMaker,
		bytes32 _hash,
		Entities.Sig memory _sig
	) private view returns (bool) {
		bytes memory isValidSignatureData = abi.encodeWithSelector(
			EIP_1271_SELECTOR,
			_hash,
			abi.encodePacked(_sig.r, _sig.s, _sig.v)
		);

		/*
			Call the `_orderMaker` smart contract and check for the specific magic 
			EIP-1271 result.
		*/
		bytes4 result;
		assembly {
			let success := staticcall(
				
				// Forward all available gas.
				gas(),
				_orderMaker,
		
				// The calldata offset comes after length.
				add(isValidSignatureData, 0x20),

				// Load calldata length.
				mload(isValidSignatureData), // load calldata length

				// Do not use memory for return data.
				0,
				0
			)

			/*
				If the call failed, copy return data to memory and pass through revert 
				data.
			*/
			if iszero(success) {
				returndatacopy(0, 0, returndatasize())
				revert(0, returndatasize())
			}

			/*
				If the return data is the expected size, copy it to memory and load it 
				to our `result` on the stack.
			*/
			if eq(returndatasize(), 0x20) {
				returndatacopy(0, 0, 0x20)
				result := mload(0)
			}
		}

		// If the collected result is the expected selector, the signature is valid.
		return result == EIP_1271_SELECTOR;
	}

	/**
		Validate that a provided order `_hash` does not correspond to a finalized 
		order, was not created with an invalidated nonce, and was actually signed 
		by its maker `_maker` with signature `_sig`.

		@param _hash A hash of an `Order` to validate.
		@param _maker The address of the maker who signed the order `_hash`.
		@param _nonce A nonce in the order for checking validity in 
			mass-cancelation.
		@param _sig The ECDSA signature of the order `_hash`, which must have been 
			signed by the order `_maker`.

		@return _ Whether or not the specified order `_hash` is authenticated as 
			valid to continue fulfilling.
	*/
	function _authenticateOrder (
		bytes32 _hash,
		address _maker,
		uint256 _nonce,
		Entities.Sig calldata _sig
	) private view returns (bool) {

		// Verify that the order has not already been canceled or fulfilled.
		if (cancelledOrFinalized[_hash]) {
			return false;
		}

		// Verify that the order was not createed with an expired nonce.
		if (_nonce < minOrderNonces[_maker]) {
			return false;
		}

		/* EOA-only authentication: ECDSA-signed by maker. */
		// Verify that the order hash was actually signed by the provided `_maker`.
		if (ecrecover(_hash, _sig.v, _sig.r, _sig.s) == _maker) {
			return true;
		}

		/*
			If the `_maker` is a smart contract, recover an EIP-1271 contract 
			signature for attempted authentication.
		*/
		if (Address.isContract(_maker)) {
			return _recoverContractSignature(_maker, _hash, _sig);
		}

		/*
			The signature is not validated against either an EOA or smart contract 
			signer and is therefore not valid.
		*/
		return false;
	}

	/**
		Execute all ERC-20 token or Ether transfers associated with an order match, 
		paid for by the message sender.

		@param _order The order whose payment is being matched.
		@param _royaltyIndex Th

		@return _ The amount of payment required for order fulfillment in ERC-20 
			token or Ether.

		@custom:throws NotEnoughValueSent if message value is insufficient to cover 
			an Ether payment.
	*/
	function _pay (
		Entities.Order memory _order,
		uint256 _royaltyIndex
	) private returns (uint256) {

		/*
			If the order being fulfilled is an offer, the message sender is the party 
			selling an item. If the order being fulfilled is a listing, the message 
			sender is the party buying an item.
		*/
		(address seller, address buyer) = _order.outline.side == Sales.Side.Buy
			? (msg.sender, _order.outline.maker)
			: (_order.outline.maker, msg.sender);

		// Calculate a total price for fulfilling the order.
		uint256 requiredAmount = Sales._calculateFinalPrice(
			_order.outline.saleKind,
			_order.outline.basePrice,
			_order.extra,
			_order.outline.listingTime
		);

		// If the amount required for order fulfillment is not zero, then transfer.
		if (requiredAmount > 0) {

			/*
				Track the amount of payment that the seller will ultimately receive 
				after fees are deducted.
			*/
			uint256 receiveAmount = requiredAmount;

			// Handle a payment in ERC-20 token.
			if (_order.outline.paymentToken != address(0)) {

				// Store the token transfer proxy in memory to save gas.
				TokenTransferProxy proxy = tokenTransferProxy;

				/*
					Store fee configuration and charge platform fees. Platform fees are 
					configured in basis points.
				*/
				uint256 config = _protocolFee;
				if (uint96(config) != 0) {
					uint256 fee = (requiredAmount * uint96(config)) / 10_000;

					/*
						Extract the fee recipient address from the fee configuration and 
						transfer the platform fee. Deduct the fee from the maker's receipt.
					*/
					proxy.transferERC20(
						_order.outline.paymentToken,
						buyer,
						address(uint160(config >> 96)),
						fee
					);
					receiveAmount -= fee;
				}

				// Charge creator royalty fees based on the royalty index.
				config = royalties[_order.outline.target][_royaltyIndex];
				if (uint96(config) != 0) {
					uint256 fee = (requiredAmount * uint96(config)) / 10_000;

					/*
						Extract the fee recipient address from the fee configuration and 
						transfer the royalty fee. Deduct the fee from the maker's receipt.
					*/
					proxy.transferERC20(
						_order.outline.paymentToken,
						buyer,
						address(uint160(config >> 96)),
						fee
					);
					receiveAmount -= fee;
				}

				// Transfer the remainder of the payment to the item seller.
				proxy.transferERC20(
					_order.outline.paymentToken,
					buyer,
					seller,
					receiveAmount
				);

			// Handle a payment in Ether.
			} else {
				if (msg.value < requiredAmount) {
					revert NotEnoughValueSent();
				}

				/*
					Store fee configuration and charge platform fees. Platform fees are 
					configured in basis points.
				*/
				uint256 config = _protocolFee;
				if (uint96(config) != 0) {
					uint256 fee = (requiredAmount * uint96(config)) / 10_000;

					/*
						Extract the fee recipient address from the fee configuration and 
						transfer the platform fee. Deduct the fee from the maker's receipt.
					*/
					address(uint160(config >> 96)).transferEth(fee);
					receiveAmount -= fee;
				}

				// Charge creator royalty fees based on the the royalty index.
				config = royalties[_order.outline.target][_royaltyIndex];
				if (uint96(config) != 0) {
					uint256 fee = (requiredAmount * uint96(config)) / 10_000;

					/*
						Extract the fee recipient address from the fee configuration and 
						transfer the royalty fee. Deduct the fee from the maker's receipt.
					*/
					address(uint160(config >> 96)).transferEth(fee);
					receiveAmount -= fee;
				}

				// Transfer the remainder of the payment to the item seller.
				seller.transferEth(receiveAmount);
			}
		}

		// Return the required payment amount.
		return requiredAmount;
	}

	/**
		Perform the exchange of an item for an ERC-20 token or Ether in fulfilling 
		the given `_order`.

		@param _taker The address of the caller who fulfills the order.
		@param _order The `Order` to execute.
		@param _signature The signature provided for fulfilling the order, signed 
			by the order maker.
		@param _tokenId The unique token ID of the item involved in the order.

		@custom:throws InvalidOrder if the order parameters cannot be validated.
		@custom:throws CannotAuthenticateOrder if the order parameters cannot be 
			authenticated.
		@custom:throws UserProxyDoesNotExist if the targeted delegate proxy for the 
			user does not exist.
		@custom:throws UnknownUserProxyImplementation if the targeted delegate 
			proxy implementation is not as expected.
		@custom:throws CallToProxyFailed if the encoded call to the proxy fails.
	*/
	function _exchange (
		address _taker,
		Entities.Order memory _order,
		Entities.Sig calldata _signature,
		uint256 _tokenId
	) internal {

		// Retrieve the order hash.
		bytes32 hash = _hashToSign(_order);

		// Validate the order.
		if (!_validateOrderParameters(_taker, _order)) {
			revert InvalidOrder();
		}

		// Authenticate the order.
		if (
			!_authenticateOrder(
				hash,
				_order.outline.maker,
				_order.nonce,
				_signature
			)
		) { 
			revert CannotAuthenticateOrder();
		}

		// Store the registry object in memory to save gas.
		IProxyRegistry proxyRegistry = registry;

		/*
			Retrieve the delegate proxy address and implementation contract address 
			of the side of the order exchanging their item for an ERC-20 token or 
			Ether.
		*/
		(address delegateProxy, address implementation) = proxyRegistry
			.userProxyConfig(
				_order.outline.side == Sales.Side.Buy
					? msg.sender
					: _order.outline.maker
			);

		// Verify that the user's delegate proxy exists.
		if (!Address.isContract(delegateProxy)) {
			revert UserProxyDoesNotExist();
		}

		// Verify that the implementation of the user's delegate proxy is expected.
		if (
			OwnableDelegateProxy(payable(delegateProxy)).implementation() !=
			implementation
		) {
			revert UnknownUserProxyImplementation();
		}

		// Access the passthrough `AuthenticatedProxy` to make transfer calls.
		AuthenticatedProxy proxy = AuthenticatedProxy(payable(delegateProxy));

		// Populate the order call data depending on the sale type.
		_order.generateCall(_taker, _tokenId);

		/*
			Perform the encoded call against the delegate proxy and verify that it 
			succeeded.
		*/
		if (
			!proxy.call(
				_order.outline.target,
				AuthenticatedProxy.CallType.Call,
				_order.data
			)
		) {
			revert CallToProxyFailed();
		}

		/*
			Fulfill order payment and refund the message sender if needed. The first 
			element of the order extra field contains the royalty index corresponding 
			to the collection royalty fee that was created at the time of order 
			signing.
		*/
		uint256 price = _pay(_order, _order.extra[0]);
		if (msg.value > price) {
			msg.sender.transferEth(msg.value - price);
		}

		// Mark the order as finalized.
		cancelledOrFinalized[hash] = true;

		// Condense order settlement status for event emission.
		bytes memory settledParameters = abi.encodePacked(
			bytes1(0xFF),
			_order.outline.saleKind,
			price,
			_order.outline.paymentToken,
			_order.outline.target,
			_order.data
		);

		// Emit an event with the results of this order.
		emit OrderResult(
			hash,
			_order.outline.maker,
			_taker,
			settledParameters
		);
	}

	/**
		A helper function to emit an `OrderResult` event while avoiding a 
		stack-depth error.

		@param _recipient The address which will receive the item.
		@param _order The `Order` to execute.
		@param _hash The hash of the order.
		@param _code Error codes for the reason of order failure.
		@param _price The price at which the order was fulfilled.
	*/
	function _emitResult (
		address _recipient,
		Entities.Order memory _order,
		bytes32 _hash,
		bytes1 _code,
		uint256 _price
	) private {
		emit OrderResult(
			_hash,
			_order.outline.maker,
			_recipient,
			abi.encodePacked(
				_code,
				_order.outline.saleKind,
				_price,
				_order.outline.paymentToken,
				_order.outline.target,
				_order.data
			)
		);
	}

	/**
		Find similiar existing payment token addresses and increases their amount.
		If payment tokens are not found, create a new payment element.

		@param _payments An array to accumulate payment elements.
		@param _paymentToken The payment token used in fulfilling the order.
		@param _recipient The order maker.
		@param _price The price of fulfilling the order.
	*/
	function _insert (
		bytes memory _payments,
		address _paymentToken,
		uint256 _recipient,
		uint256 _price
	) private pure {
		assembly {

			// Iterate through the `_payments` array in chunks of size 0x60.
			let len := div(mload(add(_payments, 0x00)), 0x60)
			let found := false
			for {
				let i := 0
			} lt(i, len) {
				i := add(i, 1)
			} {

				/*
					Load the token at this position of the array. If it is equal to the 
					payment token, check the payment destination.
				*/
				let token := mload(add(_payments, add(mul(i, 0x60), 0x20)))
				if eq(token, _paymentToken) {
					let offset := add(_payments, add(mul(i, 0x60), 0x60))

					/*
						If the payment destination is the recipient, increase the amount 
						they are already being paid.
					*/
					let to := mload(add(_payments, add(mul(i, 0x60), 0x40)))
					if eq(to, _recipient) {
						let amount := mload(offset)
						mstore(offset, add(amount, _price))
						found := true
					}
				}
			}

			// If the payment recipient was not found, insert their payment.
			if eq(found, 0) {
				switch len

				/*
					In the event of the initial insert, we've already allocated 0x20 
					bytes and only need to allocate 0x40 more to fit our three payment 
					variables.
				*/
				case 0 {
					mstore(
						add(_payments, 0x00),
						add(mload(add(_payments, 0x00)), 0x40)
					)
				}

				// Increase the size of the array by 0x60.
				default {
					mstore(
						add(_payments, 0x00),
						add(mload(add(_payments, 0x00)), 0x60)
					)
				}

				// Store the payment token, recipient, and amount.
				let offset := add(_payments, mul(len, 0x60))
				mstore(add(offset, 0x20), _paymentToken)
				mstore(add(offset, 0x40), _recipient)
				mstore(add(offset, 0x60), _price)
			}
		}
	}

	/**
		Generates a unique payment token transfer calls and adds it to the 
		`_payments` array.

		@param _payments An array to accumulate payment elements.
		@param _paymentToken The payment token used in fulfilling the order.
		@param _royaltyIndex The index of the royalty for the item collection with 
			which royalty fees should be calculated.
		@param _recipient The order maker.
		@param _price The price of fulfilling the order.
		@param _collection The item collection address.
	*/
	function _addPayment (
		bytes memory _payments,
		address _paymentToken,
		uint256 _royaltyIndex,
		uint256 _recipient,
		uint256 _price,
		address _collection
	) private view {
		uint256 finalPrice = _price;

		// Insert the protocol fee.
		uint256 config = _protocolFee;
		if (uint96(config) != 0) {
			unchecked {
				uint256 fee = (_price * uint96(config)) / 10_000;
				config = (config >> 96);
				_insert(_payments, _paymentToken, config, fee);
				finalPrice -= fee;
			}
		}

		// Insert the royalty payment.
		config = royalties[_collection][_royaltyIndex];
		if (uint96(config) != 0) {
			unchecked {
				uint256 fee = (_price * uint96(config)) / 10_000;
				config = (config >> 96);
				_insert(_payments, _paymentToken, config, fee);
				finalPrice -= fee;
			}
		}

		// Insert the final payment to the end recipient into the payment array.
		_insert(_payments, _paymentToken, _recipient, finalPrice);
	}

	/**
		Executes orders in the context of fulfilling potentially-multiple item 
		listings. This function cannot be used for fulfilling offers. This function 
		accumulates payment information in `_payments` for single-shot processing.

		@param _recipient The address which will receive the item.
		@param _order The `Order` to execute.
		@param _signature The signature provided for fulfilling the order, signed 
			by the order maker.
		@param _payments An array for accumulating payment information.
	*/
	function _exchangeUnchecked (
		address _recipient,
		Entities.Order memory _order,
		Entities.Sig calldata _signature,
		bytes memory _payments
	) internal {

		// Retrieve the order hash.
		bytes32 hash = _hashToSign(_order);
		{

			// Validate the order.
			if (!_validateOrderParameters(_recipient, _order)) {
				_emitResult(_recipient, _order, hash, 0x11, 0);
				return;
			}

			// Authenticate the order.
			if (
				!_authenticateOrder(
					hash,
					_order.outline.maker,
					_order.nonce,
					_signature
				)
			) {
				_emitResult(_recipient, _order, hash, 0x12, 0);
				return;
			}

			// Store the registry object in memory to save gas.
			IProxyRegistry proxyRegistry = registry;

			/*
				Retrieve the delegate proxy address and implementation contract address 
				of the side of the order exchanging their item for an ERC-20 token or 
				Ether.
			*/
			(address delegateProxy, address implementation) = proxyRegistry
				.userProxyConfig(_order.outline.maker);

			// Verify that the user's delegate proxy exists.
			if (!Address.isContract(delegateProxy)) {
				_emitResult(_recipient, _order, hash, 0x43, 0);
				return;
			}

			// Verify the implementation of the user's delegate proxy is expected.
			if (
				OwnableDelegateProxy(payable(delegateProxy)).implementation() !=
				implementation
			) {
				_emitResult(_recipient, _order, hash, 0x44, 0);
				return;
			}

			// Access the passthrough `AuthenticatedProxy` to make transfer calls.
			AuthenticatedProxy proxy = AuthenticatedProxy(payable(delegateProxy));

			// Populate the order call data depending on the sale type.
			_order.generateCall(_recipient, 0);

			/*
				Perform the encoded call against the delegate proxy and verify that it 
				succeeded.
			*/
			if (
				!proxy.call(
					_order.outline.target,
					AuthenticatedProxy.CallType.Call,
					_order.data
				)
			) {
				_emitResult(_recipient, _order, hash, 0x50, 0);
				return;
			}
		}
		{

			// Calculate a total price for fulfilling the order.
			uint256 price = Sales._calculateFinalPrice(
				_order.outline.saleKind,
				_order.outline.basePrice,
				_order.extra,
				_order.outline.listingTime
			);

			// Add the calculated price to the payments accumulator.
			_addPayment(
				_payments,
				_order.outline.paymentToken,
				_order.extra[0],
				uint256(uint160(_order.outline.maker)),
				price,
				_order.outline.target
			);

			// Mark the order as finalized and emit the final result.
			cancelledOrFinalized[hash] = true;
			_emitResult(_recipient, _order, hash, 0xFF, price);
		}
	}

	/**
		Execute all payments from the provided `_payments` array.

		@param _payments A bytes array of accumulated payment data, populated by 
			`_exchangeUnchecked` and `_addPayment`.
		@param _buyer The caller paying to fulfill these payments.
		@param _proxy The address of a token transfer proxy.
	*/
	function _pay (
		bytes memory _payments,
		address _buyer,
		address _proxy
	) internal {
		bytes4 sig = TokenTransferProxy.transferERC20.selector;
		uint256 ethPayment;
		assembly {

			/*
				Take the `_payments` and determine the length in discrete chunks of 
				size 0x60. Iterate through each chunk.
			*/
			let len := div(mload(add(_payments, 0x00)), 0x60)
			for {
				let i := 0
			} lt(i, len) {
				i := add(i, 1)
			} {

				// Extract the token, to, and amount tuples from the array chunks.
				let token := mload(add(_payments, add(mul(i, 0x60), 0x20)))
				let to := mload(add(_payments, add(mul(i, 0x60), 0x40)))
				let amount := mload(add(_payments, add(mul(i, 0x60), 0x60)))
				
				// Switch and handle the case of sending and accumulating Ether.
				switch token
				case 0 {
					ethPayment := add(ethPayment, amount)

					/*
						Attempt to pay `amount` Ether to the `to` destination, reverting if 
						unsuccessful.
					*/
					let result := call(gas(), to, amount, 0, 0, 0, 0)
					if iszero(result) {
						revert(0, 0)
					}
				}

				// Handle the case of ERC-20 token transfers.
				default {

					// Create a pointer at position 0x40.
					let data := mload(0x40)

					/*
						Create a valid `transferERC20` payload in data. TransferERC20 takes 
						as parameters `_token`, `_from`, `_to`, and `_amount`.
					*/
					mstore(data, sig)
					mstore(add(data, 0x04), token)
					mstore(add(data, 0x24), _buyer)
					mstore(add(data, 0x44), to)
					mstore(add(data, 0x64), amount)

					/*
						Attempt to execute the ERC-20 transfer, reverting upon failure. The 
						size of the data is 0x84.
					*/
					let result := call(gas(), _proxy, 0, data, 0x84, 0, 0)
					if iszero(result) {
						revert(0, 0)
					}
				}
			}
		}

		// Refund any excess Ether to the buyer.
		if (msg.value > ethPayment) {
			_buyer.transferEth(msg.value - ethPayment);
		}
	}
}