// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
	ProtocolFeeManager
} from "./ProtocolFeeManager.sol";

import {
	DomainAndTypehashes
} from "./DomainAndTypehashes.sol";

import {
	FREE_MEMORY_POINTER,
	_freeMemoryPointer,
	_recover
} from "./Helpers.sol";

import {
	_getValidatorAddress,
	_setValidatorAddress,
	_getRoyalty,
	_setRoyalty,
	_getRoyaltyIndex
} from "./Storage.sol";

/// Thrown if attempting to set the validator address to zero.
error ValidatorAddressCannotBeZero ();

/// Thrown if the signature provided by the validator is expired.
error SignatureExpired ();

/// Thrown if the signature provided by the validator is invalid.
error BadSignature ();

/// Thrown if attempting to recover a signature of invalid length.
error InvalidSignatureLength ();

/// Thrown if argument arrays length missmatched.
error LengthMismatch();

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
*/
contract RoyaltyManager is DomainAndTypehashes, ProtocolFeeManager {

	/** The public identifier for the right to change the validator address. 
			_VALIDATOR_SETTER = keccak256("VALIDATOR_SETTER");
	*/
	bytes32 private constant _VALIDATOR_SETTER = 
		0xab7922d407ee68907f3012689fc312513191a8f302400319928e871c6d39f8ec;
	

	/**  The EIP-712 typehash of a royalty update.
			keccak256(
	 			"Royalty(
						address setter,
						address collection,
						uint256 deadline,
						uint256 newRoyalties
					)"
			);
	*/
	bytes32 private constant _ROYALTY_TYPEHASH = 
		0xfb611fe2ee773273b2db591335adbd769558cf583a410ad6b83eb8860c37f0d7;

	/**  The EIP-712 typehash of a royalty update.
			keccak256(
	 			"Royalties(
						address setter,
						address[] collections,
						uint256 deadline,
						uint256[] newRoyalties
					)"
			);
	*/
	bytes32 private constant _MULTIPLE_ROYALTIES_TYPEHASH = 
		0xca8317744c36fb2eeb56f974afb6d5cd31ade90176dad0d7a06a624f10c09bdc;

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
	) ProtocolFeeManager(_protocolFeeRecipient, _protocolFeePercent) {
		_setValidatorAddress(_validator);
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
		uint256 fee = _getRoyalty(
			_collection,
			_getRoyaltyIndex(
				_collection
			)
		);

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
	) external hasValidPermit(_UNIVERSAL, _VALIDATOR_SETTER) {
		if (_validator == address(0)) {
			revert ValidatorAddressCannotBeZero();
		}
		_setValidatorAddress(_validator);
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
						_ROYALTY_TYPEHASH,
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
		Generate a hash from the royalty changing parameters.
		
		@param _setter The caller setting the royalty changes.
		@param _collections The address of the collection for which royalties will 
			be altered.
		@param _deadline The time when the `_setter` loses the right to alter 
			royalties.
		@param _newRoyalties The new royalty information to set.

		@return _ The hash of the royalty parameters for checking signature 
			validation.
	*/
	function _hash (
		address _setter,
		address[] calldata _collections,
		uint256 _deadline,
		uint256[] calldata _newRoyalties
	) internal view returns (bytes32) {
		return keccak256(
			abi.encodePacked(
				"\x19\x01",
				_deriveDomainSeparator(),
				keccak256(
					abi.encode(
						_MULTIPLE_ROYALTIES_TYPEHASH,
						_setter,
						keccak256(
							abi.encodePacked(_collections)
						),
						_deadline,
						keccak256(
							abi.encodePacked(_newRoyalties)
						)
					)
				)
			)
		);
	}

	function indices (address _collection) public view returns(uint256) {
		return _getRoyaltyIndex(_collection);
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
			) != _getValidatorAddress()
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
		uint256 oldRoyalties = _getRoyalty(
			_collection,
			_getRoyaltyIndex(
				_collection
			)
		);
		_setRoyalty(
			_collection,
			_newRoyalties
		);

		// Emit an event notifying about the royalty change.
		emit RoyaltyChanged(
			msg.sender,
			_collection,
			oldRoyalties,
			_newRoyalties
		);
	}

	/**
		Update the royalty mapping for a collection with a new royalty.

		@param _collections The addresses of collections for which `_newRoyalties` 
			are set.
		@param _deadline The time until which the `_signature` is valid.
		@param _newRoyalties The updated royalties to set.
		@param _signature A signature signed by the `validator`.

		@custom:throws BadSignature if the signature submitted for setting 
			royalties is invalid.
		@custom:throws SignatureExpired if the signature is expired.
	*/
	function setMultipleRoyalties (
		address[] calldata _collections,
		uint256 _deadline,
		uint256[] calldata _newRoyalties,
		bytes calldata _signature
	) external {

		if (_newRoyalties.length != _collections.length) {
			revert LengthMismatch();
		}

		// Verify that the signature was signed by the royalty validator.
		if (
			_recover(
				_hash(msg.sender, _collections, _deadline, _newRoyalties),
				_signature
			) != _getValidatorAddress()
		) {
			revert BadSignature();
		}

		// Verify that the signature has not expired.
		if (_deadline < block.timestamp) {
			revert SignatureExpired();
		}

		for (uint256 i; i < _collections.length; ) {

			/*
				Increment the current royalty index for the collection and update its 
				royalty information.
			*/
			uint256 oldRoyalties = _getRoyalty(
				_collections[i],
				_getRoyaltyIndex(
					_collections[i]
				)
			);
			_setRoyalty(
				_collections[i],
				_newRoyalties[i]
			);

			// Emit an event notifying about the royalty change.
			emit RoyaltyChanged(
				msg.sender,
				_collections[i],
				oldRoyalties,
				_newRoyalties[i]
			);

			unchecked {
				++i;
			}
		}
	}
}