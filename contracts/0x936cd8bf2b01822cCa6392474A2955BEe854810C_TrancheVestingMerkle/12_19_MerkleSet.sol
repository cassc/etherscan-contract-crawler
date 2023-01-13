// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IMerkleSet } from "../interfaces/IMerkleSet.sol";

contract MerkleSet is IMerkleSet {
	bytes32 private merkleRoot;

	constructor(bytes32 _merkleRoot) {
		_setMerkleRoot(_merkleRoot);
	}

	modifier validMerkleProof(bytes32 leaf, bytes32[] calldata merkleProof) {
		_verifyMembership(leaf, merkleProof);

		_;
	}

	function _testMembership(bytes32 leaf, bytes32[] calldata merkleProof)
		internal
		view
		returns (bool)
	{
		return MerkleProof.verify(merkleProof, merkleRoot, leaf);
	}

	function getMerkleRoot() public view returns (bytes32) {
		return merkleRoot;
	}

	function _verifyMembership(bytes32 leaf, bytes32[] calldata merkleProof) internal view {
		require(_testMembership(leaf, merkleProof), "invalid proof");
	}

	function _setMerkleRoot(bytes32 _merkleRoot) internal {
		merkleRoot = _merkleRoot;
		emit SetMerkleRoot(merkleRoot);
	}
}