// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/// Thrown if attempting to recover a signature of invalid length.
error InvalidSignatureLength ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title EIP-712 Domain Manager
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>

	A contract for providing EIP-712 signature-services.

	@custom:date December 4th, 2022.
*/
abstract contract EIP712 {

	/**
		The typehash of the EIP-712 domain, used in dynamically deriving a domain 
		separator.
	*/
	bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(
		"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
	);

	/// A name used in the domain separator.
	string public constant name = "GigaMart";

	/// The immutable chain ID detected during construction.
	uint256 private immutable CHAIN_ID;

	/// The immutable chain ID created during construction.
	bytes32 private immutable DOMAIN_SEPARATOR;

	/**
		Construct a new EIP-712 domain instance.
	*/
	constructor () {
		uint chainId;
		assembly {
			chainId := chainid()
		}
		CHAIN_ID = chainId;
		DOMAIN_SEPARATOR = keccak256(
			abi.encode(
				EIP712_DOMAIN_TYPEHASH,
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
		return chainId == CHAIN_ID
			? DOMAIN_SEPARATOR
			: keccak256(
				abi.encode(
					EIP712_DOMAIN_TYPEHASH,
					keccak256(bytes(name)),
					keccak256(bytes(version())),
					chainId,
					address(this)
				)
			);
	}

	/**
		Recover the address which signed `_hash` with signature `_signature`.

		@param _hash A hash signed by an address.
		@param _signature The signature of the hash.

		@return _ The address which signed `_hash` with signature `_signature.

		@custom:throws InvalidSignatureLength if the signature length is not valid.
	*/
	function _recover (
		bytes32 _hash,
		bytes memory _signature
	) internal pure returns (address) {

		// Validate that the signature length is as expected.
		if (_signature.length != 65) {
			revert InvalidSignatureLength();
		}

		// Divide the signature into r, s and v variables.
		bytes32 r;
		bytes32 s;
		uint8 v;
		assembly {
			r := mload(add(_signature, 0x20))
			s := mload(add(_signature, 0x40))
			v := byte(0, mload(add(_signature, 0x60)))
		}

		// Return the recovered address.
		return ecrecover(_hash, v, r, s);
	}
}