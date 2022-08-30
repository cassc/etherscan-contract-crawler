// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

import "../../fxPortal/IFxStateSender.sol";

/// @notice Configuration entity for sending events to Governance layer
struct Destinations {
    IFxStateSender fxStateSender;
    address destinationOnL2;
}