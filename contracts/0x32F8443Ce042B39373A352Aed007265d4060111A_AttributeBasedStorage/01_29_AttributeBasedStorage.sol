// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import './libraries/SSTORE2Map.sol';
import './RarityCompositingEngine.sol';
import './Merge.sol';
import './ChunkedDataStorage.sol';
import './interfaces/IDataStorage.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

contract AttributeBasedStorage is IDataStorage, Ownable, ERC165 {
  RarityCompositingEngine rce;
  Merge merge;
  ChunkedDataStorage chunkedDataStorage;

  uint256 attributeLookupIndex;
  uint256 attributeStartIndex;

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

  constructor(
    address _merge,
    address _rce,
    address _chunkedDataStorage,
    uint256 _attributeLookupIndex,
    uint256 _attributeStartIndex
  ) {
    rce = RarityCompositingEngine(_rce);
    merge = Merge(_merge);
    attributeLookupIndex = _attributeLookupIndex;
    chunkedDataStorage = ChunkedDataStorage(_chunkedDataStorage);
    attributeStartIndex = _attributeStartIndex;
  }

  function getDataIndex(uint256 tokenId) public view returns (uint) {
    uint256 rarityScore = merge.getRarityScoreForToken(tokenId);
    bytes memory seed = abi.encodePacked(rarityScore, tokenId);
    (, uint16[] memory attributeIndexes) = rce.getRarity(rarityScore, seed);
    return attributeIndexes[attributeLookupIndex] - attributeStartIndex;
  }

  function indexToData(uint256 tokenId) public view returns (bytes memory) {
    return
      chunkedDataStorage.indexToData(
        getDataIndex(tokenId) 
      );
  }
}