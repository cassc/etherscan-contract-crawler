// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract IHPEvent {
  function emitMintEvent(
    address to,
    address nft,
    uint256 tokenId,
    string memory trackId
  ) external virtual;

  function emitNftContractInitialized(
    address nft
  ) external virtual;

  function emitTokenTransferred(
    address from,
    address to,
    address nft,
    uint256 tokenId
  ) external virtual;

  function emitSetApprovedForAll(
    address nft,
    address operator,
    bool approved
  ) external virtual;

  function emitApproved(
    address nft,
    address operator,
    uint256 tokenId
  ) external virtual;

  function setAllowedContracts(address _contractAddress) external virtual {}
}