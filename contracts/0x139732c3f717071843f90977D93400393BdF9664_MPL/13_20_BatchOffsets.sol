//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


/// @title Batch Offsets
/// @author Adam Fuller (@azf20)
/// Randomly shuffles IDs in batches, given an overall token limit
/// Requirements: batchSize() divides perfectly into limit(), tokenIds start at 0
contract BatchOffsets {

  error BatchNotRevealed();
  event BatchRevealed(uint256 batch, uint256 batchSize, uint256 within, uint256 overall);

  // counter of revealed batches
  uint256 public revealedBatches;

  // tracking the number of tokens in a batch
  uint256 internal _batchSize;

  function batchSize() public view virtual returns (uint256) {
    return _batchSize;
  }

  // limit function, to be overriden by the importing contract
  function limit() public view virtual returns (uint256) {
    return 0;
  }

  // structure for an individual batch offset
  struct BatchOffset {
    uint256 seed; // the random number used to generate the offsets
    uint256 within; // the offset of tokens within the batch
    uint256 overall; // the offset of the batch overall, relative to other batches
  }

  // batches start at 1
  mapping(uint256 => BatchOffset) public offsets;
  mapping(uint256 => bool) private takenOffsets;


  // Storing the offsets which are taken in a packed array of booleans
  mapping(uint256 => uint256) public takenBitMap;

  /// @notice Internal function to set an index as taken
  /// @param index the index
  function _setTaken(uint256 index) private {
      uint256 takenWordIndex = index / 256;
      uint256 takenBitIndex = index % 256;
      takenBitMap[takenWordIndex] = takenBitMap[takenWordIndex] | (1 << takenBitIndex);
  }

  // set the batch offset for a batch, given a random number
  function _setBatchOffset(uint256 _batch, uint256 random) internal {

    // get an offset for within this batch
    BatchOffset memory newBatchOffset;
    newBatchOffset.seed = random;
    newBatchOffset.within = random % batchSize();

    // get an initial overall offset, out of the remaining slots
    uint256 range = ((limit() / batchSize()) - revealedBatches);
    random >>= 16;
    uint256 overall = random % range;

    // create an array to populate with the remaining available offsets
    uint256[] memory offsetOptions = new uint256[](range);
    uint256 counter;
    uint256 word;

    // fetch the first word from the packed booleans (makes it closer to O(1))
    uint256 takenWord = takenBitMap[word];

    // check which offsets are already taken from the full range
    for(uint256 j=0; j<(limit() / batchSize()); j++) {
      // if the offset is beyond the range of the current word, fetch the next word
      if ((j / 256) > word) {
        takenWord = takenBitMap[j / 256];
      }
      // check if a given offset is taken. If it is not, add it to the array of options
      uint256 takenBitIndex = j % 256;
      uint256 mask = (1 << takenBitIndex);
      if(takenWord & mask != mask) {
        offsetOptions[counter] = j;
        counter += 1;
      }
    }
    // the offset uses the initial offset to pick from the remaining available offsets
    newBatchOffset.overall = offsetOptions[overall];

    // set the selected offset as taken, and save the batch offset and increase the revealedBatches counter
    _setTaken(newBatchOffset.overall);
    offsets[_batch] = newBatchOffset;
    revealedBatches += 1;
    emit BatchRevealed(_batch, batchSize(), newBatchOffset.within, newBatchOffset.overall);
  }

  // helper to work out which batch an ID is from
  function idToBatch(uint256 id) public view returns (uint256) {
    return ((id) / batchSize()) + 1;
  }

  // get the shuffled ID, based on its batch's offsets
  function getShuffledId(uint256 id) public virtual view returns (uint256) {
    uint256 _batch = idToBatch(id);
    if(offsets[_batch].seed == 0) revert BatchNotRevealed();
    BatchOffset memory _offset = offsets[_batch];
    uint256 within = (((id) % batchSize()) + _offset.within) % batchSize();
    return (within * (limit() / batchSize())) + _offset.overall
    ;
  }

}