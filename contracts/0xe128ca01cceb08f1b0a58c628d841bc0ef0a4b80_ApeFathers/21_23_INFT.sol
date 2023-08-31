// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2023, GSKNNFT Inc
pragma solidity ^0.8.21;

interface INFT {
  // Events
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function burn(uint256 tokenId) external;

  function ownerOf(uint256 tokenId) external view returns (address);

  function walletOfOwner(address owner) external view returns (uint256[] calldata);

  function balanceOf(address owner) external view returns (uint256);

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  function isOwnerOf(address owner, uint256[] calldata tokenId) external view returns (bool);

  function approve(address to, uint256 tokenId) external;

  function getApproved(uint256 tokenId) external view returns (address);

  function setApprovalForAll(address operator, bool approved) external;

  function isApprovedForAll(address owner, address operator) external view returns (bool);

  function isApprovedOrOwner(address caller, address operator) external view returns (bool);

  function transferFrom(address from, address to, uint256 tokenId) external;

  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}