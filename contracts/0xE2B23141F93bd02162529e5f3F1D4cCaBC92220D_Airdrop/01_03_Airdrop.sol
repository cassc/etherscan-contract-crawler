pragma solidity 0.8.2;

import "MerkleProof.sol";
import "IERC20.sol";

contract Airdrop {
	using MerkleProof for bytes32[];

	IERC20 public token;

	bytes32 public merkleRoot;
	mapping(uint256 => uint256) public claimedBitMap;

	event Claimed(uint256 index, address account, uint256 amount);

	constructor(address _token, bytes32 _root) public {
		token = IERC20(_token);
		merkleRoot = _root;
	}

	function isClaimed(uint256 _index) public view returns(bool) {
		uint256 wordIndex = _index / 256;
		uint256 bitIndex = _index % 256;
		uint256 word = claimedBitMap[wordIndex];
		uint256 bitMask = 1 << bitIndex;
		return word & bitMask == bitMask;
	}

	function _setClaimed(uint256 _index) internal {
		uint256 wordIndex = _index / 256;
		uint256 bitIndex = _index % 256;
		claimedBitMap[wordIndex] |= 1 << bitIndex;
	}

	function claim(uint256 _index, address _account, uint256 _amount, bytes32[] memory _proof) external {
		require(!isClaimed(_index), "Airdrop: Claimed already");
		bytes32 node = keccak256(abi.encodePacked(_index, _account, _amount));
		require(_proof.verify(merkleRoot, node), "Airdrop: Wrong proof");
		
		_setClaimed(_index);
		require(token.transfer(_account, _amount), "Airdrop: Token transfer failed");
		emit Claimed(_index, _account, _amount);
	}
}