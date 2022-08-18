// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IMetaDataOracle {
  function takeRole(address caller) external;

  function requestMetaData(uint tokenId) external returns(uint256);

  function returnMetadata(string memory json, address callerAddress, uint256 id, uint tokenId) external;

  function addProvider(address provider) external;

  function removeProvider(address provider) external;

  function setProvidersThreshold(uint threshold) external;
}