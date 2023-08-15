// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Batched release extension
 * @notice Allows tokens to be released in equal sized batches
 */
abstract contract BatchedReleaseExtension {
    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    uint256 internal _totalTokens;
    uint256 internal _batchSize;

    /// @dev Tracker for the collected amount count. Init to 1 to save gas on updating
    uint256 internal _collectedCount = 1;

    /// @dev Tracker for collected token ids to prevent collecting the same token more than once
    mapping(uint256 => bool) internal _collectedTokenIds;

    /**
     * @notice The current active batch number
     * @dev Batch numbers are 0-`_batchSize` where 0 is "off"
     */
    uint256 internal _activeBatch;

    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    error InvalidBatch();
    error NotActiveBatch();
    error TokenNotInBatch();
    error TokenNotInActiveBatch();
    error CannotGoToNextBatch();

    /* ------------------------------------------------------------------------
                                    E V E N T S
    ------------------------------------------------------------------------ */

    /**
     * @dev When the current active batch is updated
     * @param batch The batch number that is now active
     * @param forced If the batch was forcefully set by an admin
     */
    event ActiveBatchSet(uint256 indexed batch, bool forced);

    /* ------------------------------------------------------------------------
                                 M O D I F I E R S
    ------------------------------------------------------------------------ */

    /**
     * @dev Modifier that reverts if the batch specified is not active
     */
    modifier onlyWhenActiveBatchIs(uint256 batch) {
        if (_activeBatch != batch) revert NotActiveBatch();
        _;
    }

    /**
     * @dev Modifier that reverts if the token is not in the specified batch
     */
    modifier onlyWhenTokenIsInBatch(uint256 id, uint256 batch) {
        if (_getBatchFromId(id) != batch) revert TokenNotInBatch();
        _;
    }

    /**
     * @dev Modifier that reverts if the token is not in the active batch
     */
    modifier onlyWhenTokenIsInActiveBatch(uint256 id) {
        if (_getBatchFromId(id) != _activeBatch) revert TokenNotInActiveBatch();
        _;
    }

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /**
     * @dev Requires `totalTokens` to be divisible by `batchSize` othewise you will
     * not be able to move to the final batch, for example:
     * If `totalTokens` = 12 and `batchSize` = 5 then tokens 11 and 12 will never be reachable.
     * This is because the function to move to the next batch calculates the total number of
     * batches, in this case there would be 2 batches. 12/5 = 2.4 which gets rounded down to 2.
     * You will not be able to move to batch 3 to collect tokens 11 and 12.
     *
     * @param totalTokens The total number of tokens to be released
     * @param batchSize The size of an individual batch
     */
    constructor(uint256 totalTokens, uint256 batchSize) {
        _totalTokens = totalTokens;
        _batchSize = batchSize;
    }

    /* ------------------------------------------------------------------------
                            C O L L E C T   T O K E N S
    ------------------------------------------------------------------------ */

    /**
     * @notice Mark a specific token as collected and increment the count of tokens collected
     * @dev This enables moving to the next batch once the threshold has been hit. To prevent
     * ids being collected more than once, you'll have to add your own checks when collecting.
     * @param id The token id that was collected
     */
    function _collectToken(uint256 id) internal {
        _collectedTokenIds[id] = true;

        unchecked {
            _collectedCount++;
        }
    }

    /**
     * @notice Mark specific tokens as collected and increment the count of tokens collected
     * @dev This enables moving to the next batch once the threshold has been hit. To prevent
     * ids being collected more than once, you'll have to add your own checks when collecting.
     * @param ids The token ids that were collected
     */
    function _collectTokens(uint256[] calldata ids) internal {
        for (uint256 i = 0; i < ids.length; i++) {
            _collectedTokenIds[ids[i]] = true;
        }

        unchecked {
            _collectedCount += ids.length;
        }
    }

    /* ------------------------------------------------------------------------
                                     A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Advances the active batch based on the number of tokens sold in the current batch
     * @dev Reverts if the current batch hasn't sold out yet.
     */
    function _goToNextBatch() internal {
        uint256 nextBatch = (totalCollected() / _batchSize) + 1;

        // Check if the batch can be advanced
        if (_activeBatch >= nextBatch || nextBatch > (_totalTokens / _batchSize)) {
            revert CannotGoToNextBatch();
        }

        // Increment to go to the next batch
        unchecked {
            ++_activeBatch;
        }

        // Emit a batch updated event
        emit ActiveBatchSet(_activeBatch, false);
    }

    /// @dev Force implementation of `goToNextBatch`
    function goToNextBatch() public virtual;

    /**
     * @notice Admin function to force the active batch
     * @dev Bypasses checking if an entire batch is sold out. To be used in situations
     * where the state needs to be fixed for whatever reason. Can be set to zero to
     * effectively pause any sales relying on the current batch being set.
     * @param batch The batch number to activate
     */
    function _forcefullySetBatch(uint256 batch) internal {
        // Limit the batch number to only be in the valid range.
        // 0 is valid which would effectively pause any sales.
        if (batch > (_totalTokens / _batchSize)) revert InvalidBatch();

        // Set the active branch to the one specified
        _activeBatch = batch;

        // Emit a batch updated event
        emit ActiveBatchSet(_activeBatch, true);
    }

    /* ------------------------------------------------------------------------
                                   G E T T E R S
    ------------------------------------------------------------------------ */

    /**
     * @notice Returns the total number of tokens collected
     * @return count The number of tokens collected
     */
    function totalCollected() public view virtual returns (uint256) {
        // Subtract the 1 that `_collectedCount` was initialised with
        return _collectedCount - 1;
    }

    // Get the batch from the non-zero-indexed token id
    function _getBatchFromId(uint256 id) internal view returns (uint256) {
        if (id == 0 || id > _totalTokens) return 0;
        return ((id - 1) / _batchSize) + 1;
    }
}