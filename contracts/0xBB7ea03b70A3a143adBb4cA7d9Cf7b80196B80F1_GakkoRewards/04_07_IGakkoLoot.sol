//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

  struct Token{
    uint16 parentId;
    uint16 level;
    bool isClaimed;
  }

interface IGakkoLoot{
  function handleClaim(address owner, Token calldata claim) external;
}