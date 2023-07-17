// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "MerkleProof.sol";

abstract contract Merkle {
	using MerkleProof for bytes32[];

	bytes32 public merkleRoot;
	mapping(uint256 => uint256) public claimedBitMap;

	event Claimed(uint256 index, address account, uint256 amount);

	function isClaimed(uint256 _index) public view returns(bool) {
		uint256 wordIndex = _index / 256;
		uint256 bitIndex = _index % 256;
		uint256 word = claimedBitMap[wordIndex];
		uint256 bitMask = 1 << bitIndex;
		return word & bitMask == bitMask;
	}

	function _verify(uint256 _index, address _account, uint256 _amount, uint256 _prio, bytes32[] memory _proof) internal view{
		bytes32 node = keccak256(abi.encodePacked(_account, _amount, _index, _prio));
		require(_proof.verify(merkleRoot, node), "Wrong proof");
	}

	function _setClaimed(uint256 _index) internal {
		uint256 wordIndex = _index / 256;
		uint256 bitIndex = _index % 256;
		claimedBitMap[wordIndex] |= 1 << bitIndex;
	}

	function _claim(uint256 _index, address _account, uint256 _amount, uint256 _prio, bytes32[] memory _proof) internal {
		require(!isClaimed(_index), "Claimed already");
		bytes32 node = keccak256(abi.encodePacked(_account, _amount, _index, _prio));
		require(_proof.verify(merkleRoot, node), "Wrong proof");
		
		_setClaimed(_index);
		emit Claimed(_index, _account, _amount);
	}
}