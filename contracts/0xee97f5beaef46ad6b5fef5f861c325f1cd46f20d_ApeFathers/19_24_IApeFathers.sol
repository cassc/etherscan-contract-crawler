// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2023, GSKNNFT Inc
pragma solidity 0.8.20;

interface IApeFathers {
  function getOwner() external view returns (address);

  function exists(uint256 tokenId) external view returns (bool);

  function _totalSupply() external view returns (uint256);

  function mint(address _to, uint256 quantity) external payable;

  function totalMinted() external view returns (uint256);

  function baseURI() external view returns (string memory);

  function numberMinted(address owner) external view returns (uint256);

  function nextTokenId() external view returns (uint256);

  function multicall(bytes[] calldata data, address diamond) external;

  function burnClaim(uint256[] calldata tokenId, uint256 quantity) external;

  event Burned(address indexed burner, uint256 indexed tokenId);
  event ContractUpgraded(address sender, address indexed contractAddress, bool indexed success, string);
  event ContractUpgradeRejected(address sender, address indexed contractAddress, bool indexed success, string);
  event Stage1Initialized(address indexed contractAddress, address indexed contractOwner, bool indexed initialized);
  event DiamondInitialized(address indexed contractAddress, address indexed contractOwner, bool indexed initialized);

}