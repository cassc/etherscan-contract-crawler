// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IComptroller {
  function enterMarkets(address[] memory cTokens) external returns (uint256[] memory);
}

interface ICEther {
  function borrow(uint256 borrowAmount) external returns (uint256);
}

interface ICERC721 {
  function mints(uint256[] calldata tokenIds) external returns (uint256[] memory);

  function transfer(address dst, uint256 amount) external returns (bool);

  function userTokens(address user, uint256 index) external view returns (uint256);

  function redeems(uint256[] calldata redeemTokenIds) external returns (uint256[] memory);

  function underlying() external view returns(address);
}

interface IUnderlying {
  function transferFrom(address from, address to, uint256 tokenId) external;
}