// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "./BatchedReleaseExtension.sol";

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Batched release operator extension
 * @notice Allows tokens to be released in equal sized batches. To be used by contracts that use
 * the operator pattern for collecting tokens e.g. a separate contract handles collecting tokens.
 */
abstract contract BatchedReleaseOperatorExtension is BatchedReleaseExtension {
    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    /**
     * @notice Contracts that have approval to operate for a given batch
     * @dev Batch number => operator contract address
     */
    mapping(uint256 => address) internal _operatorForBatch;

    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    error NotOperatorForBatch();

    /* ------------------------------------------------------------------------
                                    E V E N T S
    ------------------------------------------------------------------------ */

    /**
     * @dev When an operator is set for a batch
     * @param batch The batch number that an operator was set for
     * @param operator The operator address for the batch
     */
    event BatchOperatorSet(uint256 indexed batch, address indexed operator);

    /* ------------------------------------------------------------------------
                                 M O D I F I E R S
    ------------------------------------------------------------------------ */

    /**
     * @dev Modifier that only allows the operator for the currently active batch
     */
    modifier onlyWhenOperatorForActiveBatch() {
        if (_operatorForBatch[_activeBatch] != msg.sender) revert NotOperatorForBatch();
        _;
    }

    /**
     * @dev Modifier that only allows the operator for a specific batch
     */
    modifier onlyWhenOperatorForBatch(uint256 batch) {
        if (_operatorForBatch[batch] != msg.sender) revert NotOperatorForBatch();
        _;
    }

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */
    /**
     * @param totalTokens The total number of tokens to be released
     * @param batchSize The number of equal batches to be released
     */
    constructor(uint256 totalTokens, uint256 batchSize)
        BatchedReleaseExtension(totalTokens, batchSize)
    {}

    /* ------------------------------------------------------------------------
                                     A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Adds an operator for a specific batch
     * @dev Allows the use of the `onlyOperatorForBatch()` modifier.
     * Reverts if the batch isn't between 1-`_numOfBatches`.
     * @param batch The batch to set the operator for
     * @param operator The operator contract that get's approval to all the minters tokens
     */
    function _setBatchOperator(uint256 batch, address operator) internal {
        if (batch > (_totalTokens / _batchSize) || batch < 1) revert InvalidBatch();
        _operatorForBatch[batch] = operator;
        emit BatchOperatorSet(batch, operator);
    }

    /**
     * @dev Force implementation of `setBatchOperator`.
     * Can be overriden to pre-approve token transfers using `isApprovedForAll` for example.
     */
    function setBatchOperator(uint256 batch, address operator) public virtual;
}