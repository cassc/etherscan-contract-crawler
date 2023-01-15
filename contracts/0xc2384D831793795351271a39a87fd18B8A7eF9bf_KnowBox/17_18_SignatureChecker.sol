// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./KnowBoxInfo.sol";

library SignatureChecker {
	address private constant signer = 0x9add88207AC0Db396d6050716BADB7eC6C96bA33;

	bytes32 public constant MINT_HASH = 0x5bf9043e1eaa47b5c26a6a6eef0b4f9f128379e0b6c47e5e98b66123e7c0164e;

	bytes32 public constant OPEN_HASH = 0x407e394ce1be01de81e6dae9c411116d2aba76150bb021cb4e97216cc7ef30d6;

	function recover(
		bytes32 hash,
		uint8 v,
		bytes32 r,
		bytes32 s
	) internal pure returns (address) {
		require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "Signature: Invalid s parameter");

		require(v == 27 || v == 28, "Signature: Invalid v parameter");

		address signer_ = ecrecover(hash, v, r, s);
		require(signer_ != address(0), "Signature: Invalid signer");

		return signer_;
	}

	function verifyMint(KnowBoxInfo.MintInfo calldata mintInfo, bytes32 domainSeparator) internal pure returns (bool) {
		bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, getMintInfoHash(mintInfo)));
		return recover(digest, mintInfo.v, mintInfo.r, mintInfo.s) == signer;
	}

	function verifyOpen(KnowBoxInfo.OpenInfo calldata openInfo, bytes32 domainSeparator) internal pure returns (bool) {
		bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, getOpenInfoHash(openInfo)));
		return recover(digest, openInfo.v, openInfo.r, openInfo.s) == signer;
	}

	function getMintInfoHash(KnowBoxInfo.MintInfo calldata info) internal pure returns (bytes32) {
		return keccak256(abi.encode(MINT_HASH, info.minter, info.counter, keccak256(bytes(info.cdkey))));
	}

	function getOpenInfoHash(KnowBoxInfo.OpenInfo calldata info) internal pure returns (bytes32) {
		return keccak256(abi.encode(OPEN_HASH, info.token, info.salt));
	}
}