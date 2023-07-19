// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LowLevelERC20Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC20Transfer.sol";
import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {Pausable} from "@looksrare/contracts-libs/contracts/Pausable.sol";
import {ReentrancyGuard} from "@looksrare/contracts-libs/contracts/ReentrancyGuard.sol";

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title SeasonRewardsDistributor
 * @notice It distributes LOOKS tokens with rolling Merkle airdrops.
 */
contract SeasonRewardsDistributor is Pausable, ReentrancyGuard, OwnableTwoSteps, LowLevelERC20Transfer {
    uint256 public constant BUFFER_ADMIN_WITHDRAW = 3 days;

    address public immutable looksRareToken;

    // Current reward round (users can only claim pending rewards for the current round)
    uint256 public currentRewardRound;

    // Last paused timestamp
    uint256 public lastPausedTimestamp;

    // Max amount per user in current tree
    uint256 public maximumAmountPerUserInCurrentTree;

    // Total amount claimed by user (in LOOKS)
    mapping(address => uint256) public amountClaimedByUser;

    // Merkle root for a reward round
    mapping(uint256 => bytes32) public merkleRootOfRewardRound;

    // Checks whether a merkle root was used
    mapping(bytes32 => bool) public merkleRootUsed;

    // Keeps track on whether user has claimed at a given reward round
    mapping(uint256 => mapping(address => bool)) public hasUserClaimedForRewardRound;

    event RewardsClaim(address indexed user, uint256 indexed rewardRound, uint256 amount);
    event UpdateSeasonRewards(uint256 indexed rewardRound);
    event TokenWithdrawnOwner(uint256 amount);

    error AlreadyClaimed();
    error AmountHigherThanMax();
    error InvalidProof();
    error MerkleRootAlreadyUsed();
    error TooEarlyToWithdraw();

    /**
     * @notice Constructor
     * @param _looksRareToken address of the LooksRare token
     * @param _owner address of the owner
     */
    constructor(address _looksRareToken, address _owner) OwnableTwoSteps(_owner) {
        looksRareToken = _looksRareToken;
        merkleRootUsed[bytes32(0)] = true;
    }

    /**
     * @notice Claim pending rewards
     * @param amount amount to claim
     * @param merkleProof array containing the merkle proof
     */
    function claim(uint256 amount, bytes32[] calldata merkleProof) external whenNotPaused nonReentrant {
        // Verify the reward round is not claimed already
        if (hasUserClaimedForRewardRound[currentRewardRound][msg.sender]) {
            revert AlreadyClaimed();
        }

        (bool claimStatus, uint256 adjustedAmount) = _canClaim(msg.sender, amount, merkleProof);

        if (!claimStatus) {
            revert InvalidProof();
        }
        if (amount > maximumAmountPerUserInCurrentTree) {
            revert AmountHigherThanMax();
        }

        // Set mapping for user and round as true
        hasUserClaimedForRewardRound[currentRewardRound][msg.sender] = true;

        // Adjust amount claimed
        amountClaimedByUser[msg.sender] += adjustedAmount;

        // Transfer adjusted amount
        _executeERC20DirectTransfer(looksRareToken, msg.sender, adjustedAmount);

        emit RewardsClaim(msg.sender, currentRewardRound, adjustedAmount);
    }

    /**
     * @notice Update season rewards with a new merkle root
     * @dev It automatically increments the currentRewardRound
     * @param merkleRoot root of the computed merkle tree
     */
    function updateSeasonRewards(bytes32 merkleRoot, uint256 newMaximumAmountPerUser) external onlyOwner {
        if (merkleRootUsed[merkleRoot]) {
            revert MerkleRootAlreadyUsed();
        }

        currentRewardRound++;
        merkleRootOfRewardRound[currentRewardRound] = merkleRoot;
        merkleRootUsed[merkleRoot] = true;
        maximumAmountPerUserInCurrentTree = newMaximumAmountPerUser;

        emit UpdateSeasonRewards(currentRewardRound);
    }

    /**
     * @notice Pause distribution
     */
    function pauseDistribution() external onlyOwner whenNotPaused {
        lastPausedTimestamp = block.timestamp;
        _pause();
    }

    /**
     * @notice Unpause distribution
     */
    function unpauseDistribution() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Transfer LOOKS tokens back to owner
     * @dev It is for emergency purposes
     * @param amount amount to withdraw
     */
    function withdrawTokenRewards(uint256 amount) external onlyOwner whenPaused {
        if (block.timestamp <= (lastPausedTimestamp + BUFFER_ADMIN_WITHDRAW)) {
            revert TooEarlyToWithdraw();
        }
        _executeERC20DirectTransfer(looksRareToken, msg.sender, amount);

        emit TokenWithdrawnOwner(amount);
    }

    /**
     * @notice Check whether it is possible to claim and how much based on previous distribution
     * @param user address of the user
     * @param amount amount to claim
     * @param merkleProof array with the merkle proof
     */
    function canClaim(
        address user,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external view returns (bool, uint256) {
        return _canClaim(user, amount, merkleProof);
    }

    /**
     * @notice Check whether it is possible to claim and how much based on previous distribution
     * @param user address of the user
     * @param amount amount to claim
     * @param merkleProof array with the merkle proof
     */
    function _canClaim(
        address user,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) internal view returns (bool, uint256) {
        // Compute the node and verify the merkle proof
        bytes32 node = keccak256(bytes.concat(keccak256(abi.encodePacked(user, amount))));

        bool canUserClaim = MerkleProof.verify(merkleProof, merkleRootOfRewardRound[currentRewardRound], node);

        if ((!canUserClaim) || (hasUserClaimedForRewardRound[currentRewardRound][user])) {
            return (false, 0);
        } else {
            return (true, amount - amountClaimedByUser[user]);
        }
    }
}