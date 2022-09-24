// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface ITaggrNft {
  function initialize(
    address owner,
    address distributor,
    string memory name,
    string memory symbol,
    string memory baseTokenUri,
    uint256 maxSupply,
    uint96 royaltiesPct
  ) external;

  function distributeToken(address to, uint256 tokenId) external;
  function distributeTokenWithURI(address to, uint256 tokenId, string memory tokenUri) external;
}