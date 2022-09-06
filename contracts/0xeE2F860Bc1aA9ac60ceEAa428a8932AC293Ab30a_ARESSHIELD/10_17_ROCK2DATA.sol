// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

import "./ROCK2HEADER.sol";




abstract contract ROCK2DATA is Context {

  // Events
  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);

  event Rocked(bytes32 id);


  // IDs
  bytes4 constant _INTERFACE_ID_SWAP = 0x83838383;

  bytes4 constant _INTERFACE_ID_PAWS = 0x38383838;



  // RockManagement

  mapping(address => RockEntry) r;

  mapping(uint256 => uint256) _deadBox;

  mapping(uint => mapping(uint => Rocking)) s;
  mapping(uint => uint) sCount;
  uint sIndex = 0;

  uint256 _maxAllowanceTime = 15*60; // 15 min


  // dig params

  uint256 digQualChildCountMin = 5;
  uint256 digSumChildMin = 10 * 10 * 10**_decimals;
  uint256 digSumNorm     =       5 * 10**_decimals;
  uint256 digSumMin      =       1 * 10**_decimals;

  uint256 _digPrice = 0.001 * ( 10**18);
  address _digCurrency = address(0);
  uint256 _digForSale = 1;
  uint8   _digDecimals = 18;


  // rt prov params

  uint256 _rate = 100;
  uint256 _keep = 85 + 45;


  // rock params

  uint256 _rockPrice = 0.001 * ( 10**18);
  address _rockCurrency = address(0);
  uint256 _rockToPayout = 0;
  uint8   _rockDecimals = 18;

  uint256 _rockFee = 0.001 *  10**18;
  uint96  _rockFeeUnit = 1000;

  uint256 _apy = 85;
  uint256 _apySetDate;
  uint256 _apyValid;


  uint256 public y2s = 365 * 24 * 60 * 60;


  // stats

  address[] balancedAddress;


  // totals

  uint256 _totalSupplyERC20 = 0;
  uint256 _totalSupplyBlocked = 0;
  uint256 _totalSummarized = 0;
  uint256 _totalSummarizedAPY = 0;
  uint256 _totalDigged = 0;
  uint256 _totalSale = 0;

  // money on the contract
  mapping( address => uint ) _totalFlow;


  // misc
  address[10] chargeAddresses;

  bool chainPayEnabled = true;

  uint256 controlSeed = 0;

  uint256 lastrn = 1;



  // ts param

  bool _swapAllowed = false;


  // basics

  string public _name;
  string public _symbol;

  uint8 _decimals = 10;

  uint8 dummy = 0;



  constructor(string memory name_, string memory symbol_) payable {

      _name = name_;
      _symbol = symbol_;

      _apySetDate = block.timestamp;
      _apyValid   = y2s;

      _totalFlow[address(0)] += msg.value;

  }

}