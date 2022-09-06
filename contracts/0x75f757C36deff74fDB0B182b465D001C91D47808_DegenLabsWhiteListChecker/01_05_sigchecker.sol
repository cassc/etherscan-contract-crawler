// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DegenLabsWhiteListChecker is Ownable {
	address public signer;

	constructor(address _signer) {
		signer = _signer;
	}

	function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4) {
		(address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(ECDSA.toEthSignedMessageHash(hash), signature);
		if (error == ECDSA.RecoverError.NoError && recovered == signer) {
			return 0x1626ba7e;
		}
		return 0xffffffff;
	}

	function updateSigner(address _signer) external onlyOwner {
		signer = _signer;
	}
}