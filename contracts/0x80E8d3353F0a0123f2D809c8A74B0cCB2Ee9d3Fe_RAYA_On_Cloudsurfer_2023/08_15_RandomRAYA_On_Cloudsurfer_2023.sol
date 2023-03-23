pragma solidity ^0.8.8;

// SPDX-License-Identifier: MIT

contract RandomRAYA_On_Cloudsurfer_2023 {
  uint256[177] public indices;
  uint256 public constant MAX_RAYA = 177;

  event GenerateRandom(uint256 index, uint256 tokenId);

  /// Pick a random index
  /// @dev Grabs a random number lower than the total remaining supply and checks the index of indices if a value has been assigned, if so returns assigned value and if not, the index itself
  /// @param totalSupply Remaining supply of the original contract
  function randomIndex(uint256 totalSupply) internal returns (uint256) {
    uint256 totalSize = MAX_RAYA - totalSupply;
    uint256 index = uint256(
      keccak256(
        abi.encodePacked(
          msg.sender,
          block.coinbase,
          block.gaslimit,
          block.difficulty,
          block.timestamp
        )
      )
    ) % totalSize;
    uint256 value = 0;

    if (indices[index] != 0) {
      value = indices[index];
    } else {
      value = index;
    }

    if (indices[totalSize - 1] == 0) {
      indices[index] = totalSize - 1;
    } else {
      indices[index] = indices[totalSize - 1];
    }
    uint256 val = value + 1;
    emit GenerateRandom(index, val);
    return val;
  }
}