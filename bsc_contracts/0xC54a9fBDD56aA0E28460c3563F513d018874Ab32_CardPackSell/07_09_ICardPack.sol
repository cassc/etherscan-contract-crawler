// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ICardPack {
  struct Proof {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  function currentTokenId() external view returns (uint256);

  function mint(address to, uint256 category) external;

  function incubate(uint256 tokenId) external;

  function unpack(
    uint256 tokenId,
    uint256 category,
    Proof memory proof
  ) external;
}