// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface INefturiansData {

  event MetadataUpdated(uint256 indexed tokenId, uint256 indexed key, string value);
  event AttributeUpdated(uint256 indexed tokenId, uint256 indexed key, uint256 value);

  function getMetadata(uint256 tokenId) external view returns (string memory);

  function addKey(string calldata key) external;

  function setMetadata(uint256 tokenId, uint256 key, string calldata value, bytes calldata signature) external;

  function setAttributes(uint256 tokenId, uint256[] calldata keys, uint256[] calldata values, bytes calldata signature) external;
}