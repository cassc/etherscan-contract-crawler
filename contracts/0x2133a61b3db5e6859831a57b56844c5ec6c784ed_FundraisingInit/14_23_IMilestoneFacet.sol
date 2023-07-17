// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

// Local imports
import { RequestTypes } from "../structs/RequestTypes.sol";

/**************************************

    Milestone facet interface

**************************************/

interface IMilestoneFacet {
    function unlockMilestone(RequestTypes.UnlockMilestoneRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external;

    function claimMilestone(RequestTypes.ClaimMilestoneRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external;
}