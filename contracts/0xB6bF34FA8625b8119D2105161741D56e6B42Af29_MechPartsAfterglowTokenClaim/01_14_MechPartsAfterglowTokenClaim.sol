// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "./MechPartsAfterglowToken.sol";

contract MechPartsAfterglowTokenClaim is ReentrancyGuard, Ownable, IERC1155Receiver
{
	// TPL Mecha Parts token contract
	MechPartsAfterglowToken public mechPartsAfterglowToken;

	// Claim Allowlist
	bytes32 public claimMerkleRoot;
	mapping(address => mapping(uint => bool)) public claimAllowlistClaimed;

	constructor(
		address payable _MechPartsAfterglowTokenAddress,
		bytes32 _claimMerkleRoot
	) {
		// Set the token address
		mechPartsAfterglowToken = MechPartsAfterglowToken(_MechPartsAfterglowTokenAddress);

		// Set the merkleRoot
		setClaimMerkleRoot(_claimMerkleRoot);
	}

	function claim(
		address _recipient,
		bytes32[][] calldata _proofs,
		uint256[] calldata _tokenIds,
		uint256[] calldata _tokenCounts
	)
		external
		nonReentrant
	{
		// We have to go through the airdrop function since there is no other way to mint
		// So the Mech Parts Token contract will airdrop (mint) to this contract,
		// and then this contract will transfer out the tokens to the claimer
		require(_proofs.length > 0, "Missing proof");
		require(_tokenIds.length > 0, "Must provide tokens for claim");
		require(_tokenIds.length == _tokenCounts.length, "Invalid array lengths for tokenIds and tokenCounts");
		require(_tokenIds.length == _proofs.length, "Invalid array lengths for proofs and tokenIds");

		for (uint256 idx; idx < _tokenIds.length; idx++) {
			bytes32[] calldata _proof = _proofs[idx];
			uint256 _tokenId = _tokenIds[idx];
			uint256 _tokenCount = _tokenCounts[idx];

			// Check that purchase is legal per allowlist
			require(reviewClaimProof(_recipient, _proof, _tokenId, _tokenCount), "Proof does not match data");
			require(claimAllowlistClaimed[_recipient][_tokenId] == false, "Can not exceed permitted amount");

			// Update allowlist claimed
			// We require that each person claims the exact number of a tokenID provided to them
			claimAllowlistClaimed[_recipient][_tokenId] = true;
		}

		// If we make it here, then send tokens
		mechPartsAfterglowToken.safeBatchTransferFrom(
			address(this),
			_recipient,
			_tokenIds,
			_tokenCounts,
			""
		);
	}

	/**
	 * Allowlist Merkle Data
	 * Credit for Merkle setup code: Cobble
	 **/
	function getLeaf(address addr, uint256 tokenId, uint256 tokenCount) public pure returns(bytes32) {
		return keccak256(abi.encodePacked(addr, tokenId, tokenCount));
	}

	function reviewClaimProof(
		address _sender,
		bytes32[] calldata _proof,
		uint256 _tokenId,
		uint256 _tokenCount
	) public view returns (bool) {
		return MerkleProof.verify(_proof, claimMerkleRoot, getLeaf(_sender, _tokenId, _tokenCount));
	}



	/**
	 * Only Owner functions:
	 * - setting the claim merkle root
	 * - burning the remaining supply
	 **/


	function setClaimMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
		claimMerkleRoot = _merkleRoot;
	}

	function burnBatch(
		uint256[] calldata _tokenIds,
		uint256[] calldata _tokenCounts
	) public onlyOwner {
		mechPartsAfterglowToken.burnBatch(
			address(this),
			_tokenIds,
			_tokenCounts
		);
	}


	/**
	 * IERC1155Receiver implementation
	 **/

	function supportsInterface(
		bytes4 interfaceId
	) external pure returns (bool) {
		return interfaceId == type(IERC1155Receiver).interfaceId;
	}

	function onERC1155Received(
		address,
		address,
		uint256,
		uint256,
		bytes calldata
	) external pure returns (bytes4) {
		return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
	}

	function onERC1155BatchReceived(
		address,
		address,
		uint256[] calldata,
		uint256[] calldata,
		bytes calldata
	) external pure returns (bytes4) {
		return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
	}
}