// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;


interface IERC173 {
  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
  function owner() view external returns(address);
  function transferOwnership(address _newOwner) external;	
}