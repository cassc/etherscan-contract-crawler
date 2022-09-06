// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./positions/IMuffinHubPositions.sol";
import "./IMuffinHub.sol";

/// @notice Muffin hub interface, combining both primary and secondary contract
interface IMuffinHubCombined is IMuffinHub, IMuffinHubPositions {}