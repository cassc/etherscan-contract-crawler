// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ISellableNFT is IERC721 {
  function MAX_SUPPLY() external view returns(uint256);
  function totalSupply() external view returns(uint256);
  function safeMint(
    address to
  )
  external
  returns(uint256 mintedTokenId);
}