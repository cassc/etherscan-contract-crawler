// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@mikker/contracts/contracts/Splitter.sol";

contract FountCardMintSplitter is Splitter {
  constructor(
    address[] memory payees,
    uint256[] memory shares,
    address weth
  ) Splitter(payees, shares, weth) {}
}