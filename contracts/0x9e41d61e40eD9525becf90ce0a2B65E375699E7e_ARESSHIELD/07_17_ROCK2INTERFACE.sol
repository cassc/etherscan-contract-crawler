// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./ROCK2HEADER.sol";


interface ROCK2INTERFACE  {


  function name() external view  returns (string memory) ;
  function symbol() external view  returns (string memory) ;
  function decimals() external view  returns (uint8) ;
  function totalSupply() external view returns (uint256) ;
  function balanceOf(address account) external view returns (uint256) ;

  function transfer(address recipient, uint256 amount) external returns (bool) ;
  function allowance(address owner, address spender) external view returns (uint256) ;

// part of TokenSwap Interface
// function approve(address spender, uint256 amount) external returns (bool) ;
  function transferFrom( address sender, address recipient,       uint256 amount   ) external returns (bool) ;
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool) ;
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) ;



  function lastBlockingOf(address account) external view returns (uint256) ;

  function balancesOf( address account) external returns (uint256 [16] memory b) ;
  function totals() external view returns (uint256 [5] memory) ;




  function getTimeStamp() external view returns (uint256) ;
  function totalFlow(address currency) external view returns (uint) ;
  function totalBalance() external view returns (uint256) ;
  function isProtected(address account) external view returns (bool) ;

  function getAPY() external view returns (uint256) ;
  function getAPY( uint256 now_ ) external view returns (uint256 rate, uint256 from, uint256 till, bool valid ) ;
  function getPrice() external view returns ( uint256 price, address currency, uint8 decimal, uint256 forSale) ;
  function getFee() external view returns (uint256 fee, uint96 unit);

  function hasDig(address sender) external view returns (bool) ;


}