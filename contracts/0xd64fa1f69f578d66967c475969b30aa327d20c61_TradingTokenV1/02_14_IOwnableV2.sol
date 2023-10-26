// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @title Ownable
 * 
 * parent for ownable contracts
 */
interface IOwnableV2 {
  event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

  function owner() external view returns (address);
  function transferOwnership(address newOwner_) external;
}