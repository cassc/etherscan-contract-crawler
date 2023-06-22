// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {PausableImpl} from "splits-utils/PausableImpl.sol";

import {IOracle} from "./interfaces/IOracle.sol";

/// @title Abstract Oracle Implementation
/// @author 0xSplits
/// @notice Abstract oracle clone-implementation
abstract contract OracleImpl is PausableImpl, IOracle {
/// slot 0 - 11 byte free

/// OwnableImpl storage
/// address internal $owner;
/// 20 bytes

/// PausableImpl storage
/// bool internal $paused;
/// 1 byte
}