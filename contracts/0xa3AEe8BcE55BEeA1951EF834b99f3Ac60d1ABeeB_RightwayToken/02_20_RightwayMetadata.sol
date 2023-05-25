// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';

import '../utils/Base64.sol';
import './RightwayDecoder.sol';


library RightwayMetadata {
  /*
   * token state information
   */
  struct TokenRedemption {
    uint64 timestamp;
    string memo;
  }

  struct AdditionalContent {
    string contentLibraryArweaveHash;
    uint16 contentIndex;
    string contentType;
    string slug;
  }

  struct TokenState {
    uint64   soldOn;
    uint256  price;
    address  buyer;

    TokenRedemption[] redemptions;
    AdditionalContent[] additionalContent;
    uint16   attributesStart;
    uint16   attributesLength;
  }

  struct MetadataAttribute {
    bool isArray;
    string key;
    string[] values;
  }

  struct MetadataContent {
    string uri;
    string contentLibraryArweaveHash;
    uint16 contentIndex;
    string contentType;
  }

  struct MetadataAdditionalContent {
    string slug;
    string uri;
    string contentLibraryArweaveHash;
    uint16 contentIndex;
    string contentType;
  }

  struct TokenMetadata {
    string name;
    string description;
    MetadataAttribute[] attributes;
    uint256 editionSize;
    uint256 editionNumber;
    uint256 totalRedemptions;
    uint64 redemptionExpiration;
    MetadataContent[] content;
    TokenRedemption[] redemptions;
    uint64 soldOn;
    address buyer;
    uint256 price;
    bool isMinted;
    MetadataAdditionalContent[] additionalContent;
  }


  function reduceDropAttributes(RightwayDecoder.Drop storage drop, RightwayDecoder.DropAttribute[] memory dropAttribute ) internal view returns ( MetadataAttribute[] memory ) {
    if (dropAttribute.length == 0) {
      return new MetadataAttribute[](0);
    }


    uint resultCount = 0;
    uint16 lastKey = 0xFFFF;
    for (uint16 idx = 0; idx < dropAttribute.length; idx++) {
      if (!dropAttribute[idx].isArray || dropAttribute[idx].key != lastKey) {
        resultCount++;
        lastKey = dropAttribute[idx].key;
      }
    }

    MetadataAttribute[] memory result = new MetadataAttribute[](resultCount);
    resultCount = 0;
    lastKey = dropAttribute[0].key;
    for (uint16 idx = 0; idx < dropAttribute.length; idx++) {
      if (!dropAttribute[idx].isArray || dropAttribute[idx].key != lastKey) {
        result[resultCount].isArray = dropAttribute[idx].isArray;
        result[resultCount].key = RightwayDecoder.decodeDropString(drop, dropAttribute[idx].key);
        result[resultCount].values = new string[](1);
        result[resultCount].values[0] = RightwayDecoder.decodeDropString(drop, dropAttribute[idx].value);
        resultCount++;
        lastKey = dropAttribute[idx].key;
      } else {
        string[] memory oldValues = result[resultCount - 1].values;
        result[resultCount - 1].values = new string[](oldValues.length + 1);
        for( uint vidx = 0; vidx < oldValues.length; vidx++) {
          result[resultCount - 1].values[vidx] = oldValues[vidx];
        }
        result[resultCount - 1].values[oldValues.length] = RightwayDecoder.decodeDropString(drop, dropAttribute[idx].value);
      }
    }

    return result;
  }

  function getAttributes(RightwayDecoder.Drop storage drop, uint16 start, uint16 length) internal view returns ( MetadataAttribute[] memory ) {
    if (length == 0) {
      return new MetadataAttribute[](0);
    }

    RightwayDecoder.DropAttribute[] memory dropAttributes = new RightwayDecoder.DropAttribute[](length);
    for (uint16 idx = 0; idx < length; idx++) {
      dropAttributes[idx] = RightwayDecoder.decodeDropAttribute(drop, idx + start);
    }

    return reduceDropAttributes(drop, dropAttributes);
  }

  function getAttributes(string storage creator, RightwayDecoder.Drop storage drop, TokenState memory state, RightwayDecoder.DropEdition memory edition, RightwayDecoder.DropTemplate memory template) internal view returns ( MetadataAttribute[] memory ) {
    MetadataAttribute[] memory tokenAttributes = getAttributes(drop, state.attributesStart, state.attributesLength);
    MetadataAttribute[] memory editionAttributes = getAttributes(drop, edition.attributesStart, edition.attributesLength);
    MetadataAttribute[] memory templateAttributes = getAttributes(drop, template.attributesStart, template.attributesLength);

    uint totalAttributes = tokenAttributes.length + editionAttributes.length + templateAttributes.length + 1;
    MetadataAttribute[] memory result = new MetadataAttribute[](totalAttributes);

    uint outputIdx = 0;
    for (uint idx = 0; idx < tokenAttributes.length; idx++) {
      result[outputIdx++] = tokenAttributes[idx];
    }

    for (uint idx = 0; idx < editionAttributes.length; idx++) {
      result[outputIdx++] = editionAttributes[idx];
    }

    for (uint idx = 0; idx < templateAttributes.length; idx++) {
      result[outputIdx++] = templateAttributes[idx];
    }

    result[outputIdx].isArray = false;
    result[outputIdx].key = 'creator';
    result[outputIdx].values = new string[](1);
    result[outputIdx].values[0] = creator;

    return result;
  }

  function getContentDetails(RightwayDecoder.Drop storage drop, string storage contentApi, uint16 index) public view returns (
    string memory uri,
    string memory contentLibraryArweaveHash,
    uint16 contentIndex,
    string memory contentType
  ) {
    RightwayDecoder.DropContent memory content = RightwayDecoder.decodeDropContent(drop, index);
    RightwayDecoder.DropContentLibrary storage contentLibrary = RightwayDecoder.getDropContentLibrary(drop, content.contentLibrary);

    contentIndex = content.contentIndex;
    contentLibraryArweaveHash = Base64.encode(contentLibrary.arweaveHash);
    if (content.contentType == 0) {
      contentType = 'png';
    } else if (content.contentType == 1) {
      contentType = 'jpg';
    } else if (content.contentType == 2) {
      contentType = 'svg';
    } else if (content.contentType == 3) {
      contentType = 'mp4';
    }
    uri = string(abi.encodePacked(contentApi, '/', contentLibraryArweaveHash, '/', Strings.toString(contentIndex), '.', contentType ));
  }

  function getContent(RightwayDecoder.Drop storage drop, string storage contentApi, uint16 start, uint16 length) internal view returns(MetadataContent[] memory) {
    MetadataContent[] memory result = new MetadataContent[](length);

    for(uint16 idx = 0; idx < length; idx++) {
      (result[idx].uri, result[idx].contentLibraryArweaveHash, result[idx].contentIndex, result[idx].contentType) = getContentDetails(drop, contentApi, start+idx);
    }

    return result;
  }

  function getContents(RightwayDecoder.Drop storage drop, string storage contentApi, RightwayDecoder.DropEdition memory edition, RightwayDecoder.DropTemplate memory template) internal view returns (MetadataContent[] memory) {
    MetadataContent[] memory editionContent = getContent(drop, contentApi, edition.contentStart, edition.contentLength);
    MetadataContent[] memory templateContent = getContent(drop, contentApi, template.contentStart, template.contentLength);

    uint totalContents = editionContent.length + templateContent.length;
    MetadataContent[] memory result = new MetadataContent[](totalContents);

    uint outputIdx = 0;
    for (uint idx = 0; idx < editionContent.length; idx++) {
      result[outputIdx++] = editionContent[idx];
    }

    for (uint idx = 0; idx < templateContent.length; idx++) {
      result[outputIdx++] = templateContent[idx];
    }

    return result;
  }

  function getAdditionalContent(string storage contentApi, AdditionalContent memory content ) internal pure returns (MetadataAdditionalContent memory) {
    MetadataAdditionalContent memory result;
    result.uri = string(abi.encodePacked(contentApi, '/', content.contentLibraryArweaveHash, '/', Strings.toString(content.contentIndex), '.', content.contentType ));
    result.contentLibraryArweaveHash = content.contentLibraryArweaveHash;
    result.contentIndex = content.contentIndex;
    result.contentType = content.contentType;
    result.slug = content.slug;
    return result;
  }

  function getAdditionalContents(string storage contentApi, TokenState memory state) internal pure returns (MetadataAdditionalContent[] memory) {
    MetadataAdditionalContent[] memory result = new MetadataAdditionalContent[](state.additionalContent.length);
    uint outputIdx = 0;
    for (uint idx = 0; idx < state.additionalContent.length; idx++) {
      result[outputIdx++] = getAdditionalContent(contentApi, state.additionalContent[idx]);
    }

    return result;
  }

  function getTemplateMetadata(RightwayDecoder.Drop storage drop, TokenMetadata memory result, RightwayDecoder.DropTemplate memory template) public view {
    result.name = RightwayDecoder.decodeDropSentence(drop, template.name);
    result.description = RightwayDecoder.decodeDropSentence(drop, template.description);
    result.totalRedemptions = template.redemptions;
    result.redemptionExpiration = template.redemptionExpiration;
  }

  function getEditionMetadata(TokenMetadata memory result, RightwayDecoder.DropEdition memory edition ) public pure {
    result.editionSize = edition.size;
  }

  function getTokenMetadata(TokenMetadata memory result, string storage creator, RightwayDecoder.Drop storage drop, string storage contentApi, uint256 tokenId, TokenState memory state) public view {
    require(tokenId < drop.numTokens, 'No such token');
    RightwayDecoder.DropToken memory token = RightwayDecoder.decodeDropToken(drop, uint16(tokenId));
    RightwayDecoder.DropEdition memory edition = RightwayDecoder.decodeDropEdition(drop, token.edition);
    RightwayDecoder.DropTemplate memory template = RightwayDecoder.decodeDropTemplate(drop, edition.template);

    getTemplateMetadata(drop, result, template);
    getEditionMetadata(result, edition);
    result.editionNumber = token.serial;
    result.attributes = getAttributes(creator, drop, state, edition, template);
    result.content = getContents(drop, contentApi, edition, template);
    result.additionalContent = getAdditionalContents(contentApi, state);
  }

  function getStateMetadata(TokenMetadata memory result, TokenState memory state, bool isMinted) public pure {
    result.soldOn = state.soldOn;
    result.buyer = state.buyer;
    result.price = state.price;
    result.isMinted = isMinted;

    uint numRedemptions = state.redemptions.length;
    result.redemptions = new TokenRedemption[](numRedemptions);
    for (uint idx = 0; idx < numRedemptions; idx++) {
      result.redemptions[idx] = state.redemptions[idx];
    }
  }

  function getMetadata(string storage creator, RightwayDecoder.Drop storage drop, string storage contentApi, uint256 tokenId, TokenState memory state, bool isMinted) public view returns (TokenMetadata memory){
    TokenMetadata memory result;
    getTokenMetadata(result, creator, drop, contentApi, tokenId, state);
    getStateMetadata(result, state, isMinted);
    return result;
  }


}