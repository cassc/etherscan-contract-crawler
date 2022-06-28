// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../library/Token.sol";

interface MappedTokenConsumer {
  struct MappedToken {
    Token.Standard erc;
    address tokenAddr;
  }
}