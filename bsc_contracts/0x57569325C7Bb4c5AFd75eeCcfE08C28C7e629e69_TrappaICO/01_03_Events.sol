// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Events {
  event BuyTokens (address buyer, uint amount);
  event RevertTokens (address owner, uint amount);
  event ReturnStuckTokens (address owner, address token);
  event TransferBalance (address owner, uint amount);
  event SwitchOnOff (bool online);
}