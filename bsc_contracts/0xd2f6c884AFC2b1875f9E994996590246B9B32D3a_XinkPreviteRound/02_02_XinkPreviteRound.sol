pragma solidity ^0.8.7;

import './Interfaces.sol';

contract XinkPreviteRound {
  address payable owner;
  address xink;

  uint minimumEntry = 667e15; // above 0.6667 bnb
  uint amountPerBnb = 108000; // 108000 XINK

  constructor(address _xink) {
    xink = _xink;
    owner = payable(msg.sender);
  }

  receive() payable external {
    require(msg.sender == owner || msg.value >= minimumEntry, "MIN");
    owner.transfer(msg.value);
    uint tokenAmount = msg.value * amountPerBnb;
    IERC20(xink).transfer(msg.sender, tokenAmount);
  }

  function removeToken(address tokenAddress, uint tokenAmount) external {
    require(msg.sender == owner, 'NOT_ALLOWED');
    IERC20(tokenAddress).transfer(owner, tokenAmount);
  }
}