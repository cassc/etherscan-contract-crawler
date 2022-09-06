// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;

/*
 SAMPLE for ERC20 extension

 vunction swap( address tokenAddress, uint256 tokenParam, uint256 amount ) {

   approve( tokenAddress, amount);

   PEERSALE(token).swap( msg.sender, tokenParam, address(this),  amount );

 }
*/



import "./TokenSwapHEADER.sol";


interface TokenSwap {

/*
  // Passive
  vunction setSwap( uint256 tokenParam, address currencyAddress, uint256 amount) external;

  vunction getSwaps( uint256 tokenParam) external returns ( swapSet[] memory);

  vunction delSwap( uint256 tokenParam) external;
*/
//  function approve(address spender, uint256 amount) external returns (bool);


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