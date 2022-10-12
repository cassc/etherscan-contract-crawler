// contracts/AirdropTokenDistributor.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "IERC20.sol";
import "MerkleProof.sol";
import "IAirdropTokenDistributor.sol";

contract AirdropTokenDistributor is IAirdropTokenDistributor {
    address public immutable override token;
    bytes32 public immutable override merkleRoot;
    address public owner;

    uint256 public startTime;
    uint256 public endTime;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(
        address token_,
        bytes32 merkleRoot_,
        uint256 _startTime,
        uint256 _endTime
    ) public {
        token = token_;
        merkleRoot = merkleRoot_;
        startTime = _startTime;
        endTime = _endTime;
        owner = msg.sender;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external override {
        require(block.timestamp >= startTime, "NOT START");
        require(block.timestamp <= endTime, "CLAIM EXPIRED");
        require(!isClaimed(index), "AirdropTokenDistributor: Drop already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "AirdropTokenDistributor: Invalid proof.");

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), "AirdropTokenDistributor: Transfer failed.");

        emit Claimed(index, account, amount);
    }

    function withdrawAll() external {
        require(msg.sender == owner, "not owner");
        require(block.timestamp > endTime, "not end");
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner, amount);
    }
}