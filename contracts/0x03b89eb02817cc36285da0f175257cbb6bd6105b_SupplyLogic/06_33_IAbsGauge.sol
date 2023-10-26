// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import {ILendingGauge} from './ILendingGauge.sol';

/**
 * @title IAbsGauge
 * @author HopeLend
 * @notice Defines the basic interface for AbsGauge.
 */
interface IAbsGauge {
  function lendingGauge() external view returns (ILendingGauge);
}