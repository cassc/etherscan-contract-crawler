// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface INuclearNerds {
  function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool);
  function ownerOf(uint256 tokenid) external view returns (address);
}