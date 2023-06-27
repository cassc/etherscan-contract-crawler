// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title MultiRewards
 * @dev It uses safe guard addresses (e.g., address(0), address(1)) to add a protection layer against operational errors when the operator sets up the merkle roots for each of the existing trees.
 */
contract LinearVestingMerkle is Pausable, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    struct vestInfo {
        uint256 totalReward;
        uint256 startEpoch;
        uint256 totalMonths;
    }

    struct TreeParameter {
        address safeGuard; // address of the safe guard (e.g., address(0))
        bytes32 merkleRoot; // current merkle root
    }

    // Standard safe guard
    vestInfo public SAFE_GUARD_AMOUNT = vestInfo(0, 0, 0);

    // Keeps track of number of trees existing in parallel
    uint8 public numberTrees;

    // Last paused timestamp
    uint256 public lastPausedTimestamp;

    // Keeps track of current parameters of a tree
    mapping(uint8 => TreeParameter) public treeParameters;

    // Check whether safe guard address was used
    mapping(address => bool) public safeGuardUsed;

    // Checks whether a merkle root was used
    mapping(bytes32 => bool) public merkleRootUsed;

    event Claim(
        address user,
        uint256 rewardRound,
        uint256 totalAmount,
        uint8[] treeIds,
        uint256[] amounts
    );
    event NewTree(uint8 treeId);
    event UpdateRoot(uint8 treeId, bytes32 root);

    constructor() {}

    /**
     * @notice Update merkle root
     * @param treeIds array of treeIds
     * @param merkleRoots array of merkle roots (for each treeId)
     * @param merkleProofsSafeGuards array of merkle proof for the safe guard addresses
     */
    function updateRoot(
        uint8[] calldata treeIds,
        bytes32[] calldata merkleRoots,
        bytes32[][] calldata merkleProofsSafeGuards
    ) external onlyOwner {
        require(
            treeIds.length > 0 &&
                treeIds.length == merkleRoots.length &&
                treeIds.length == merkleProofsSafeGuards.length,
            "Owner: Wrong lengths"
        );

        vestInfo memory tempGuard = SAFE_GUARD_AMOUNT;

        for (uint256 i = 0; i < merkleRoots.length; i++) {
            require(treeIds[i] < numberTrees, "Owner: Tree nonexistent");
            require(
                !merkleRootUsed[merkleRoots[i]],
                "Owner: Merkle root already used"
            );
            treeParameters[treeIds[i]].merkleRoot = merkleRoots[i];
            merkleRootUsed[merkleRoots[i]] = true;
            bool canSafeGuardClaim = _canClaim(
                treeParameters[treeIds[i]].safeGuard,
                treeIds[i],
                tempGuard,
                merkleProofsSafeGuards[i]
            );
            require(canSafeGuardClaim, "Owner: Wrong safe guard proofs");
            emit UpdateRoot(treeIds[i], merkleRoots[i]);
        }
    }

    /**
     * @notice Add a new tree
     * @param safeGuard address of a safe guard user (e.g., address(0), address(1))
     * @dev Only for owner.
     */
    function addNewTree(address safeGuard) external onlyOwner {
        require(
            !safeGuardUsed[safeGuard],
            "BidshopHammerRewards: Safe guard already used"
        );
        safeGuardUsed[safeGuard] = true;
        treeParameters[numberTrees].safeGuard = safeGuard;

        // Emit event and increment number trees
        emit NewTree(numberTrees++);
    }

    /**
     * @notice Pause distribution
     * @dev Only for owner.
     */
    function pauseDistribution() external onlyOwner whenNotPaused {
        lastPausedTimestamp = block.timestamp;
        _pause();
    }

    /**
     * @notice Unpause distribution
     * @dev Only for owner.
     */
    function unpauseDistribution() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Check whether it is possible to claim and how much based on previous distribution
     * @param user address of the user
     * @param treeId id of the merkle tree
     * @param vestingData struct to create the node
     * @param merkleProof array with the merkle proof
     */
    function _canClaim(
        address user,
        uint8 treeId,
        vestInfo memory vestingData,
        bytes32[] calldata merkleProof
    ) internal view returns (bool) {
        // Compute the node and verify the merkle proof
        bytes32 node = keccak256(
            abi.encodePacked(
                user,
                vestingData.totalReward,
                vestingData.startEpoch,
                vestingData.totalMonths
            )
        );
        bool canUserClaim = MerkleProof.verify(
            merkleProof,
            treeParameters[treeId].merkleRoot,
            node
        );

        if (!canUserClaim) {
            return (false);
        } else {
            return (true);
        }
    }
}