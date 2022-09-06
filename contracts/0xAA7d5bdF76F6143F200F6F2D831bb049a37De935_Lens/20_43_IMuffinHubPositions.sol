// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../IMuffinHubBase.sol";
import "../IMuffinHubEvents.sol";
import "./IMuffinHubPositionsActions.sol";
import "./IMuffinHubPositionsView.sol";

interface IMuffinHubPositions is
    IMuffinHubBase,
    IMuffinHubEvents,
    IMuffinHubPositionsActions,
    IMuffinHubPositionsView
{}