// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import './libraries/SSTORE2Map.sol';
import './interfaces/IDataStorage.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

contract ChunkedDataStorage is IDataStorage, Ownable, ERC165 {
  uint256 public constant MAX_UINT_16 = 0xFFFF;

  mapping(uint256 => uint256) public numLayerDataInChunk;

  uint256 public currentMaxChunksIndex = 0;

  constructor() {}

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IDataStorage).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function batchAddChunkedData(bytes[] calldata data) public onlyOwner {
    numLayerDataInChunk[currentMaxChunksIndex] = data.length;

    bytes memory chunkedLayerData = '';

    for (uint256 i = 0; i < data.length; ++i) {
      require(
        data[i].length <= MAX_UINT_16,
        'ChunkedDataStorage: data exceeds size of 0xFFFF'
      );
      chunkedLayerData = abi.encodePacked(
        chunkedLayerData,
        uint16(data[i].length),
        data[i]
      );
    }
    SSTORE2Map.write(bytes32(currentMaxChunksIndex), chunkedLayerData);
    currentMaxChunksIndex++;
  }

  function indexToData(uint256 index) public view returns (bytes memory) {
    uint256 currentChunkIndex = 0;
    uint256 currentIndex = 0;
    do {
      currentIndex += numLayerDataInChunk[currentChunkIndex];
      currentChunkIndex++;
      if (numLayerDataInChunk[currentChunkIndex] == 0) {
        break;
      }
    } while (currentIndex <= index);
    currentChunkIndex--;
    currentIndex -= numLayerDataInChunk[currentChunkIndex];
    uint256 localChunkIndex = index - currentIndex;
    bytes memory chunkedData = SSTORE2Map.read(bytes32(currentChunkIndex));
    uint256 localChunkIndexPointer = 0;
    for (uint256 i = 0; i < chunkedData.length; i += 0) {
      if (localChunkIndexPointer == localChunkIndex) {
        return
          BytesUtils.slice(
            chunkedData,
            i + 2,
            BytesUtils.toUint16(chunkedData, i)
          );
      }
      i += BytesUtils.toUint16(chunkedData, i) + 2;
      localChunkIndexPointer++;
    }

    return '';
  }
}