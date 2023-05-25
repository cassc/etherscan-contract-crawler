pragma solidity >=0.7.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0



import "./IERC721TokenOwner.sol";

interface IUserDefinableAttributes is IERC721TokenOwner {
  
  /**
   * @dev Sets the number of user attributes.
   * 
   * NOTE: Can edit existing attributes (in case of changing maxValue if more traits added)
   * 
   * NOTE: the num attributes is defined as the max attributeId
   * 
   * Should only be called by contract owner.
   * 
   * Requirements:
   *   - AttributeId must be greater than 0
   */
  function setNumAttributes(uint256 numAttributes) external;
  
  // Returns the greatest attributeId
  function getNumAttributes() external view returns (uint256);

  // Gets a single user attribute
  function getUserAttribute(uint256 tokenId, uint256 attributeId) external view returns (uint256);

  // Gets all user attributes
  function getUserAttributes(uint256 tokenId) external view returns (uint256[] memory);

  error InvalidAttribute();

}