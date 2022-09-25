// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Aggregator
 * @author Fibswap <[email protected]>
 * @notice NFT marketplace aggregator
 */
abstract contract Aggregator is Ownable {
  // ============ Properties =============

  address public fibswap;
  address public target;

  // ============ Constructor =============

  constructor(address _fibswap, address _target) {
    fibswap = _fibswap;
    target = _target;
  }

  // ============ Modifiers =============

  /**
   * @notice Errors if the sender is not Fibswap
   */
  modifier onlyFibswap() {
    require(msg.sender == fibswap, "!fibswap");
    _;
  }

  // ============ Public Functions =============

  function setFibswap(address _fibswap) external onlyOwner {
    require(_fibswap != address(0), "zero");

    fibswap = _fibswap;
  }

  function setTarget(address _target) external onlyOwner {
    require(Address.isContract(_target), "!contract");

    target = _target;
  }
}