// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "../libraries/Sales.sol";
import "../proxy/AuthenticatedProxy.sol";

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Entities Library
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>

	A library for managing supported order entities and helper functions.

	@custom:date December 4th, 2022.
*/
library Entities {

	/// The function selector for an ERC-1155 transfer.
	bytes4 internal constant _ERC1155_TRANSFER_SELECTOR = 0xf242432a;

	/// The function selector for an ERC-721 transfer.
	bytes4 internal constant _ERC721_TRANSFER_SELECTOR = 0x23b872dd;

	/// The EIP-712 typehash of an order outline.
	bytes32 public constant OUTLINE_TYPEHASH =
		keccak256(
			"Outline(uint256 basePrice,uint256 listingTime,uint256 expirationTime,address exchange,address maker,uint8 side,address taker,uint8 saleKind,address target,uint8 callType,address paymentToken)"
		);

	/// The EIP-712 typehash of an order.
	bytes32 public constant ORDER_TYPEHASH =
		keccak256(
			"Order(uint256 nonce,Outline outline,uint256[] extra,bytes data)Outline(uint256 basePrice,uint256 listingTime,uint256 expirationTime,address exchange,address maker,uint8 side,address taker,uint8 saleKind,address target,uint8 callType,address paymentToken)"
		);

	/**
		A struct for supporting internal Order details in order to avoidd 
		stack-depth issues.

		@param basePrice The base price of the order in `paymentToken`. This is the 
			price of fulfillment for static sale kinds. This is the starting price 
			for `DecreasingPrice` sale kinds.
		@param listingTime The listing time of the order.
		@param expirationTime The expiration time of the order.
		@param exchange The address of the exchange contract, intended as a 
			versioning mechanism if the exchange is upgraded.
		@param maker The address of the order maker.
		@param side The sale side of the deal (Buy or Sell). This is a handy flag 
			for determining which delegate proxy to use depending for participants on 
			different ends of the order.
		@param taker The order taker address if one is specified. This 
			spepcification is only honored in `DirectListing` and `DirectOffer` sale 
			kinds; in other cases we write dynamic addresses.
		@param saleKind The kind of sale to fulfill in this order.
		@param target The target of the order. This should be the address of an 
			item collection to perform a transfer on.
		@param callType The type of proxy call to perform in fulfilling this order.
		@param paymentToken The address of an ERC-20 token used to pay for the 
			order, or the zero address to fulfill payment with Ether.
	*/
	struct Outline {
		uint256 basePrice;
		uint256 listingTime;
		uint256 expirationTime;
		address exchange;
		address maker;
		Sales.Side side;
		address taker;
		Sales.SaleKind saleKind;
		address target;
		AuthenticatedProxy.CallType callType;
		address paymentToken;
	}

	/**
		A struct for managing an order on the exchange.

		@param nonce The order nonce used to prevent duplicate order hashes.
		@param outline A struct of internal order details.
		@param extra An array of extra order information. The first element of this 
			array should be the index for on-chain royalties of the collection 
			involved in the order. In the event of a `DecreasingPrice` sale kind, the 
			second element should be the targeted floor price of the listing and the 
			third element should be the time at which the floor price is reached.
		@param data The call data of the order.
	*/
	struct Order {
		uint256 nonce;
		Outline outline;
		uint256[] extra;
		bytes data;
	}

	/**
		A struct for an ECDSA signature.

		@param v The v component of the signature.
		@param r The r component of the signature.
		@param s The s component of the signature.
	*/
	struct Sig {
		uint8 v;
		bytes32 r;
		bytes32 s;
	}

	/**
		A helper function to hash the outline of an `Order`.

		@param _outline The outline of an `Order` to hash.

		@return _ A hash of the order outline.
	*/
	function _hash (
		Outline memory _outline
	) private pure returns (bytes32) {
		return keccak256(
			abi.encode(
				OUTLINE_TYPEHASH,
				_outline.basePrice,
				_outline.listingTime,
				_outline.expirationTime,
				_outline.exchange,
				_outline.maker,
				_outline.side,
				_outline.taker,
				_outline.saleKind,
				_outline.target,
				_outline.callType,
				_outline.paymentToken
			)
		);
	}

	/**
		Hash an order and return the canonical order hash without a message prefix.

		@param _order The `Order` to hash.

		@return _ The hash of `_order`.
	*/
	function hash (
		Order memory _order
	) internal pure returns (bytes32) {
		return keccak256(
			abi.encode(
				ORDER_TYPEHASH,
				_order.nonce,
				_hash(_order.outline),
				keccak256(abi.encodePacked(_order.extra)),
				keccak256(_order.data)
			)
		);
	}

	/**
		Validate the selector of the call data of the provided `Order` `_order`. 
		This prevents callers from executing arbitrary functions; only attempted 
		transfers. The transfers may still be arbitrary and malicious, however.

		@param _order The `Order` to validate the call data selector for.

		@return _ Whether or not the call has been validated.
	*/
	function validateCall (
		Order memory _order
	) internal pure returns (bool) {
		bytes memory data = _order.data;

		/*
			Retrieve the selector and verify that it matches either of the ERC-721 or 
			ERC-1155 transfer functions.
		*/
		bytes4 selector;
		assembly {
			selector := mload(add(data, 0x20))
		}
		return
			selector == _ERC1155_TRANSFER_SELECTOR ||
			selector == _ERC721_TRANSFER_SELECTOR;
	}

	/**
		Populate the call data of the provided `Order` `_order` with the `_taker` 
		address and item `_tokenId` based on the kind of sale specified in the 
		`_order`.

		This function uses assembly to directly manipulate the order data. The 
		offsets are determined based on the length of the order data array and the 
		location of the call parameter being inserted.

		In both the ERC-721 `transferFrom` function and the ERC-1155 
		`safeTransferFrom` functions, the `_from` address is the first parameter, 
		the `_to` address is the second parameter and the `_tokenId` is the third 
		parameter.

		The length of the order data is always 0x20 and the function selector is 
		0x04. Therefore the first parameter begins at 0x24. The second parameter 
		lands at 0x44, and the third parameter lands at 0x64. Depending on the sale 
		kind of the order, this function inserts any required dynamic information 
		into the order data.

		@param _order The `Order` to populate call data for based on its sale kind.
		@param _taker The address of the caller who fulfills the order.
		@param _tokenId The token ID of the item involved in the `_order`.

		@param data The order call data with the new fields inserted as needed.
	*/
	function generateCall (
		Order memory _order,
		address _taker,
		uint256 _tokenId
	) internal pure returns (bytes memory data) {

		data = _order.data;
		uint8 saleKind = uint8(_order.outline.saleKind);
		assembly {
			switch saleKind

			/*
				In a `FixedPrice` order, insert the `taker` address as the `_to` 
				parameter in the transfer call.
			*/
			case 0 {
				mstore(add(data, 0x44), _taker)
			}

			/*
				In a `DecreasingPrice` order, insert the `taker` address as the `_to` 
				parameter in the transfer call.
			*/
			case 1 {
				mstore(add(data, 0x44), _taker)
			}

			/*
				In an `Offer` order, insert the `taker` address as the `_from` 
				parameter in the transfer call.
			*/
			case 4 {
				mstore(add(data, 0x24), _taker)
			}

			/*
				In a `CollectionOffer` order, insert the `taker` address as the 
				`_from` parameter and the `_tokenId` as the `_tokenId` parameter in the 
				transfer call.
			*/
			case 5 {
				mstore(add(data, 0x24), _taker)
				mstore(add(data, 0x64), _tokenId)
			}

			/*
				In the `DirectListing` and `DirectOffer` sale kinds, all elements of 
				the order are fully specified and no generation occurs.
			*/
			default {
			}
		}
	}
}