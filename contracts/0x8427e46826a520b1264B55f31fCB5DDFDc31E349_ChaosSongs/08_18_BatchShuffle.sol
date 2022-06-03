// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @title BatchShuffle
/// @notice Assign random offsets based on seed input. Remove selected offset from set so it cannot be used multiple times
abstract contract BatchShuffle {
    uint256 internal immutable _batchSize; /*Number of consecutive tokens using the same offset*/
    uint256 internal immutable _startShuffledId; /*Offset to add to all token IDs*/

    mapping(uint256 => uint16) public availableIds; /*Mapping to use to track used offsets*/
    uint16 public availableCount; /*Track the available count to know the id of the current max offset*/
    mapping(uint256 => uint256) public offsets; /*Store offsets once found*/

    /// @notice Constructor sets the shuffle parameters
    /// @param _availableCount Max number of offsets
    /// @param batchSize_ Number of consecutive tokens using the same offset
    /// @param startShuffledId_ Offset to add to all token IDs
    constructor(
        uint16 _availableCount,
        uint256 batchSize_,
        uint256 startShuffledId_
    ) {
        availableCount = _availableCount; /*Set max offsets*/
        _batchSize = batchSize_; /*Set consecutive tokens using same offset*/
        _startShuffledId = startShuffledId_; /*Set offset for all token IDs*/
    }

    /// @notice Set offset at index using seed
    /// @param _index Offset to set
    /// @param _seed Number fr RNG
    function _setNextOffset(uint256 _index, uint256 _seed) internal {
        require(availableCount > 0, "Sold out"); /*Revert once we use up all indices*/
        // Get index of ID to mint from available ids
        uint256 swapIndex = _seed % availableCount;
        // Load in new id
        uint256 newId = availableIds[swapIndex];
        // If unset, assume equals index
        if (newId == 0) {
            newId = swapIndex;
        }
        uint16 lastIndex = availableCount - 1;
        uint16 lastId = availableIds[lastIndex];
        if (lastId == 0) {
            lastId = lastIndex;
        }
        // Set last value as swapped index
        availableIds[swapIndex] = lastId;

        availableCount--;

        offsets[_index] = newId;
    }

    /// @dev Get the token ID to use for URI of a token ID
    /// @param _tokenId Token to check
    function getShuffledTokenId(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        uint256 _batchIndex = _tokenId % _batchSize; /*Get the offset within the batch*/
        uint256 _batchStart = _tokenId - _batchIndex; /*Offsets are stored for batches of 4 consecutive songs*/
        uint256 _offset = offsets[_batchStart];
        uint256 _shuffledTokenId = (_offset * _batchSize) +
            _startShuffledId +
            _batchIndex; /*Add to token ID to get shuffled ID*/

        return _shuffledTokenId;
    }
}