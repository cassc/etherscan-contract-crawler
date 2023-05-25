// SPDX-License-Identifier: MIT
pragma solidity >=0.5.2;

interface IWhitelist {
  // Views
  function root() external view returns (bytes32);
  function uri() external view returns (string memory);
  function whitelisted(address account, bytes32[] memory proof) external view returns (bool);

  // Mutative
  function updateWhitelist(bytes32 _root, string memory _uri) external; 
}