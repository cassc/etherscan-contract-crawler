// SPDX-License-Identifier: UNLICENSED
// Based on code from MACI (https://github.com/appliedzkp/maci/blob/7f36a915244a6e8f98bacfe255f8bd44193e7919/contracts/sol/IncrementalMerkleTree.sol)
pragma solidity ^0.8.0;
pragma abicoder v2;

// OpenZeppelin v4
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { SNARK_SCALAR_FIELD } from "./Globals.sol";

import { PoseidonT3 } from "./Poseidon.sol";

/**
 * @title Commitments
 * @author Railgun Contributors
 * @notice Batch Incremental Merkle Tree for commitments
 * @dev Publically accessible functions to be put in RailgunLogic
 * Relevent external contract calls should be in those functions, not here
 */
contract Commitments is Initializable {
  // NOTE: The order of instantiation MUST stay the same across upgrades
  // add new variables to the bottom of the list and decrement the __gap
  // variable at the end of this file
  // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading

  // Commitment nullifiers (treenumber -> nullifier -> seen)
  mapping(uint256 => mapping(uint256 => bool)) public nullifiers;

  // The tree depth
  uint256 internal constant TREE_DEPTH = 16;

  // Tree zero value
  uint256 public constant ZERO_VALUE = uint256(keccak256("Railgun")) % SNARK_SCALAR_FIELD;

  // Next leaf index (number of inserted leaves in the current tree)
  uint256 internal nextLeafIndex;

  // The Merkle root
  uint256 public merkleRoot;

  // Store new tree root to quickly migrate to a new tree
  uint256 private newTreeRoot;

  // Tree number
  uint256 public treeNumber;

  // The Merkle path to the leftmost leaf upon initialisation. It *should
  // not* be modified after it has been set by the initialize function.
  // Caching these values is essential to efficient appends.
  uint256[TREE_DEPTH] public zeros;

  // Right-most elements at each level
  // Used for efficient upodates of the merkle tree
  uint256[TREE_DEPTH] private filledSubTrees;

  // Whether the contract has already seen a particular Merkle tree root
  // treeNumber -> root -> seen
  mapping(uint256 => mapping(uint256 => bool)) public rootHistory;


  /**
   * @notice Calculates initial values for Merkle Tree
   * @dev OpenZeppelin initializer ensures this can only be called once
   */
  function initializeCommitments() internal onlyInitializing {
    /*
    To initialise the Merkle tree, we need to calculate the Merkle root
    assuming that each leaf is the zero value.
    H(H(a,b), H(c,d))
      /          \
    H(a,b)     H(c,d)
    /   \       /  \
    a    b     c    d
    `zeros` and `filledSubTrees` will come in handy later when we do
    inserts or updates. e.g when we insert a value in index 1, we will
    need to look up values from those arrays to recalculate the Merkle
    root.
    */

    // Calculate zero values
    zeros[0] = ZERO_VALUE;

    // Store the current zero value for the level we just calculated it for
    uint256 currentZero = ZERO_VALUE;

    // Loop through each level
    for (uint256 i = 0; i < TREE_DEPTH; i++) {
      // Push it to zeros array
      zeros[i] = currentZero;

      // Calculate the zero value for this level
      currentZero = hashLeftRight(currentZero, currentZero);
    }

    // Set merkle root and store root to quickly retrieve later
    newTreeRoot = merkleRoot = currentZero;
    rootHistory[treeNumber][currentZero] = true;
  }

  /**
   * @notice Hash 2 uint256 values
   * @param _left - Left side of hash
   * @param _right - Right side of hash
   * @return hash result
   */
  function hashLeftRight(uint256 _left, uint256 _right) public pure returns (uint256) {
    return PoseidonT3.poseidon([
      _left,
      _right
    ]);
  }

  /**
   * @notice Calculates initial values for Merkle Tree
   * @dev Insert leaves into the current merkle tree
   * Note: this function INTENTIONALLY causes side effects to save on gas.
   * _leafHashes and _count should never be reused.
   * @param _leafHashes - array of leaf hashes to be added to the merkle tree
   */
  function insertLeaves(uint256[] memory _leafHashes) internal {
    /*
    Loop through leafHashes at each level, if the leaf is on the left (index is even)
    then hash with zeros value and update subtree on this level, if the leaf is on the
    right (index is odd) then hash with subtree value. After calculating each hash
    push to relevent spot on leafHashes array. For gas efficiency we reuse the same
    array and use the count variable to loop to the right index each time.

    Example of updating a tree of depth 4 with elements 13, 14, and 15
    [1,7,15]    {1}                    1
                                       |
    [3,7,15]    {1}          2-------------------3
                             |                   |
    [6,7,15]    {2}     4---------5         6---------7
                       / \       / \       / \       / \
    [13,14,15]  {3}  08   09   10   11   12   13   14   15
    [] = leafHashes array
    {} = count variable
    */

    // Get initial count
    uint256 count = _leafHashes.length;

    // Create new tree if current one can't contain new leaves
    // We insert all new commitment into a new tree to ensure they can be spent in the same transaction
    if ((nextLeafIndex + count) >= (2 ** TREE_DEPTH)) { newTree(); }

    // Current index is the index at each level to insert the hash
    uint256 levelInsertionIndex = nextLeafIndex;

    // Update nextLeafIndex
    nextLeafIndex += count;

    // Variables for starting point at next tree level
    uint256 nextLevelHashIndex;
    uint256 nextLevelStartIndex;

    // Loop through each level of the merkle tree and update
    for (uint256 level = 0; level < TREE_DEPTH; level++) {
      // Calculate the index to start at for the next level
      // >> is equivilent to / 2 rounded down
      nextLevelStartIndex = levelInsertionIndex >> 1;

      uint256 insertionElement = 0;

      // If we're on the right, hash and increment to get on the left
      if (levelInsertionIndex % 2 == 1) {
        // Calculate index to insert hash into leafHashes[]
        // >> is equivilent to / 2 rounded down
        nextLevelHashIndex = (levelInsertionIndex >> 1) - nextLevelStartIndex;

        // Calculate the hash for the next level
        _leafHashes[nextLevelHashIndex] = hashLeftRight(filledSubTrees[level], _leafHashes[insertionElement]);

        // Increment
        insertionElement += 1;
        levelInsertionIndex += 1;
      }

      // We'll always be on the left side now
      for (insertionElement; insertionElement < count; insertionElement += 2) {
        uint256 right;

        // Calculate right value
        if (insertionElement < count - 1) {
          right = _leafHashes[insertionElement + 1];
        } else {
          right = zeros[level];
        }

        // If we've created a new subtree at this level, update
        if (insertionElement == count - 1 || insertionElement == count - 2) {
          filledSubTrees[level] = _leafHashes[insertionElement];
        }

        // Calculate index to insert hash into leafHashes[]
        // >> is equivilent to / 2 rounded down
        nextLevelHashIndex = (levelInsertionIndex >> 1) - nextLevelStartIndex;

        // Calculate the hash for the next level
        _leafHashes[nextLevelHashIndex] = hashLeftRight(_leafHashes[insertionElement], right);

        // Increment level insertion index
        levelInsertionIndex += 2;
      }

      // Get starting levelInsertionIndex value for next level
      levelInsertionIndex = nextLevelStartIndex;

      // Get count of elements for next level
      count = nextLevelHashIndex + 1;
    }
 
    // Update the Merkle tree root
    merkleRoot = _leafHashes[0];
    rootHistory[treeNumber][merkleRoot] = true;
  }

  /**
   * @notice Creates new merkle tree
   */
  function newTree() internal {
    // Restore merkleRoot to newTreeRoot
    merkleRoot = newTreeRoot;

    // Existing values in filledSubtrees will never be used so overwriting them is unnecessary

    // Reset next leaf index to 0
    nextLeafIndex = 0;

    // Increment tree number
    treeNumber++;
  }

  uint256[10] private __gap;
}