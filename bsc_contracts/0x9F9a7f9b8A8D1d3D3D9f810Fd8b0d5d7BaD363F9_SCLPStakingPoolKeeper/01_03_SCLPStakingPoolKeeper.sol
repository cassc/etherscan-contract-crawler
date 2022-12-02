// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { KeeperCompatibleInterface } from "./interfaces/KeeperCompatibleInterface.sol";

import { IEpoch } from "./interfaces/IEpoch.sol";

interface ICollector is IEpoch {
  function step() external;
}

/**
 * The stability pool keeper gives the stability pool a MAHA reward every 30 days.
 */
contract SCLPStakingPoolKeeper is KeeperCompatibleInterface {
  ICollector public collector;

  constructor(ICollector _collector) {
    collector = _collector;
  }

  function checkUpkeep(bytes calldata)
    external
    view
    override
    returns (bool, bytes memory)
  {
    return (collector.callable(), "");
  }

  function performUpkeep(bytes calldata) external override {
    collector.step();
  }
}