// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract WhitelistCustom {
	address public signer;
	bool public prelaunchStarted = false;

	mapping(address => bool) private _blacklist;
	BitMaps.BitMap private _usedSignatures;

	constructor(address signatureChecker) {
		signer = signatureChecker;
	}

	function _isValidSignature(bytes32 hash, bytes memory signature) internal view returns (bool) {
		(address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(ECDSA.toEthSignedMessageHash(hash), signature);
		if (error == ECDSA.RecoverError.NoError && recovered == signer) {
			return true;
		}
		return false;
	}

	function _checkWhitelist(
		address user,
		uint256 maxTokensAmount,
		uint256 nonce,
		bytes memory signature
	) internal view {
		require(prelaunchStarted, "Whitelist: NOT_STARTED");
		require(user == msg.sender, "Whitelist: WRONG_USER");
		require(!BitMaps.get(_usedSignatures, nonce), "Whitelist: SIG_REMOVED");

		bytes32 dataHash = keccak256(
			abi.encode("CustomWhiteList", address(this), block.chainid, nonce, user, maxTokensAmount)
		);

		require(_isValidSignature(dataHash, signature), "Whitelist: INVALID_SIGNATURE");
	}

	function _removeFromWhitelist(uint256 nonce) internal {
		BitMaps.set(_usedSignatures, nonce);
	}

	function _startPrelaunchMint() internal {
		prelaunchStarted = true;
	}

	function _pausePrelaunchMint() internal {
		prelaunchStarted = false;
	}

	function _changeSigner(address _signer) internal {
		signer = _signer;
	}
}