// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import {AggregatorV2V3Interface} from '../dependencies/chainlink/AggregatorV2V3Interface.sol';

interface IHopeAggregator is AggregatorV2V3Interface {
  function transmit(uint256 _answer) external;
}