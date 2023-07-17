// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

interface IVotingEscrow {
    function stake(uint256 amount, uint256 end, address _account) external;
}

contract LockupDistributor {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    bytes32 public immutable merkleRoot;
    IVotingEscrow public immutable stakingContract;
    uint256 public immutable startTimestamp;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    //@notice This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 indexed index, address indexed account, uint256 amount, uint256 stakeDuration);

    constructor(IERC20 _token, bytes32 _merkleRoot, address _stakingContract, uint256 _startTimestamp) {
        token = _token;
        merkleRoot = _merkleRoot;
        stakingContract = IVotingEscrow(_stakingContract);
        startTimestamp = _startTimestamp;
    }

    /**
     * @dev Execute a claim using a merkle proof with optional stake in the staking contract.
     * @param _index Index in the tree
     * @param _amount Amount eligiblle to claim
     * @param _merkleProof The proof
     * @param _stakeDuration Duration of the stake to create
     */
    function claim(uint256 _index, uint256 _amount, bytes32[] calldata _merkleProof, uint256 _stakeDuration) external {
        require(!isClaimed(_index), "MerkleDistributor: Drop already claimed.");
        require(block.timestamp >= startTimestamp, "MerkleDistributor: Claim period not open yet.");

        // Verify the merkle proof.
        require(isProofValid(_index, _amount, msg.sender, _merkleProof), "MerkleDistributor: Invalid proof.");

        // Mark it claimed and send the token.
        setClaimed(_index);
        if (_stakeDuration > 0) {
            token.approve(address(stakingContract), _amount);
            stakingContract.stake(_amount, _stakeDuration, msg.sender);
        } else {
            token.safeTransfer(msg.sender, _amount);
        }

        emit Claimed(_index, msg.sender, _amount, _stakeDuration);
    }

    /**
     * @dev
     * @param _index Index in the tree
     */
    function isClaimed(uint256 _index) public view returns (bool) {
        uint256 claimedWordIndex = _index / 256;
        uint256 claimedBitIndex = _index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /**
     * @dev
     * @param _index Index in the tree
     */
    function setClaimed(uint256 _index) internal {
        uint256 claimedWordIndex = _index / 256;
        uint256 claimedBitIndex = _index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function isProofValid(
        uint256 _index,
        uint256 _amount,
        address _account,
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        // Verify the Merkle proof.
        bytes32 node = keccak256(bytes.concat(keccak256(abi.encode(_index, _account, _amount))));
        return MerkleProof.verify(_merkleProof, merkleRoot, node);
    }
}