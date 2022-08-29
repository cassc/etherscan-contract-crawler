// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {AggregatorV3Interface, FluxAggregator} from "./FluxAggregator.sol";
import {IOracleAdapter} from "./IOracleAdapter.sol";
import {IOverrideOracle} from "./IOverrideOracle.sol";
import {ILockingOracle} from "./ILockingOracle.sol";