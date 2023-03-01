// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoin {
  function balanceOf(address) external view returns (uint256);

  function transfer(address, uint256) external returns (bool);
}

contract RoyaltySplitter {
  address owner;

  constructor() {
    owner = msg.sender;
  }

  function claim(ICoin[] calldata coins) external returns (uint256 balance, uint256[] memory coinBalances) {
    require(owner == msg.sender);

    balance = address(this).balance;
    payable(owner).transfer(balance);

    uint256 coinCount = coins.length;
    coinBalances = new uint256[](coinCount);

    for (uint256 i = 0; i < coinCount; i++) {
      coinBalances[i] = coins[i].balanceOf(address(this));
      coins[i].transfer(owner, coinBalances[i]);
    }
  }

  fallback() external payable {}

  receive() external payable {}
}