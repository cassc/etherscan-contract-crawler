// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../dependencies/IAccessControlChecker.sol";

interface IWataridoriAccessControlChecker {
  function registerDocumentId(bytes32 documentId, address contractAddress) external;
  function registerToken(bytes32 _documentId, address _contractAddress, uint256 _tokenId) external;
}