pragma solidity ^0.8.0;

// SPDX-License-Identifier: GPL-3.0



import "./IUserDefinableAttributes.sol";
import '@openzeppelin/contracts/access/Ownable.sol';



abstract contract UserDefinableAttributes is IUserDefinableAttributes, Ownable {

  uint256 _numAttributes;

  // NOTE: could use arrays here, but saves gas by using mappings (so do not have to push to array?)
  mapping(uint256 /* tokenId */ => mapping(uint256 /* attributeId */ => uint256 /* value */)) attributesForTokens;


  // implements createUserAttribute
  function setNumAttributes(uint256 numAttributes) public virtual onlyOwner {
  
    // ensure not setting to less attributes than current
    if(_numAttributes >= numAttributes) revert InvalidAttribute();

    // number of attributes is greater of current attributeId or previous number of attributes
    _numAttributes = numAttributes;

  }

  function getNumAttributes() public view virtual override returns (uint256) {
    return _numAttributes;
  }


  function _setUserAttribute(uint256 tokenId, uint256 attributeId, uint256 attributeValue) internal virtual {
    // ensure token owner
    if(!(this.ownerOf(tokenId) == msg.sender)) revert NotTokenOwner();

    // ensure attributeId is valid
    if(attributeId >= _numAttributes) revert InvalidAttribute();

    // ensure attributeValue is valid
    if(attributeValue == 0) revert InvalidAttribute();

    attributesForTokens[tokenId][attributeId] = attributeValue;
  }

  
  function _setUserAttributes(uint256 tokenId, uint256[] memory attributeIds, uint256[] memory attributeValues) internal virtual {
    // ensure token owner
    if(!(this.ownerOf(tokenId) == msg.sender)) revert NotTokenOwner();

    // ensure attributeIds and attributeValues are same length
    if(attributeIds.length != attributeValues.length) revert InvalidAttribute();

    for(uint256 i = 0; i < attributeIds.length; i++) {
      _setUserAttribute(tokenId, attributeIds[i], attributeValues[i]);
    }
  }

  function getUserAttribute(uint256 tokenId, uint256 attributeId) public view virtual override returns (uint256) {
    return attributesForTokens[tokenId][attributeId];
  }

  function getUserAttributes(uint256 tokenId) public view virtual override returns (uint256[] memory) {
    uint256[] memory attributeValues = new uint256[](_numAttributes);

    // Attributes are 0 indexed
    for(uint256 i = 0; i < _numAttributes; i++) {
      attributeValues[i] = attributesForTokens[tokenId][i];
    }

    return attributeValues;
  }

}