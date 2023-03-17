// SPDX-License-Identifier: UNLICENSED
// AINFT Contracts v1.0.0
pragma solidity ^0.8.9;

interface IAINFTBaseV1 {
  event Mint(
    address indexed to,
    uint256 indexed startTokenId,
    uint256 quantity
  );

  function supportsInterface(bytes4 interfaceId_) external view returns (bool);

  function tokenURI(uint256 tokenId_) external view returns (string memory);

  function tokensOf(
    address owner_,
    uint256 offset_,
    uint256 limit_
  ) external view returns (uint256[] memory);

  function setBaseURI(string calldata baseURI_) external;

  function setMaxTokenId(uint256 maxTokenId_) external;

  function mint(address to_, uint256 quantity_) external returns (uint256);

  function burn(uint256 tokenId_) external;

  function destroy(address payable to_) external;
}