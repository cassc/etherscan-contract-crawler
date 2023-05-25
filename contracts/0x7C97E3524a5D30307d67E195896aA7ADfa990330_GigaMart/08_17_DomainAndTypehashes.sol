// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
	ONE_WORD,
	TWO_WORDS,
	ONE_WORD_SHIFT,
	PROOF_KEY,
	PROOF_KEY_SHIFT,
	ECDSA_MAX_LENGTH
} from "./Helpers.sol";

import {
	MAX_BULK_ORDER_HEIGHT,
	ORDER_TYPEHASH,
	BULK_ORDER_HEIGHT_ONE_TYPEHASH,
	BULK_ORDER_HEIGHT_TWO_TYPEHASH,
	BULK_ORDER_HEIGHT_THREE_TYPEHASH,
	BULK_ORDER_HEIGHT_FOUR_TYPEHASH,
	BULK_ORDER_HEIGHT_FIVE_TYPEHASH,
	BULK_ORDER_HEIGHT_SIX_TYPEHASH,
	BULK_ORDER_HEIGHT_SEVEN_TYPEHASH,
	BULK_ORDER_HEIGHT_EIGHT_TYPEHASH,
	BULK_ORDER_HEIGHT_NINE_TYPEHASH,
	BULK_ORDER_HEIGHT_TEN_TYPEHASH
} from "./OrderConstants.sol";

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title EIP-712 Domain Manager
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>

	A contract for providing EIP-712 signature-services.
*/
contract DomainAndTypehashes {

	/**
		The typehash of the EIP-712 domain, used in dynamically deriving a domain 
		separator.
	*/
	/**
		The typehash of the EIP-712 domain, used in dynamically deriving a domain 
		separator.

		keccak256(
			"EIP712Domain(
				string name,
				string version,
				uint256 chainId
				,address verifyingContract
			)"
		)
	*/
	bytes32 private constant _EIP712_DOMAIN_TYPEHASH = 
		0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

	/// A name used in the domain separator.
	string public constant name = "GigaMart";

	/// The immutable chain ID detected during construction.
	uint256 internal immutable _CHAIN_ID;

	/// The immutable chain ID created during construction.
	bytes32 private immutable _DOMAIN_SEPARATOR;

	/**
		Construct a new EIP-712 domain instance.
	*/
	constructor () {

		uint chainId;
		assembly {
			chainId := chainid()
		}
		_CHAIN_ID = chainId;
		_DOMAIN_SEPARATOR = keccak256(
			abi.encode(
				_EIP712_DOMAIN_TYPEHASH,
				keccak256(bytes(name)),
				keccak256(bytes(version())),
				chainId,
				address(this)
			)
		);
	}

	/**
		Return the version of this EIP-712 domain.

		@return _ The version of this EIP-712 domain.
	*/
	function version () public pure returns (string memory) {
		return "1";
	}

	/**
		Dynamically derive an EIP-712 domain separator.

		@return _ A constructed domain separator.
	*/
	function _deriveDomainSeparator () internal view returns (bytes32) {
		uint chainId;
		assembly {
			chainId := chainid()
		}
		return chainId == _CHAIN_ID
			? _DOMAIN_SEPARATOR
			: keccak256(
				abi.encode(
					_EIP712_DOMAIN_TYPEHASH,
					keccak256(bytes(name)),
					keccak256(bytes(version())),
					chainId,
					address(this)
				)
			);
	}

	/**
		Computes hash from previously calculated order hash
			and merkle tree proofs,

		@param _proofAndSignature signature concatenated with
			proofs for the order.
		@param _leaf hash of the order.

		@return bulkOrderHash hash of the merkle tree.
	 */
	function _computeBulkOrderHash (
        bytes calldata _proofAndSignature,
        bytes32 _leaf
    ) internal pure returns (bytes32 bulkOrderHash) {
        // Declare arguments for the root hash and the height of the proof.
        bytes32 root;
        uint256 height;
		
        // Utilize assembly to efficiently derive the root hash using the proof.
        assembly {
            // Retrieve the length of the proof, key, and signature combined.
            let fullLength := _proofAndSignature.length

            // If proofAndSignature has odd length, it is a compact signature
            // with 64 bytes.
            let signatureLength := sub(ECDSA_MAX_LENGTH, and(fullLength, 1))

            // Derive height (or depth of tree) with signature and proof length.
            height := shr(ONE_WORD_SHIFT, sub(fullLength, signatureLength))

            // Derive the pointer for the key using the signature length.
            let keyPtr := add(_proofAndSignature.offset, signatureLength)
		
            // Retrieve the three-byte key using the derived pointer.
            let key := shr(PROOF_KEY_SHIFT, calldataload(keyPtr))
	
            /// Retrieve pointer to first proof element by applying a constant
            // for the key size to the derived key pointer.
            let proof := add(keyPtr, PROOF_KEY)
			
           // Compute level 1.
            let scratchPtr1 := shl(ONE_WORD_SHIFT, and(key, 1))
            mstore(scratchPtr1, _leaf)
            mstore(xor(scratchPtr1, ONE_WORD), calldataload(proof))

            // Compute remaining proofs.
            for {
                let i := 1
            } lt(i, height) {
                i := add(i, 1)
            } {
                proof := add(proof, ONE_WORD)
                let scratchPtr := shl(ONE_WORD_SHIFT, and(shr(i, key), 1))
                mstore(scratchPtr, keccak256(0, TWO_WORDS))
                mstore(xor(scratchPtr, ONE_WORD), calldataload(proof))
            }

            // Compute root hash.
            root := keccak256(0, TWO_WORDS)

			let typeHash

			switch height
				case 1 {
					typeHash := BULK_ORDER_HEIGHT_ONE_TYPEHASH
				}
				case 2 {
					typeHash := BULK_ORDER_HEIGHT_TWO_TYPEHASH
				}
				case 3 {
					typeHash := BULK_ORDER_HEIGHT_THREE_TYPEHASH
				}
				case 4 {
					typeHash := BULK_ORDER_HEIGHT_FOUR_TYPEHASH
				}
				case 5 {
					typeHash := BULK_ORDER_HEIGHT_FIVE_TYPEHASH
				}
				case 6 {
					typeHash := BULK_ORDER_HEIGHT_SIX_TYPEHASH
				}
				case 7 {
					typeHash := BULK_ORDER_HEIGHT_SEVEN_TYPEHASH
				}
				case 8 {
					typeHash := BULK_ORDER_HEIGHT_EIGHT_TYPEHASH
				}
				case 9 {
					typeHash := BULK_ORDER_HEIGHT_NINE_TYPEHASH
				}
				case 10 {
					typeHash := BULK_ORDER_HEIGHT_TEN_TYPEHASH
				}
				default {
					typeHash := ORDER_TYPEHASH
				}
      
        	// Use the typehash and the root hash to derive final bulk order hash.
            mstore(0, typeHash)
            mstore(ONE_WORD, root)
            bulkOrderHash := keccak256(0, TWO_WORDS)
        }
    }
}