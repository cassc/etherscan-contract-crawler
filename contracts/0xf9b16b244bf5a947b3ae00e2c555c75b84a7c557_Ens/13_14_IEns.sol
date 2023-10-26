// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IEns {
  function ensSetReverseName(address reverseRegistrar, string memory name) external;

  function ensUnwrap(address nameWrapper, bytes32 labelHash) external;

  function ensSetApprovalForAll(address registry, address operator, bool approved) external;
}