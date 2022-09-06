// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;


import "./TokenSwapHEADER.sol";


interface TokenSwap {


  // Passive
  function paws( address owner, uint256 tokenParam, uint256 amount ) payable external  returns (bool);

  // Active
  function swap( address tokenAddress, uint256 tokenParam, uint256 amount ) external;

  function supportsInterface(bytes4 interfaceId) external view returns (bool);


  // Price for fast Selling
  function setSwap(uint256 tokenParam, address currency, uint256 price) external;
  function getSwaps(uint256 tokenParam) external view returns ( swapSet[] memory);
  function delSwap(uint256 tokenParam) external;


}