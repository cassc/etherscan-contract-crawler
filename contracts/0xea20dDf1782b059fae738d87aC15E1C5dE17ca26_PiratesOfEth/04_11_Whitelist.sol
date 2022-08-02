// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

interface ISignatureChecker {
	function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4);
}

abstract contract Whitelist {
	bool public mintWhitelistStarted = false;
	address private immutable _signatureChecker;

	mapping(address => bool) private _blacklist;
	BitMaps.BitMap private _usedSignatures;

	constructor(address signatureChecker) {
		_signatureChecker = signatureChecker;
	}

	modifier notOnBlacklist() {
		require(!_blacklist[msg.sender], "Blacklisted");

		_;
	}

	function _updateBlacklist(address[] memory users, bool[] memory blackListed) internal {
		uint256 length = users.length;
		require(length == blackListed.length);
		for (uint256 i = 0; i < length; i++) {
			_blacklist[users[i]] = blackListed[i];
		}
	}

	function _updateWhitelist(
		address user,
		uint16 tokensAmount,
		uint256 nonce,
		bytes memory signature
	) internal {
		require(mintWhitelistStarted, "Whitelist: NOT_STARTED");
		require(user == msg.sender, "Whitelist: WRONG_USER");

		bytes32 dataHash = keccak256(
			abi.encode("DegenLabsWhiteList", address(this), block.chainid, nonce, user, tokensAmount)
		);

		require(!BitMaps.get(_usedSignatures, nonce), "Whitelist: SIG_ALREADY_USED");

		bytes4 result = ISignatureChecker(_signatureChecker).isValidSignature(dataHash, signature);
		require(result == 0x1626ba7e, "Whitelist: INVALID_SIGNATURE");

		BitMaps.set(_usedSignatures, nonce);
	}

	function _removeFromWhitelist(uint256 nonce) internal {
		// we invalidate signature with that nonce
		BitMaps.set(_usedSignatures, nonce);
	}

	function _startWhitelistMint() internal {
		mintWhitelistStarted = true;
	}
}