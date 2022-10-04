// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.8 <0.8.10;

interface IERC721Factory {
  function createERC721(
    string calldata _collectionName,
    string calldata _baseMetadataURI
  ) external returns (address contractAddress);
}