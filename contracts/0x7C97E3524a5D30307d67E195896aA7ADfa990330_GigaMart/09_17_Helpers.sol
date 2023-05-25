// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/*
	This file contains constants and low-level functions
	for processing signatures.
*/

type MemoryPointer is uint256;

// Default free memory pointer value.
MemoryPointer constant FREE_MEMORY_POINTER = MemoryPointer.wrap(0x80);
uint256 constant ZERO_MEMORY_SLOT = 0x0;
// One 32 bytes word.
uint256 constant ONE_WORD = 0x20;
// Two 32 bytes words.
uint256 constant TWO_WORDS = 0x40; 
// Three 32 bytes words.
uint256 constant THREE_WORDS = 0x60; 
// Amount of bits to increase a pointer on one word.
uint256 constant ONE_WORD_SHIFT = 0x5;
// Length of the proof key.
uint256 constant PROOF_KEY = 0x3;
// Bits to shift to the next key.
uint256 constant PROOF_KEY_SHIFT = 0xe8;
// Max signature length in bytes.
uint256 constant ECDSA_MAX_LENGTH = 65;
// Ethereum message prefix.
bytes2 constant PREFIX = 0x1901;
 // IAssetHandler.transferItem function selector.
bytes4 constant TRANSFER_ITEM_SELECTOR = 0xfb6659f9;
uint256 constant TRANSFER_ITEM_DATA_LENGTH = 0xe4;
uint256 constant ERC721_ITEM_TYPE = 0;
uint256 constant ERC1155_ITEM_TYPE = 1;
// Divisor for percent math.
uint256 constant PRECISION = 10_000; 

/*
	Sets free memory pointer back to defaul value;
*/
function _resetMemoryPointer () pure {
	assembly {
		mstore(0x40, 0x80)
	}
}

/*
	Reads current free memory pointer.
*/
function _freeMemoryPointer () pure returns(MemoryPointer memPtr) {
	assembly{
		memPtr := mload(0x40)
	}
}

// keccak256(abi.encode(bytes(0)))
bytes32 constant HASH_OF_ZERO_BYTES=
    0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

// 1 block reorg gap
uint256 constant LUCKY_NUMBER = 13;

/**
	Recover the address which signed `_hash` with signature `_signature`.

	@param _digest A hash signed by an address.
	@param _signature The signature of the hash.

	@return _ The address which signed `_hash` with signature `_signature.

	@custom:throws InvalidSignatureLength if the signature length is not valid.
*/
function _recover (
	bytes32 _digest,
	bytes calldata _signature
) pure returns (address) {

	// Divide the signature into r, s and v variables.
	bytes32 r;
	bytes32 s;
	uint8 v;
	assembly {
		r := calldataload(_signature.offset)
		s := calldataload(add(_signature.offset, 0x20))
		v := byte(0, calldataload(add(_signature.offset, 0x40)))
	}
	// Return the recovered address.
	return ecrecover(_digest, v, r, s);
}

// The selector for EIP-1271 contract-based signatures.
bytes4 constant EIP_1271_SELECTOR = bytes4(
	keccak256("isValidSignature(bytes32,bytes)")
);

/**
	A helper function to validate an EIP-1271 contract signature.

	@param _orderMaker The smart contract maker of the order.
	@param _hash The hash of the order.
	@param _signature The signature of the order to validate.

	@return _ Whether or not `_signature` is a valid signature of `_hash` by the 
		`_orderMaker` smart contract.
*/
function _recoverContractSignature (
	address _orderMaker,
	bytes32 _hash,
	bytes calldata _signature
) view returns (bool) {
	bytes32 r;
	bytes32 s;
	uint8 v;
	assembly {
		r := calldataload(_signature.offset)
		s := calldataload(add(_signature.offset, 0x20))
		v := byte(0, calldataload(add(_signature.offset, 0x40)))
	}
	bytes memory isValidSignatureData = abi.encodeWithSelector(
		EIP_1271_SELECTOR,
		_hash,
		abi.encodePacked(r, s, v)
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