// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {ICyberbrokersAccolades} from "./ICyberbrokersAccolades.sol";

/// @title CyberbrokersAccoladesClaim
/// @author CyberBrokers
/// @author dev by @dievardump
/// @notice Minter
contract CyberbrokersAccoladesClaim is Ownable {
	error NotAuthorized();
	error InvalidLength();
	error InvalidSignature();
	error AlreadyClaimed();

	/// @notice nft contract
	address public immutable ACCOLADES;

	/// @notice address allowed to sign the proof of claim
	address public signer;

	/// @notice contract name
	/// @dev makes beautiful smartbags
	string public name = "CyberBrokers Accolades Claim";

	mapping(bytes32 => bool) public claimed;

	constructor(address newAccolades, address newSigner) {
		ACCOLADES = newAccolades;
		signer = newSigner;
	}

	// =============================================================
	//                       	   Interactions
	// =============================================================

	/// @notice Allows to claim
	/// @param to recipient of the nft
	/// @param tokenId the token id to mint
	/// @param amount the amount to mint
	/// @param proof proof of signature
	function claim(
		address to,
		uint256 tokenId,
		uint256 amount,
		bytes calldata proof
	) external {
		bytes32 message = keccak256(abi.encode(to, tokenId, amount, address(this)));
		_checkSignature(message, proof);

		if (claimed[message]) {
			revert AlreadyClaimed();
		}

		claimed[message] = true;

		address[] memory temp = new address[](1);
		temp[0] = to;
		ICyberbrokersAccolades(ACCOLADES).mint(temp, tokenId, amount);
	}

	// =============================================================
	//                       	   Gated Owner
	// =============================================================

	/// @notice allows owner to set the signer address to allow buys
	/// @param newSigner the new signer address
	function setSigner(address newSigner) external onlyOwner {
		signer = newSigner;
	}

	// =============================================================
	//                       	   Internals
	// =============================================================

	/// @dev checks that proof is the result of the signature of `message` by signer
	function _checkSignature(bytes32 message, bytes memory proof) internal view {
		// verifies the signature
		if (signer != ECDSA.recover(ECDSA.toEthSignedMessageHash(message), proof)) {
			revert InvalidSignature();
		}
	}
}