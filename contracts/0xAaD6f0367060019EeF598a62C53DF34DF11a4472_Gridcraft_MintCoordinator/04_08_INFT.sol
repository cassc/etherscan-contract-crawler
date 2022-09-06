//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface INFT {
  function saleMint(address _recepient, uint256 _amount, bool stake) external;
  function transferFrom(address from, address to, uint256 tokenId) external;
  function tokensOfOwner(address owner) external view returns (uint256[] memory);
  function totalSupply() external view returns (uint256);
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function remaining() external view returns (uint256 nftsRemaining);
}