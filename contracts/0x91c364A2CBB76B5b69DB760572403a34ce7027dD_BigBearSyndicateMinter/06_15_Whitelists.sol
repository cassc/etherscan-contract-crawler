// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

library Whitelists {
	// Inspired by https://medium.com/@ItsCuzzo/using-merkle-trees-for-nft-whitelists-523b58ada3f9
	struct MerkleProofWhitelist {
		bytes32 _rootHash;
	}

	function getRootHash(MerkleProofWhitelist storage whitelist)
		internal
		view
		returns (bytes32)
	{
		return whitelist._rootHash;
	}

	function setRootHash(
		MerkleProofWhitelist storage whitelist,
		bytes32 _rootHash
	) internal {
		whitelist._rootHash = _rootHash;
	}

	function isWhitelisted(
		MerkleProofWhitelist storage whitelist,
		address user,
		bytes32[] calldata proof
	) internal view returns (bool) {
		bytes32 leaf = keccak256(abi.encodePacked(user));

		return MerkleProof.verify(proof, whitelist._rootHash, leaf);
	}
}