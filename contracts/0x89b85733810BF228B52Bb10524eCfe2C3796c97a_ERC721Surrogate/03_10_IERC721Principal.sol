// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IERC721Principal is IERC721, IERC721Metadata {
  function owner() external view returns (address);
  function totalSupply() external view returns(uint256);
}