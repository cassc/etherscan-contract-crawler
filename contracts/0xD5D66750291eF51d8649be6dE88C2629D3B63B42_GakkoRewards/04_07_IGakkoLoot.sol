//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct Token{
  address owner;
  uint16 parentId;
  uint16 level;
  bool isClaimed;
}

struct TokenList{
  uint16 length;
  Token[] tokens;
}

interface IGakkoLoot{
  function handleClaims(address owner, TokenList calldata list) external;
}