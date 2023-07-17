// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { InputBet } from "./BetStructs.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

/**
 * @title EIP712
 * @dev Contains all of the order hashing functions for EIP712 compliant signatures
 */
contract EIP712 {

	using ECDSAUpgradeable for bytes32;

	struct EIP712Domain {
		string  name;
		string  version;
		uint256 chainId;
		address verifyingContract;
	}

	/* Order typehash for EIP 712 compatibility. */
	bytes32 constant public BET_TYPEHASH = keccak256(
		"Bet(uint256 matchId,address bettor,uint16 target,uint32 odds,uint256 amount,uint256 nonce)"
	);
	bytes32 constant public ROOT_TYPEHASH = keccak256(
		"Root(bytes32 root)"
	);

	bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
		"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
	);

	function _getDomainSeparator() internal view virtual returns (bytes32) {
		return _hashDomain(EIP712Domain({
				name              : "EIP712Domain",
				version           : "1.0",
				chainId           : block.chainid,
				verifyingContract : address(this)
		}));
	}

	function _hashDomain(EIP712Domain memory eip712Domain)
		internal
		pure
		returns (bytes32)
	{
		return keccak256(
			abi.encode(
				EIP712DOMAIN_TYPEHASH,
				keccak256(bytes(eip712Domain.name)),
				keccak256(bytes(eip712Domain.version)),
				eip712Domain.chainId,
				eip712Domain.verifyingContract
			)
		);
	}

	function _hashBets(InputBet[] calldata bets, uint256 nonce)
		internal
		pure
		returns (bytes32[] memory)
	{
		bytes32[] memory betHashes = new bytes32[](
			bets.length
		);
		for (uint256 i = 0; i < bets.length; i++) {
			betHashes[i] = _hashBet(bets[i], nonce);
		}
		return betHashes;
	}

	function _hashBet(InputBet calldata bet, uint256 nonce)
		internal
		pure
		returns (bytes32)
	{
		return keccak256(
			abi.encode(
				BET_TYPEHASH,
				bet.matchId,
				bet.bettor,
				bet.target,
				bet.odds,
				bet.amount,
				nonce
			)
		);
	}

	function _hashToSign(bytes32 orderHash)
		internal
		view
		returns (bytes32 hash)
	{
		return keccak256(abi.encodePacked(
				"\x19\x01",
				_getDomainSeparator(),
				orderHash
			));
	}

	function _hashToSignRoot(bytes32 root)
		internal
		view
		returns (bytes32 hash)
	{
		return keccak256(abi.encodePacked(
				"\x19\x01",
				_getDomainSeparator(),
				keccak256(abi.encode(
					ROOT_TYPEHASH,
					root
				))
			));
	}

}