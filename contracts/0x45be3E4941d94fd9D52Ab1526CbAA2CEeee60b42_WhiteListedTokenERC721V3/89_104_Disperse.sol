// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import './tge/interfaces/IBEP20.sol';

contract Disperse {
  function disperseBNB(
    address payable[] calldata recipients,
    uint256[] calldata values
  ) external payable {
    for (uint256 i = 0; i < recipients.length; i++)
      recipients[i].transfer(values[i]);
    uint256 balance = address(this).balance;
    address payable change = payable(msg.sender);
    if (balance > 0) change.transfer(balance);
  }

  function disperseToken(
    IBEP20 token,
    address[] calldata recipients,
    uint256[] calldata values
  ) external {
    uint256 total = 0;
    for (uint256 i = 0; i < recipients.length; i++) total += values[i];
    require(token.transferFrom(msg.sender, address(this), total));
    for (uint256 i = 0; i < recipients.length; i++)
      require(token.transfer(recipients[i], values[i]));
  }

  function disperseTokenSimple(
    IBEP20 token,
    address[] calldata recipients,
    uint256[] calldata values
  ) external {
    for (uint256 i = 0; i < recipients.length; i++)
      require(token.transferFrom(msg.sender, recipients[i], values[i]));
  }
}