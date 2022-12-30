// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Events {
  event RevertTokens (address owner, uint amount);
  event ClaimTokens (address owner, uint amount);
  event SwitchOnOff (bool online);
}