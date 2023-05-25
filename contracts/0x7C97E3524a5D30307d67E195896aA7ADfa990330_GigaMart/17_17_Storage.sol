// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
	MemoryPointer,
	ONE_WORD,
	TWO_WORDS,
	ZERO_MEMORY_SLOT
} from "./Helpers.sol";
/*
	This file contains functions for accessing the storage from other
	contract components w/o inheritance.
 */

// slot 0 is taken by ReentrancyGuard _status 
// slot 1 is taken by Ownable _owner
// slot 2 is taken by PermitControl permissions
// slot 3 is taken by PermitControl managerRight
uint256 constant ORDER_STATUS_SLOT = 4;

/**
	Reads and returns status of the order by `_hash`.

	@param _hash Hash of the order.

	@return status Status of the order.
*/
function _getOrderStatus (
	bytes32 _hash
) view returns(uint256 status) {
	assembly{
		// Store order hash in the first memory slot.
		mstore(ZERO_MEMORY_SLOT, _hash)
		// Store order status mapping storage slot in the second memory slot.
		mstore(add(ZERO_MEMORY_SLOT, ONE_WORD), ORDER_STATUS_SLOT)
		// Hash first two memory slots, and read storage at computed slot.
		status := sload(
			keccak256(ZERO_MEMORY_SLOT, TWO_WORDS)
		)
	}
}

/**
	Updates order status by `_hash`.

	@param _hash Hash of the order.
	@param _status New order status.
*/
function _setOrderStatus (
	bytes32 _hash,
	uint256 _status
) {
	assembly{
		// Store order hash in the first memory slot.
		mstore(ZERO_MEMORY_SLOT, _hash)
		// Store order status mapping storage slot in the second memory slot.
		mstore(add(ZERO_MEMORY_SLOT, ONE_WORD), ORDER_STATUS_SLOT)
		// Hash first two memory slots, and store new status in the computed slot.
		sstore(
			keccak256(ZERO_MEMORY_SLOT, TWO_WORDS),
			_status
		)
	}
}

uint256 constant PROTOCOL_FEE_SLOT = 5;

/**
	Returns protocol fee config (160 bits of add + 96 bits of fee percent).

	@return protocolFee Packed protocol fee config.
*/
function _getProtocolFee () view returns (uint256 protocolFee) {
	assembly{
		protocolFee := sload(PROTOCOL_FEE_SLOT)
	}
}

/**
	Updates protocol fee config.

	@param _protocolFee New protocol fee config.
*/
function _setProtocolFee (uint256 _protocolFee) {
	assembly {
		sstore(PROTOCOL_FEE_SLOT, _protocolFee)
	}
} 


uint256 constant ROYALTIES_SLOT = 6;

/**
	Reads and returns current royalty config 
	(160 bits of add + 96 bits of fee percent).

	@param _collection Address of the collection in question.
	@param _index Index, which was signed with the order.

	@return royalty royalty config.
*/
function _getRoyalty (
	address _collection,
	uint256 _index
) view returns (uint256 royalty) {
	assembly {
		// Store collection address in first memory slot.
		mstore(ZERO_MEMORY_SLOT, _collection)
		// Store slot of the royalties mapping in second memory slot.
		mstore(add(ZERO_MEMORY_SLOT, ONE_WORD), ROYALTIES_SLOT)
		// Hash first two memory slots.
		let nestedHash := keccak256(ZERO_MEMORY_SLOT, TWO_WORDS)
		// Store index in first memory slot.
		mstore(ZERO_MEMORY_SLOT, _index)
		// Store previosly computed hash in second memory slot.
		mstore(add(ZERO_MEMORY_SLOT, ONE_WORD), nestedHash)
		// Hash first two memory slots, and read storage at computed slot.
		royalty := sload(
			keccak256(ZERO_MEMORY_SLOT, TWO_WORDS)
		)
	}
}	

/**
	Updates royalty config for the collection. Increments royalty index by 1.

	@param _collection Address of the collection in question.
	@param _newRoyalty New royalty config.
*/
function _setRoyalty (
	address _collection,
	uint256 _newRoyalty
) {
	assembly{
		// Store collection address in the first memory slot
		mstore(ZERO_MEMORY_SLOT, _collection)
		// Store royalty indices mapping storage slot in the second memory slot.
		mstore(add(ZERO_MEMORY_SLOT, ONE_WORD), ROYALTY_INDICES_SLOT)
		// Hash first two memory slots, and read index at computed slot.
		let indexSlot := keccak256(ZERO_MEMORY_SLOT, TWO_WORDS)
		// Increment index
		let index := add(sload(indexSlot), 1)
		// Store incremented index value
		sstore(indexSlot, index)
		// Store royalties mapping storage slot in second memory slot.
		mstore(add(ZERO_MEMORY_SLOT, ONE_WORD), ROYALTIES_SLOT)
		// Collection address is still in the first memory slot.
		// Hash first two memory slots to compute nested mapping key.
		let nestedKey := keccak256(ZERO_MEMORY_SLOT, TWO_WORDS)
		// Store incremented index value in the first memory slot.
		mstore(ZERO_MEMORY_SLOT, index)
		// Store nested mapping key in the second memory slot
		mstore(add(ZERO_MEMORY_SLOT, ONE_WORD), nestedKey)
		// Hash first two memory slots, and store new royalty in the computed slot.
		sstore(
			keccak256(ZERO_MEMORY_SLOT, TWO_WORDS),
			_newRoyalty
		)
	}
}

uint256 constant ROYALTY_INDICES_SLOT = 7;

/**
	Reads and returns current royalty index for the collection.

	@param _collection address of the collection in question.

	@return index current royalty index of the `_collection`.
*/
function _getRoyaltyIndex (
	address _collection
) view returns (uint256 index) {
	assembly {
		// Store collection address in the first memory slot.
		mstore(ZERO_MEMORY_SLOT, _collection)
		// Store royalty indices mapping storage slot in the second memory slot.
		mstore(add(ZERO_MEMORY_SLOT, ONE_WORD), ROYALTY_INDICES_SLOT)
		// Hash first two memory slots, and read storage at computed slot.
		index := sload(
			keccak256(ZERO_MEMORY_SLOT, TWO_WORDS)
		)
	}
}

uint256 constant VALIDATOR_SLOT = 8;

/**
	Reads and returns validator address.

	@return validatorAddress Address of the royalty validator.
*/
function _getValidatorAddress () view returns (address validatorAddress) {
	assembly{
		validatorAddress := sload(VALIDATOR_SLOT)
	}
}

/**
	Sets new validator address.

	@param _validatorAddress New royalty validator address.
*/
function _setValidatorAddress (address _validatorAddress) {
	assembly {
		sstore(VALIDATOR_SLOT, _validatorAddress)
	}
} 

uint256 constant USER_NONCE_SLOT = 9;

/**
	Reads and returns user nonce.

	@param _user address of the user in question.

	@return nonce user nonce.
*/
function _getUserNonce (
	address _user
) view returns(uint256 nonce) {
	assembly {
		// Store user address in the first memory slot.
		mstore(ZERO_MEMORY_SLOT, _user)
		// Store nonce mapping storage slot in the second memory slot.
		mstore(add(ZERO_MEMORY_SLOT, ONE_WORD), USER_NONCE_SLOT)
		// Hash first two memory slots, and read storage at computed slot.
		nonce := sload(
			keccak256(ZERO_MEMORY_SLOT, TWO_WORDS)
		)
	}
}

/**
	Sets new value for the user nonce.

	@param _newNonce New user nonce value.
*/
function _setUserNonce (
	uint256 _newNonce
) {
	assembly{
		// Store msg.sender address in the first memory slot.
		mstore(ZERO_MEMORY_SLOT, caller())
		// Store nonce mapping storage slot in the second memory slot.
		mstore(add(ZERO_MEMORY_SLOT, ONE_WORD), USER_NONCE_SLOT)
		// Hash first two memory slots, and store new nonce in the computed slot.
		sstore(
			keccak256(ZERO_MEMORY_SLOT, TWO_WORDS),
			_newNonce
		)
	}
}

uint256 constant ORDER_FILL_AMOUNT_SLOT = 10;

/**
	Reads and returns current fill amount for the order by hash.

	@param _hash Hash of the order.

	@return amount previously filled amount for the order.
*/
function _getOrderFillAmount (
	bytes32 _hash
) view returns(uint256 amount) {
	assembly{
		// Store order hash in the first memory slot.
		mstore(ZERO_MEMORY_SLOT, _hash)
		// Store order fill amount mapping storage slot in the second memory slot.
		mstore(add(ZERO_MEMORY_SLOT, ONE_WORD), ORDER_FILL_AMOUNT_SLOT)
		// Hash first two memory slots, and read storage at computed slot.
		amount := sload(
			keccak256(ZERO_MEMORY_SLOT, TWO_WORDS)
		)
	}
}

/**
	Store order fill amount mapping storage slot in the second memory slot.

	@param _hash Hash of the order.
	@param _amount Updated order fill amount.
*/
function _setOrderFillAmount (
	bytes32 _hash,
	uint256 _amount
) {
	assembly{
		// Store order hash in the first memory slot.
		mstore(ZERO_MEMORY_SLOT, _hash)
		// Store order fill amount mapping storage slot in the second memory slot.
		mstore(add(ZERO_MEMORY_SLOT, ONE_WORD), ORDER_FILL_AMOUNT_SLOT)
		// Hash first two memory slots, and store new amount in the computed slot.
		sstore(
			keccak256(ZERO_MEMORY_SLOT, TWO_WORDS),
			_amount
		)
	}
}