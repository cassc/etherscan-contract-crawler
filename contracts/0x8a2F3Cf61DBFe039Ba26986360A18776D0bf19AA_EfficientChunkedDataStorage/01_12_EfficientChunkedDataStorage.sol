// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import './libraries/SSTORE2Map.sol';
import './interfaces/IDataStorage.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

contract EfficientChunkedDataStorage is IDataStorage, Ownable, ERC165 {
  uint256 public constant MAX_UINT_16 = 0xFFFF;

  uint256 public chunkSize;
  uint256 public dataSize;

  uint256 public currentMaxChunksIndex = 0;

  constructor(uint256 _dataSize, uint256 _chunkSize) {
    dataSize = _dataSize;
    chunkSize = _chunkSize;
  }

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
    require(
      data.length <= chunkSize,
      'EfficientChunkedDataStorage: data is not chunkSize in length'
    );

    bytes memory chunkedLayerData = '';

    for (uint256 i = 0; i < data.length; ++i) {
      require(
        data[i].length == dataSize,
        'EfficientChunkedDataStorage: data size mismatch'
      );
      chunkedLayerData = abi.encodePacked(chunkedLayerData, data[i]);
    }
    SSTORE2Map.write(bytes32(currentMaxChunksIndex), chunkedLayerData);
    currentMaxChunksIndex++;
  }

  function indexToData(uint256 index) public view returns (bytes memory) {
    uint256 currentChunkIndex = index / chunkSize;
    uint256 currentIndex = index % chunkSize;
    bytes memory chunkedData = SSTORE2Map.read(bytes32(currentChunkIndex));
    uint256 fromIndex = currentIndex * dataSize;
    if ((fromIndex + dataSize) <= chunkedData.length && fromIndex < chunkedData.length) {
      return BytesUtils.slice(chunkedData, fromIndex, dataSize);
    }
    return '';
  }
}