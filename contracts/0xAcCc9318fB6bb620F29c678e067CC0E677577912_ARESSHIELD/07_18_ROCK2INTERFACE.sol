// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./ROCK2HEADER.sol";


interface ROCK2INTERFACE  {


  function name() external view  returns (string memory) ;
  function symbol() external view  returns (string memory) ;
  function decimals() external view  returns (uint8) ;
  function totalSupply() external view returns (uint256) ;
  function balanceOf(address account) external view returns (uint256) ;

/*
  function mint(address account, uint256 amount) external ;
  function burn(address account, uint256 amount) external  ;
  */
  function transfer(address recipient, uint256 amount) external returns (bool) ;
  function allowance(address owner, address spender) external view returns (uint256) ;


// part of TokenSwap
//  function approve(address spender, uint256 amount) external returns (bool) ;
  function transferFrom( address sender, address recipient,       uint256 amount   ) external returns (bool) ;
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool) ;
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) ;


  function getRock() external view returns ( uint256 price, address currency, uint8 decimal, uint256 forSale) ;
  function setRock( uint256 price, address currency) external ;

  function setRocking(Rocking[] calldata _s ) external  ;
  function cntRocking() external view   returns (uint[] memory) ;
  function getRocking( uint idx ) external view  returns (Rocking[] memory) ;
  function getDigs(address account) external view  returns (Digs[] memory) ;
  function cntDigs(address account) external view returns (uint256);

  function lastBlockingOf(address account) external view returns (uint256) ;

  function balancesOf( address account) payable external returns (uint256 [16] memory b) ;
  function totals() external view returns (uint256 [5] memory) ;


  function cntCalc(address account) external view returns (uint256);
  function getCalc(address account, uint256 idx) external view returns (Calcs memory);
  function cntDig(address sender) external view returns (uint256) ;
  function hasDig(address sender) external view returns (bool) ;
  function setProv( uint childcountmin, uint childsummin, uint sumnorm, uint summin) external ;
  function setFee(uint256 fee, uint96 amount ) external  ;
  function getFee() external view returns (uint256 fee, uint96 unit);
  function setChargeAddress(address _address, uint idx) external ;
  function setMaxAllowanceTime(uint256 t ) external  ;
  function getAPY() external view returns (uint256) ;
  function getAPY( uint256 now_ ) external view returns (uint256 rate, uint256 from, uint256 till, bool valid ) ;
  function getPrice() external view returns ( uint256 price, address currency, uint8 decimal, uint256 forSale) ;
  function setPrice( uint256 price, address currency) external  ;
  function delPrice() external  ;
  function setRate( uint256 rate_) external  ;
  function getRate() external view returns (uint256) ;
  function setKeep( uint256 keep_) external  ;
  function getKeep() external view returns (uint256) ;

  function chainPayMode(bool mode) external ;
  function getTimeStamp() external view returns (uint256) ;
  function totalFlow(address currency) external view returns (uint) ;
  function totalBalance() external view returns (uint256) ;
  function isProtected(address account) external view returns (bool) ;

}