// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./ROCK2INTERFACE.sol";

/* behalf implementation to support all shield added interfaces in ROCK2 too */

abstract contract ROCK2HALF is ROCK2INTERFACE {

  // shielded - never called!
  function name() public virtual view  returns (string memory) {  return "";}
  function symbol() public virtual view  returns (string memory) {  return "";}
  function decimals() public virtual view  returns (uint8) { return 0;}
  function totalSupply() public virtual view returns (uint256) { return 0;}
  function balanceOf(address account) public virtual view returns (uint256) { account = address(0); return 0;}

  function mint(address account, uint256 amount) public virtual {  account = address(0); amount++;}
  function burn(address account, uint256 amount) public virtual  {  account = address(0); amount++;}
  function transfer(address recipient, uint256 amount) public virtual returns (bool) {  recipient = address(0); amount++;return true; }
  function allowance(address owner, address spender) public virtual view returns (uint256) {  owner = address(0);  spender = address(0); return 0;}

// part of TokenSwap
//  function approve(address spender, uint256 amount) public virtual returns (bool) {  spender = address(0); amount++; return true;}
  function transferFrom( address sender, address recipient,       uint256 amount   ) public virtual returns (bool) {  sender = address(0);  recipient = address(0); amount++; return true; }
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {    spender = address(0); addedValue++; return true;   }
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {   spender = address(0); subtractedValue++; return true;  }

  function getRock() public virtual view returns ( uint256 price, address currency, uint8 decimal, uint256 forSale) { return ( uint256(0),address(0),uint8(0),uint256(0) ); }
  function setRock( uint256 price, address currency) public virtual { price = 0; currency = address(0); }

  function setRocking(Rocking[] calldata _s ) virtual public  { require(_s.length > 0); }
  function cntRocking() virtual public view   returns (uint[] memory) { return new uint[](0); }
  function getRocking( uint idx ) virtual public view  returns (Rocking[] memory) { idx=0; return new Rocking[](0); }
  function getDigs(address account) virtual public view  returns (Digs[] memory) { account = address(0); return new Digs[](0); }
  function cntDigs(address account) public virtual view returns (uint256){ account = address(0); return 0;}

  function lastBlockingOf(address account) public virtual view returns (uint256) { account = address(0); return 0; }

  function balancesOf( address account) payable public virtual returns (uint256 [16] memory b) { b[0] = 0; account = address(0); return b;}
  function totals() public virtual view returns (uint256 [5] memory) {    return [ uint256(0), uint256(0), uint256(0), uint256(0), uint256(0) ];}


  function cntCalc(address account) public virtual view returns (uint256){ account = address(0); return 0;}
  function getCalc(address account, uint256 idx) public virtual view returns (Calcs memory){  account = address(0); idx=0;  Calcs memory c; return c;}
  function cntDig(address sender) public virtual view returns (uint256) { sender = address(0); return 0;}
  function hasDig(address sender) public virtual view returns (bool) { sender = address(0); return false; }

  function setProv( uint childcountmin, uint childsummin, uint sumnorm, uint summin) public virtual { childcountmin=0; childsummin=0; sumnorm=0; summin=0; }

  function setFee(uint256 fee, uint96 amount ) virtual public  { fee = 0; amount = 0;}
  function getFee() public virtual view returns (uint256 fee, uint96 unit){return (0,0);}
  function setChargeAddress(address _address, uint idx) virtual public { _address = address(0); idx=0; }
  function setMaxAllowanceTime(uint256 t ) virtual public  { t=0; }
  function getAPY() virtual public view returns (uint256) {return 0;}
  function getAPY( uint256 now_ ) virtual public view returns (uint256 rate, uint256 from, uint256 till, bool valid ) {}
  function getPrice() virtual public view returns ( uint256 price, address currency, uint8 decimal, uint256 forSale) {}
  function setPrice( uint256 price, address currency) virtual public  {price = 0; currency = address(0);}
  function delPrice() virtual public  {}
  function setRate( uint256 rate_) virtual public  { rate_ = 0;}
  function getRate() virtual public view returns (uint256) {return 0;}
  function setKeep( uint256 keep_) virtual public  { keep_ = 0; }
  function getKeep() virtual public view returns (uint256) { return 0;}

  function chainPayMode(bool mode) public virtual { mode = false; }
  function getTimeStamp() public virtual view returns (uint256) { return 0; }
  function totalFlow(address currency) public virtual view returns (uint) { currency = address(0); return 0; }
  function totalBalance() public virtual view returns (uint256) { return 0; }
  function isProtected(address account) public virtual view returns (bool) { account = address(0);  return false; }
  function mikro( uint256 e ) public virtual pure returns (uint256) { return e*1000000; }


}