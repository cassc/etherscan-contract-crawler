// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {
	BaseFeeManager
} from "./BaseFeeManager.sol";
import {
	EIP712
} from "../libraries/EIP712.sol";

/// Thrown if attempting to set the validator address to zero.
error ValidatorAddressCannotBeZero ();

/// Thrown if the signature provided by the validator is expired.
error SignatureExpired ();

/// Thrown if the signature provided by the validator is invalid.
error BadSignature ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Royalty Manager
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>

	A contract for providing an EIP-712 signature-based approach for on-chain 
	direct royalty payments with royalty management as gated by an off-chain 
	validator.

	This approach to royalty management is a point of centralization on GigaMart. 
	The validator key gives its controller the ability to arbitrarily change 
	collection royalty fees.

	This approach is justified based on the fact that it allows GigaMart to offer 
	a gas-optimized middle ground where royalty fees are paid out directly to 
	collection owners while still allowing an arbitrary number of collection 
	administrators to manage collection royalty fees based on off-chain role 
	management semantics.

	@custom:date December 4th, 2022.
*/
abstract contract RoyaltyManager is EIP712, BaseFeeManager {

	/// The public identifier for the right to change the validator address.
	bytes32 public constant VALIDATOR_SETTER = keccak256("VALIDATOR_SETTER");

	/// The EIP-712 typehash of a royalty update.
	bytes32 public constant ROYALTY_TYPEHASH =
		keccak256(
			"Royalty(address setter,address collection,uint256 deadline,uint256 newRoyalties)"
		);

	/// The address of the off-chain validator.
	address internal validator;

	/**
		A double mapping of collection address to index to royalty percent. This 
		allows makers to securely sign their orders safe in the knowledge that 
		royalty fees cannot be altered from beneath them.
	*/
	mapping ( address => mapping ( uint256 => uint256 )) public royalties;
	
	/// A mapping of collection addresses to the current royalty index.
	mapping ( address => uint256 ) public indices;

	/**
		Emitted after altering the royalty fee of a collection.

		@param setter The address which altered the royalty fee.
		@param collection The collection which had its royalty fee altered.
		@param oldRoyalties The old royalty fee of the collection.
		@param newRoyalties The new royalty fee of the collection.
	*/
	event RoyaltyChanged (
		address indexed setter,
		address indexed collection,
		uint256 oldRoyalties,
		uint256 newRoyalties
	);

	/**
		Construct a new instance of the GigaMart royalty fee manager.

		@param _validator The address to use as the royalty change validation 
			signer.
		@param _protocolFeeRecipient The address which receives protocol fees.
		@param _protocolFeePercent The percent in basis points of the protocol fee.
	*/
	constructor (
		address _validator,
		address _protocolFeeRecipient,
		uint96 _protocolFeePercent
	) BaseFeeManager(_protocolFeeRecipient, _protocolFeePercent) {
		validator = _validator;
	}

	/**
		Returns the current royalty fees of a collection.

		@param _collection The collection to return the royalty fees for.

		@return _ A tuple pairing the address of a collection fee recipient with 
			the actual royalty fee.
	*/
	function currentRoyalties (
		address _collection
	) external view returns (address, uint256) {
		uint256 fee = royalties[_collection][indices[_collection]];

		// The fee is a packed address-fee pair into a single 256 bit integer.
		return (address(uint160(fee >> 96)), uint256(uint96(fee)));
	}

	/**
		Change the `validator` address.

		@param _validator The new `validator` address to set.

		@custom:throws ValidatorAddressCannotBeZero if attempting to set the 
			`validator` address to the zero address.
	*/
	function changeValidator (
		address _validator
	) external hasValidPermit(UNIVERSAL, VALIDATOR_SETTER) {
		if (_validator == address(0)) {
			revert ValidatorAddressCannotBeZero();
		}
		validator = _validator;
	}

	/**
		Generate a hash from the royalty changing parameters.
		
		@param _setter The caller setting the royalty changes.
		@param _collection The address of the collection for which royalties will 
			be altered.
		@param _deadline The time when the `_setter` loses the right to alter 
			royalties.
		@param _newRoyalties The new royalty information to set.

		@return _ The hash of the royalty parameters for checking signature 
			validation.
	*/
	function _hash (
		address _setter,
		address _collection,
		uint256 _deadline,
		uint256 _newRoyalties
	) internal view returns (bytes32) {
		return keccak256(
			abi.encodePacked(
				"\x19\x01",
				_deriveDomainSeparator(),
				keccak256(
					abi.encode(
						ROYALTY_TYPEHASH,
						_setter,
						_collection,
						_deadline,
						_newRoyalties
					)
				)
			)
		);
	}

	/**
		Update the royalty mapping for a collection with a new royalty.

		@param _collection The address of the collection for which `_newRoyalties` 
			are set.
		@param _deadline The time until which the `_signature` is valid.
		@param _newRoyalties The updated royalties to set.
		@param _signature A signature signed by the `validator`.

		@custom:throws BadSignature if the signature submitted for setting 
			royalties is invalid.
		@custom:throws SignatureExpired if the signature is expired.
	*/
	function setRoyalties (
		address _collection,
		uint256 _deadline,
		uint256 _newRoyalties,
		bytes calldata _signature
	) external {

		// Verify that the signature was signed by the royalty validator.
		if (
			_recover(
				_hash(msg.sender, _collection, _deadline, _newRoyalties),
				_signature
			) != validator
		) {
			revert BadSignature();
		}

		// Verify that the signature has not expired.
		if (_deadline < block.timestamp) {
			revert SignatureExpired();
		}
		
		/*
			Increment the current royalty index for the collection and update its 
			royalty information.
		*/
		uint256 oldRoyalties = royalties[_collection][indices[_collection]];
		indices[_collection]++;
		royalties[_collection][indices[_collection]] = _newRoyalties;

		// Emit an event notifying about the royalty change.
		emit RoyaltyChanged(msg.sender, _collection, oldRoyalties, _newRoyalties);
	}
}