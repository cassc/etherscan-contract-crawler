// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC721A.sol";

interface ITrueDropERC721A is IERC721A {
  function setMintter(address mintter, bytes memory signature) external;

  function contractURI() external view returns (string memory);

  function imageBaseURI() external view returns (string memory);

  function setBaseUri(string memory tokenURI, bytes memory signature) external;

  function mintNFT(address to, uint256 quantity) external;

  function maxSupply() external view returns (uint256);

  event TrueDropCollectionCreated(address contractAddress, address owner, address signer, uint256 fee, string uniqueId);
}