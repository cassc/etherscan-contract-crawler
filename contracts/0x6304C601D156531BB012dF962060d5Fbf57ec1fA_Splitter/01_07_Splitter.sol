// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

// @author rollauver.eth

contract Splitter is Ownable, PaymentSplitter {
  constructor(
    address[] memory payees,
    uint256[] memory shares
  ) PaymentSplitter(payees, shares) {}
}