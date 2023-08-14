/**
 *Submitted for verification at Etherscan.io on 2023-08-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

contract PonzuPresaleContract  {
  address private owner;
  address[] private wallets;
  uint256 private constant DECIMAL = 18;
  uint256 private constant MAX_ETH = 1 * 10**18;
  uint256 private constant MAX_BALANCE = 50 * 10**18;

  constructor(){
    owner = msg.sender;
  }

  function deposit() external payable {
    require(address(this).balance < MAX_BALANCE);
    require(msg.value <= MAX_ETH);

    require(!exists1(msg.sender));

    wallets.push(msg.sender);
  }

  function withdraw(uint _amount) external {
    require(msg.sender == owner);
    payable(owner).transfer(_amount);
  }

  function getBalance() external view returns(uint){
    return address(this).balance;
  }

  function getAddress() external view returns(address){
    return address(this);
  }

  function canDeposit(address from) external view returns(bool){
    return !exists1(from);
  }

  function exists1(address num) public view returns (bool) {
    for (uint i = 0; i < wallets.length; i++) {
        if (wallets[i] == num) {
            return true;
        }
    }

    return false;
  }
}