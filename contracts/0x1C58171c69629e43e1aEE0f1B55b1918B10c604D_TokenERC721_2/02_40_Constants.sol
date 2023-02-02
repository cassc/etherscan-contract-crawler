// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @dev Max bps
uint256 constant MAX_BPS = 100_00;
/// @dev Winning bid minimum theshold percentage i.e. 5_00 = 5%
uint256 constant WINNING_BID_THRESHOLD_PERC = 5_00;
/// @dev The address interpreted as native token of the chain.
address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;