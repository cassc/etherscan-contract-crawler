// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.6;

import {IBPool} from "../balancer/IBPool.sol";
import {BPool} from "./BPool.sol";

contract MockBFactory {
  function newBPool() external returns (IBPool) {
    return new BPool(msg.sender);
  }
}