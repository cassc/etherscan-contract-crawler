// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import '../contracts/IToken.sol';

contract BridgeBase is Ownable, ReentrancyGuard {
  uint256 public nonce;
  mapping(uint256 => bool) public processedNonces;
  IToken public token;

  enum Step {
    Burn,
    Transfer
  }
  event Transfer(address from, address to, uint amount, uint date, uint nonce, Step indexed step);

  constructor(address _token) {
    token = IToken(_token);
  }

  event Received(address, uint);

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  function setToken(address _tokenAddress) external onlyOwner {
    token = IToken(_tokenAddress);
  }

  function withdrawTruth(address _address, uint256 _amount) external onlyOwner {
    uint256 balance = token.balanceOf(address(this));
    require(balance >= _amount, 'Amount is too high');
    token.transfer(_address, _amount);
  }

  function withdraw(address _address) external payable onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, 'Amount is too high');
    payable(_address).transfer(balance);
  }
}