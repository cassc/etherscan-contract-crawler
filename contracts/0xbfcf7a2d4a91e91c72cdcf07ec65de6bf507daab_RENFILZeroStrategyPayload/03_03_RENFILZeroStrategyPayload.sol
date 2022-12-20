// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV2Ethereum} from 'aave-address-book/AaveV2Ethereum.sol';

/**
 * @title RENFILZeroStrategyPayload
 * @notice Proposal payload to set the interest rate strategy of renFIL on Aave V2 Ethereum
 * to one with all the values zeroed
 * @author BGD Labs
 */
contract RENFILZeroStrategyPayload {
  address public constant RENFIL = 0xD5147bc8e386d91Cc5DBE72099DAC6C9b99276F5;
  address public immutable RATE_STRATEGY;

  constructor(address strategy) {
    RATE_STRATEGY = strategy;
  }

  function execute() external {
    AaveV2Ethereum.POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(RENFIL, RATE_STRATEGY);
  }
}