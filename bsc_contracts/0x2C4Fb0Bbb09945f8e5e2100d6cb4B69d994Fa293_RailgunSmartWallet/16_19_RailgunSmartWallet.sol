// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

import { TokenBlocklist } from "./TokenBlocklist.sol";
import { Commitments } from "./Commitments.sol";
import { RailgunLogic } from "./RailgunLogic.sol";
import { SNARK_SCALAR_FIELD, CommitmentPreimage, CommitmentCiphertext, ShieldCiphertext, TokenType, UnshieldType, Transaction, ShieldRequest } from "./Globals.sol";

/**
 * @title Railgun Smart Wallet
 * @author Railgun Contributors
 * @notice Railgun private smart wallet
 * @dev Entry point for processing private meta-transactions
 */
contract RailgunSmartWallet is RailgunLogic {
  /**
   * @notice Shields requested amount and token, creates a commitment hash from supplied values and adds to tree
   * @param _shieldRequests - list of commitments to shield
   */
  function shield(ShieldRequest[] calldata _shieldRequests) external payable {
    // Insertion and event arrays
    bytes32[] memory insertionLeaves = new bytes32[](_shieldRequests.length);
    CommitmentPreimage[] memory commitments = new CommitmentPreimage[](_shieldRequests.length);
    ShieldCiphertext[] memory shieldCiphertext = new ShieldCiphertext[](_shieldRequests.length);

    // Loop through each note and process
    for (uint256 notesIter = 0; notesIter < _shieldRequests.length; notesIter += 1) {
      // Check note is valid
      (bool valid, string memory reason) = RailgunLogic.validateCommitmentPreimage(
        _shieldRequests[notesIter].preimage
      );
      require(valid, string.concat("RailgunSmartWallet: ", reason));

      // Process shield request and store adjusted note
      commitments[notesIter] = RailgunLogic.transferTokenIn(_shieldRequests[notesIter].preimage);

      // Hash note for merkle tree insertion
      insertionLeaves[notesIter] = RailgunLogic.hashCommitment(commitments[notesIter]);

      // Push shield ciphertext
      shieldCiphertext[notesIter] = _shieldRequests[notesIter].ciphertext;
    }

    // Emit Shield events (for wallets) for the commitments
    emit Shield(Commitments.treeNumber, Commitments.nextLeafIndex, commitments, shieldCiphertext);

    // Push new commitments to merkle tree
    Commitments.insertLeaves(insertionLeaves);

    // Store block number of last event for easier sync
    RailgunLogic.lastEventBlock = block.number;
  }

  /**
   * @notice Execute batch of Railgun snark transactions
   * @param _transactions - Transactions to execute
   */
  function transact(Transaction[] calldata _transactions) external payable {
    uint256 commitmentsCount = RailgunLogic.sumCommitments(_transactions);

    // Create accumulators
    bytes32[] memory commitments = new bytes32[](commitmentsCount);
    uint256 commitmentsStartOffset = 0;
    CommitmentCiphertext[] memory ciphertext = new CommitmentCiphertext[](commitmentsCount);

    // Loop through each transaction, validate, and nullify
    for (
      uint256 transactionIter = 0;
      transactionIter < _transactions.length;
      transactionIter += 1
    ) {
      // Validate transaction
      (bool valid, string memory reason) = RailgunLogic.validateTransaction(
        _transactions[transactionIter]
      );
      require(valid, string.concat("RailgunSmartWallet: ", reason));

      // Nullify, accumulate, and update offset
      commitmentsStartOffset = RailgunLogic.accumulateAndNullifyTransaction(
        _transactions[transactionIter],
        commitments,
        commitmentsStartOffset,
        ciphertext
      );
    }

    // Loop through each transaction and process unshields
    for (
      uint256 transactionIter = 0;
      transactionIter < _transactions.length;
      transactionIter += 1
    ) {
      // If unshield is specified, process
      if (_transactions[transactionIter].boundParams.unshield != UnshieldType.NONE) {
        RailgunLogic.transferTokenOut(_transactions[transactionIter].unshieldPreimage);
      }
    }

    // Get insertion parameters
    (
      uint256 insertionTreeNumber,
      uint256 insertionStartIndex
    ) = getInsertionTreeNumberAndStartingIndex(commitments.length);

    // Emit commitment state update
    emit Transact(insertionTreeNumber, insertionStartIndex, commitments, ciphertext);

    // Push commitments to tree after events due to insertLeaves causing side effects
    Commitments.insertLeaves(commitments);

    // Store block number of last event for easier sync
    RailgunLogic.lastEventBlock = block.number;
  }
}