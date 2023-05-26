// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {MerkleProofLib} from "solmate/utils/MerkleProofLib.sol";

contract GasRewardsDistributor is Ownable {
    receive() external payable {}

    mapping(bytes32 root => uint16 round) public rootsToRounds;
    mapping(uint16 round => uint64 endTime) public roundEndTimes;
    mapping(bytes32 packedRecipientAndRound => bool used) public claimedRewards;

    event Claimed(address recipient, uint16 round, uint256 amount);

    error RoundNotOpen();
    error AlreadyClaimed();
    error InvalidProof();
    error TransferFailed();
    error NotEnoughEtherInContract();
    error InvalidRoundId();

    constructor() {
        if (msg.sender != tx.origin) {
            transferOwnership(tx.origin);
        }
    }

    function _packRecipientAndRound(address _address, uint16 _round) internal pure returns (bytes32) {
        return (bytes32(uint256(uint160(_address))) << 96) | bytes32(uint256(_round));
    }

    function claim(bytes32 merkleRoot, uint256 amount, bytes32[] calldata proof) public payable {
        if (amount > address(this).balance) revert NotEnoughEtherInContract();

        // Look up the round for the given merkle root, verify that it's open
        uint16 round = rootsToRounds[merkleRoot];
        if (round == 0) revert InvalidRoundId();
        if (block.timestamp > roundEndTimes[round]) revert RoundNotOpen();

        // Verify that the user hasn't already claimed for this round
        bytes32 packedRecipientAndRound = _packRecipientAndRound(msg.sender, round);
        if (claimedRewards[packedRecipientAndRound]) revert AlreadyClaimed();

        // Validate merkle proof
        if (!MerkleProofLib.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender, amount, round)))) {
            revert InvalidProof();
        }

        // Perform all state changes before sending Ether
        claimedRewards[packedRecipientAndRound] = true;
        emit Claimed(msg.sender, round, amount);

        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    function setRoundEndTime(uint16 round, uint32 endTime) public onlyOwner {
        // Round can't be 0 because that's how we check for round existence
        if (round == 0) revert InvalidRoundId();
        roundEndTimes[round] = endTime;
    }

    function setRoundMerkleRoot(uint16 round, bytes32 merkleRoot) public onlyOwner {
        // We don't check if the round is 0, because that's how we delete a merkle root
        rootsToRounds[merkleRoot] = round;
    }

    function withdraw(uint256 amount) public onlyOwner {
        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();
    }
}